// Redent page bridge. Runs in an isolated content world ("redent"), never in
// the page's own world. Detects login forms and one-time-code fields, and
// exposes fill functions callable from native code. Never submits a form or
// clicks a submit button — the user always presses the button themselves.
(function () {
  'use strict';
  try {
    var BRIDGE = 'redentBridge';
    var OTP_PATTERN = /\b(otp|totp|mfa|2fa|two[-_ ]?factor|one[-_ ]?time|auth(entication)?[-_ ]?code|verification[-_ ]?code|security[-_ ]?code|passcode|codice)\b/i;
    var CURRENT_PASSWORD_PATTERN = /\b(current|old|existing|previous|attuale|corrente|vecchia|precedente)\b/i;
    var NEW_PASSWORD_PATTERN = /\b(new|change|confirm|repeat|retype|verify|nuova|conferma|ripeti)\b/i;

    var state = { loginSignaled: false, otpPresent: false };

    function post(type, payload) {
      try {
        var handlers = window.webkit && window.webkit.messageHandlers;
        if (handlers && handlers[BRIDGE]) {
          handlers[BRIDGE].postMessage(Object.assign({ type: type }, payload || {}));
        }
      } catch (e) {}
    }

    function currentOrigin() {
      return window.location.origin;
    }

    function isMainFrame() {
      try { return window.top === window; } catch (e) { return true; }
    }

    // Open shadow roots hide login fields from a plain querySelectorAll, which
    // is how several SSO widgets (and some banks) now render. Closed roots stay
    // unreachable — that is the platform's boundary, not ours.
    function collect(selector, root) {
      var scope = root || document;
      var found = Array.prototype.slice.call(scope.querySelectorAll(selector));
      var all = scope.querySelectorAll('*');
      for (var i = 0; i < all.length; i++) {
        if (all[i].shadowRoot) found = found.concat(collect(selector, all[i].shadowRoot));
      }
      return found;
    }

    function observeShadows(root) {
      var all = (root || document).querySelectorAll('*');
      for (var i = 0; i < all.length; i++) {
        var shadow = all[i].shadowRoot;
        if (shadow && !shadow.__redentObserved) {
          shadow.__redentObserved = true;
          try { observer.observe(shadow, { childList: true, subtree: true }); } catch (e) {}
          observeShadows(shadow);
        }
      }
    }

    // React (and Vue) install their own `value` setter on the input instance and
    // track the last value they wrote. Assigning `el.value` directly is silently
    // reverted on the next render, so the field looks filled and then empties.
    // Writing through the prototype's native setter is what makes the framework
    // observe a genuine user edit.
    function setFieldValue(el, value) {
      try {
        var proto = Object.getPrototypeOf(el) || window.HTMLInputElement.prototype;
        var descriptor = Object.getOwnPropertyDescriptor(proto, 'value')
          || Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value');
        if (descriptor && descriptor.set) {
          descriptor.set.call(el, value);
        } else {
          el.value = value;
        }
      } catch (e) {
        el.value = value;
      }
      fireInputEvents(el);
    }

    function fireInputEvents(el) {
      el.dispatchEvent(new Event('input', { bubbles: true }));
      el.dispatchEvent(new Event('change', { bubbles: true }));
    }

    function isUsernameField(el) {
      if (!el || el.tagName !== 'INPUT') return false;
      var type = (el.type || '').toLowerCase();
      var autocomplete = (el.getAttribute('autocomplete') || '').toLowerCase();
      if (autocomplete === 'username' || autocomplete === 'email') return true;
      return type === 'text' || type === 'email';
    }

    function nearestUsernameField(passwordField) {
      var scope = passwordField.form || document;
      var candidates = collect('input', scope);
      var passIndex = candidates.indexOf(passwordField);
      for (var i = passIndex - 1; i >= 0; i--) {
        if (isUsernameField(candidates[i])) return candidates[i];
      }
      return null;
    }

    function findPasswordFields() {
      return collect('input[type="password"]');
    }

    // Two-step sign-in (username, then password on the next screen) is now the
    // norm for SSO. A page with only a username field is still a login page,
    // and refusing to recognise it means the vault stays silent on exactly the
    // screen where it is needed.
    function currentUsername() {
      var standalone = findStandaloneUsernameField();
      if (standalone && standalone.value) return String(standalone.value).trim();
      var pass = findPasswordFields()[0];
      var near = pass ? nearestUsernameField(pass) : null;
      if (near && near.value) return String(near.value).trim();
      return '';
    }

    function attachIdentityListener(el) {
      if (!el || el.__redentIdentityBound) return;
      el.__redentIdentityBound = true;
      var report = function () {
        var value = String(el.value || '').trim();
        if (value) post('identityCaptured', { username: value });
      };
      el.addEventListener('blur', report);
      el.addEventListener('change', report);
    }

    function findStandaloneUsernameField() {
      var inputs = collect('input');
      for (var i = 0; i < inputs.length; i++) {
        var el = inputs[i];
        var type = (el.type || '').toLowerCase();
        if (type !== 'text' && type !== 'email') continue;
        var autocomplete = (el.getAttribute('autocomplete') || '').toLowerCase();
        if (autocomplete === 'username' || autocomplete === 'email') return el;
        var haystack = [el.getAttribute('name'), el.id, el.getAttribute('placeholder'),
                        el.getAttribute('aria-label')].filter(Boolean).join(' ');
        if (/\b(user(name)?|email|e-mail|login|userid|utente|accedi)\b/i.test(haystack)) return el;
      }
      return null;
    }

    function fieldHaystack(el) {
      return [el.getAttribute('name'), el.id, el.getAttribute('placeholder'),
              el.getAttribute('aria-label'), labelText(el)].filter(Boolean).join(' ');
    }

    function isCurrentPasswordField(el) {
      var autocomplete = (el.getAttribute('autocomplete') || '').toLowerCase();
      if (autocomplete === 'current-password') return true;
      if (autocomplete === 'new-password') return false;
      return CURRENT_PASSWORD_PATTERN.test(fieldHaystack(el));
    }

    function isNewPasswordField(el) {
      var autocomplete = (el.getAttribute('autocomplete') || '').toLowerCase();
      if (autocomplete === 'new-password') return true;
      if (autocomplete === 'current-password') return false;
      return NEW_PASSWORD_PATTERN.test(fieldHaystack(el));
    }

    function changesPassword(fields) {
      return fields.length > 1 || (fields.length === 1 && isNewPasswordField(fields[0]));
    }

    // A change-password form carries the password being replaced alongside its
    // replacement. Reporting the first field would report the dead one, the
    // vault would recognise it as what it already holds, and the user would
    // never be asked to update anything.
    function submittedPasswordField(fields) {
      if (fields.length === 0) return null;
      if (fields.length === 1) return fields[0];
      for (var i = 0; i < fields.length; i++) {
        if (isNewPasswordField(fields[i])) return fields[i];
      }
      var notCurrent = fields.filter(function (el) { return !isCurrentPasswordField(el); });
      if (notCurrent.length > 0 && notCurrent.length < fields.length) return notCurrent[0];
      // Unlabelled multi-field form: the second box holds the new password in
      // both the (current, new) and the (new, confirm) layout.
      return fields[1];
    }

    // On a change-password screen the surrounding text fields belong to the
    // rest of the settings page — a display name is not a login. Only a field
    // the page explicitly marks as the username may be trusted there.
    function submittedUsername(scope, passwordField, changing) {
      if (changing) {
        var explicit = collect('input[autocomplete="username"], input[autocomplete="email"]', scope)[0];
        return explicit ? String(explicit.value || '').trim() : '';
      }
      var userField = nearestUsernameField(passwordField);
      return userField ? String(userField.value || '').trim() : '';
    }

    // Hidden password inputs are a common anti-bot decoy; counting them would
    // read an ordinary login form as a password change.
    function submittablePasswordFields(scope) {
      var fields = collect('input[type="password"]', scope);
      var shown = fields.filter(isVisibleField);
      return shown.length > 0 ? shown : fields;
    }

    function reportCredential(scope) {
      var fields = submittablePasswordFields(scope);
      var changing = changesPassword(fields);
      var field = submittedPasswordField(fields);
      if (!field || !field.value) return;
      post('credentialSubmitted', {
        origin: currentOrigin(),
        username: submittedUsername(scope, field, changing),
        password: field.value,
        passwordChange: changing
      });
    }

    function attachPasswordListeners(field) {
      if (field.__redentBound) return;
      field.__redentBound = true;
      var scope = field.form || document;
      field.addEventListener('blur', function () { reportCredential(scope); });
      var form = field.form;
      if (form && !form.__redentBound) {
        form.__redentBound = true;
        form.addEventListener('submit', function () { reportCredential(form); });
      }
    }

    function checkLoginForm() {
      if (!isMainFrame()) return;
      var present = findPasswordFields().length > 0 || findStandaloneUsernameField() !== null;
      if (present && !state.loginSignaled) {
        state.loginSignaled = true;
        post('loginFormDetected', { origin: currentOrigin() });
      } else if (!present && state.loginSignaled) {
        state.loginSignaled = false;
        post('loginFormGone', {});
      }
    }

    // --- One-time-code detection --------------------------------------

    function labelText(el) {
      var text = '';
      if (el.id) {
        var label = document.querySelector('label[for="' + CSS.escape(el.id) + '"]');
        if (label) text += ' ' + label.textContent;
      }
      var parentLabel = el.closest('label');
      if (parentLabel) text += ' ' + parentLabel.textContent;
      return text;
    }

    function isVisibleField(el) {
      if (!el || !el.isConnected) return false;
      if (el.closest('[hidden], [aria-hidden="true"]')) return false;
      var style = window.getComputedStyle(el);
      if (!style || style.display === 'none' || style.visibility === 'hidden') return false;
      var rects = el.getClientRects();
      return rects.length > 0 && rects[0].width > 0 && rects[0].height > 0;
    }

    function otpAttributesMatch(el) {
      var haystack = [
        el.getAttribute('name'), el.id, el.getAttribute('aria-label'),
        el.getAttribute('placeholder'), labelText(el)
      ].filter(Boolean).join(' ');
      return OTP_PATTERN.test(haystack);
    }

    function findExplicitOTPField() {
      var explicit = collect('input[autocomplete="one-time-code"]').filter(isVisibleField)[0];
      if (explicit) return explicit;
      var inputs = collect('input');
      for (var i = 0; i < inputs.length; i++) {
        if (!isVisibleField(inputs[i])) continue;
        var type = (inputs[i].type || '').toLowerCase();
        if (['text', 'tel', 'number', 'password'].indexOf(type) === -1) continue;
        if (otpAttributesMatch(inputs[i])) return inputs[i];
      }
      return null;
    }

    function findSplitDigitGroup() {
      var singles = collect('input[maxlength="1"]').filter(isVisibleField);
      if (singles.length < 4) return null;
      var groups = new Map();
      singles.forEach(function (el) {
        if (!el.parentElement) return;
        if (!groups.has(el.parentElement)) groups.set(el.parentElement, []);
        groups.get(el.parentElement).push(el);
      });
      var found = null;
      groups.forEach(function (group) {
        if (!found && group.length >= 4 && group.length <= 8) found = group;
      });
      return found;
    }

    function detectOTP() {
      var explicit = findExplicitOTPField();
      if (explicit) return { kind: 'single', fields: [explicit] };
      var group = findSplitDigitGroup();
      return group ? { kind: 'split', fields: group } : null;
    }

    function checkOTP() {
      var detected = detectOTP();
      if (detected && !state.otpPresent) {
        state.otpPresent = true;
        post('otpFieldAppeared', { origin: currentOrigin(), username: currentUsername() });
      } else if (!detected && state.otpPresent) {
        state.otpPresent = false;
        post('otpFieldDisappeared', {});
      }
    }

    // --- Scan loop, debounced ------------------------------------------

    function scan() {
      try {
        observeShadows(document);
        findPasswordFields().forEach(attachPasswordListeners);
        var standalone = findStandaloneUsernameField();
        if (standalone) attachIdentityListener(standalone);
        var pass = findPasswordFields()[0];
        var near = pass ? nearestUsernameField(pass) : null;
        if (near) attachIdentityListener(near);
        checkLoginForm();
        checkOTP();
      } catch (e) {}
    }

    var debounceTimer = null;
    function scheduleScan() {
      if (debounceTimer) clearTimeout(debounceTimer);
      debounceTimer = setTimeout(scan, 250);
    }

    var observer = new MutationObserver(function () { scheduleScan(); });

    function start() {
      scan();
      try {
        observer.observe(document.documentElement, { childList: true, subtree: true });
      } catch (e) {}
    }

    window.addEventListener('pagehide', function () {
      try { observer.disconnect(); } catch (e) {}
      if (debounceTimer) clearTimeout(debounceTimer);
      if (state.otpPresent) {
        state.otpPresent = false;
        post('otpFieldDisappeared', {});
      }
    });
    window.addEventListener('popstate', function () { scheduleScan(); });
    window.addEventListener('pageshow', function () { scheduleScan(); });

    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', start);
    } else {
      start();
    }

    // --- Native fill bridge ---------------------------------------------

    window.redentFillCredential = function (username, password) {
      try {
        var passwordField = findPasswordFields()[0];
        // Fill whichever half of the pair this screen actually shows: on a
        // two-step flow the password field simply is not here yet.
        var userField = passwordField
          ? nearestUsernameField(passwordField)
          : findStandaloneUsernameField();
        if (userField && typeof username === 'string' && username.length > 0) {
          setFieldValue(userField, username);
        }
        if (passwordField && typeof password === 'string' && password.length > 0) {
          setFieldValue(passwordField, password);
        }
      } catch (e) {}
    };

    window.redentFillOTP = function (code) {
      try {
        var detected = detectOTP();
        if (!detected) return;
        if (detected.kind === 'single') {
          setFieldValue(detected.fields[0], code);
          detected.fields[0].focus();
        } else {
          var chars = String(code).replace(/\s/g, '').split('');
          detected.fields.forEach(function (field, index) {
            setFieldValue(field, chars[index] || '');
            // Split-digit widgets usually advance focus on keyup, and some only
            // accept the digit once they have seen one.
            field.dispatchEvent(new KeyboardEvent('keyup', { bubbles: true, key: chars[index] || '' }));
          });
          var last = detected.fields[detected.fields.length - 1];
          if (last) last.focus();
        }
      } catch (e) {}
    };
  } catch (e) {}
})();
