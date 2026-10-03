// WebKit owns matching and selection. Keep clipped application shells in
// place when its native find tries to reveal an off-canvas match.
(function () {
  'use strict';
  var clipped = [];

  window.redentFindPrepare = function () {
    clipped = [];
    function collect(root) {
      root.querySelectorAll('*').forEach(function (element) {
        if (element.shadowRoot) collect(element.shadowRoot);
        if (element.scrollWidth <= element.clientWidth && element.scrollHeight <= element.clientHeight) return;
        var style = window.getComputedStyle(element);
        var horizontal = /hidden|clip/.test(style.overflowX);
        var vertical = /hidden|clip/.test(style.overflowY);
        if (horizontal || vertical) clipped.push({
          element: element, horizontal: horizontal, vertical: vertical,
          left: element.scrollLeft, top: element.scrollTop
        });
      });
    }
    collect(document);
  };

  window.redentFindFinish = function () {
    clipped.forEach(function (entry) {
      if (entry.horizontal) entry.element.scrollLeft = entry.left;
      if (entry.vertical) entry.element.scrollTop = entry.top;
    });
    clipped = [];
  };

  window.redentFindClear = function () {
    var selection = window.getSelection();
    if (selection) selection.removeAllRanges();
  };
})();
