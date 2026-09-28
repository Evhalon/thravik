var C=Object.defineProperty;var D=(e,t)=>{for(var n in t)C(e,n,{get:t[n],enumerable:!0})};var S={};D(S,{createControlForSetting:()=>V,createSettingCheckbox:()=>T,renderControlForSetting:()=>$,renderSettingSelect:()=>v});import"./../../../components/settings/settings.js";import"./../../../../core/common/common.js";import*as p from"./../../../../core/i18n/i18n.js";import*as R from"./../../../../core/platform/platform.js";import{Directives as U,html as a,nothing as l,render as y}from"./../../../lit/lit.js";import*as m from"./../../../settings/settings.js";import*as d from"./../../../visual_logging/visual_logging.js";import*as r from"./../../legacy.js";var{createRef:k,ref:q}=U,c={srequiresReload:"*Requires reload",settingsChangedReloadDevTools:"Settings changed. To apply, reload DevTools."},w=p.i18n.registerUIStrings("ui/legacy/components/settings_ui/SettingsUI.ts",c),u=p.i18n.getLocalizedString.bind(void 0,w);function T(e,t,n){let o=r.UIUtils.CheckboxLabel.create(e,void 0,void 0,t.name);return o.name=e,r.UIUtils.bindCheckbox(o,t),n&&r.Tooltip.Tooltip.install(o,n),o}function v(e,t,n){let o=m.SettingUIRegistration.resolve(e.descriptor()),s=o.title,f=o.options,I=o.reloadRequired,h=r.ARIAUtils.nextId("labelledControl"),g=k(),b=i=>{let x=i.target;e.set(f[x.selectedIndex].value),I&&(r.InspectorView.InspectorView.instance().displayReloadRequiredWarning(u(c.settingsChangedReloadDevTools)),g.value&&g.value.classList.remove("hidden"))};return a`
    <div class=${U.classMap({"chrome-select-label":!!t})}>
      <p class="settings-select">
        <label for=${h}>
          ${s}
          ${t?a`<p>${t}</p>`:l}
        </label>
        <select
          id=${h}
          aria-label=${s}
          .disabled=${!!n}
          @change=${b}
          jslog=${d.dropDown().track({change:!0}).context(e.name)}
        >
          ${f.map(i=>i.text&&typeof i.value=="string"?a`
                <option
                  value=${i.value}
                  ?selected=${e.get()===i.value}
                  jslog=${d.item(R.StringUtilities.toKebabCase(i.value)).track({click:!0})}
                >
                  ${i.text}
                </option>
              `:l)}
        </select>
      </p>
      ${I?a`
        <p ${q(g)} class="reload-warning hidden" role="alert" aria-live="polite">
          ${u(c.srequiresReload)}
        </p>`:l}
    </div>
  `}var $=function(e,t,n){switch(e.type()){case"boolean":return a`<setting-checkbox .data=${{setting:e,disabled:n}} @change=${()=>{m.SettingUIRegistration.maybeResolve(e.descriptor())?.reloadRequired&&r.InspectorView.InspectorView.instance().displayReloadRequiredWarning(u(c.settingsChangedReloadDevTools))}}></setting-checkbox>`;case"enum":return v(e,t,n);default:return console.error("Invalid setting type: "+e.type()),l}},V=function(e,t,n){let o=$(e,t,n);if(o===l)return null;let s=document.createDocumentFragment();return y(o,s),s.firstElementChild};export{S as SettingsUI};
//# sourceMappingURL=settings_ui.js.map
