var gt=Object.defineProperty;var Y=(o,t)=>{for(var e in t)gt(o,e,{get:t[e],enumerable:!0})};var at={};Y(at,{DEFAULT_VIEW:()=>Z,LocationsSettingsTab:()=>U,locationsSettingsTabStyles:()=>E,renderEditorView:()=>W,renderLocationDialog:()=>X,validateAccuracy:()=>ot,validateLatitude:()=>Q,validateLocale:()=>it,validateLongitude:()=>tt,validateTimezoneId:()=>et,validateTitle:()=>J});import"./../../ui/kit/kit.js";import"./../../ui/components/lists/lists.js";import*as G from"./../../core/common/common.js";import*as M from"./../../core/i18n/i18n.js";import*as L from"./../../core/sdk/sdk.js";import"./../../ui/components/buttons/buttons.js";import*as w from"./../../ui/legacy/legacy.js";import{Directives as pt,html as m,nothing as v,render as mt}from"./../../ui/lit/lit.js";import*as _ from"./../../ui/visual_logging/visual_logging.js";var E=`devtools-button.add-locations-button:not(:first-child),
.add-locations-button{margin-bottom:var(--sys-size-5);border:none}devtools-list.locations-list,
.locations-list{margin-top:var(--sys-size-3);flex:auto;display:flex;border:1px solid var(--sys-color-divider)}.locations-list-item{padding:3px 6px;height:30px;display:flex;align-items:center;position:relative;flex:auto 1 1}.locations-list-text{white-space:nowrap;text-overflow:ellipsis;flex-basis:170px;user-select:none;color:var(--sys-color-on-surface);position:relative;overflow:hidden}.locations-list-title{text-align:start}.locations-list-title-text{overflow:hidden;flex:auto;white-space:nowrap;text-overflow:ellipsis}.locations-list-separator{flex:0 0 1px;background-color:var(--sys-color-divider);height:30px;margin:0 4px}.locations-list-separator-invisible{visibility:hidden;height:100%!important}.locations-edit-row{display:flex;flex-direction:row;margin:6px 5px}.locations-edit-row input{width:100%;text-align:inherit}.locations-input-container{padding:1px}.settings-card-container-wrapper{scrollbar-gutter:stable;padding:var(--sys-size-8) 0;overflow:auto;position:absolute;inset:var(--sys-size-8) 0 0}.settings-card-container{display:flex;flex-direction:column;align-items:center;gap:var(--sys-size-9)}.location-dialog-content{padding:var(--sys-size-6);display:flex;flex-direction:column;gap:var(--sys-size-6);width:var(--sys-size-33);min-width:var(--sys-size-33)}.editor-grid{display:grid;grid-template-columns:1fr 1fr;gap:var(--sys-size-5) var(--sys-size-6)}.editor-field-full-width{grid-column:1/-1}.editor-field{display:flex;flex-direction:column;gap:var(--sys-size-2)}.editor-field-label{color:var(--sys-color-on-surface);font-size:var(--sys-size-6);font-weight:var(--ref-typeface-weight-medium)}.editor-field input{width:100%;box-sizing:border-box;padding:var(--sys-size-3) var(--sys-size-4);height:var(--sys-size-11);border:var(--sys-size-1) solid var(--sys-color-neutral-outline);border-radius:var(--sys-size-2);outline:none}.editor-field.has-error input{border-color:var(--sys-color-error)}.editor-field-error{color:var(--sys-color-error);font-size:var(--sys-size-6);overflow-wrap:break-word}.dialog-buttons{display:flex;justify-content:flex-end;gap:var(--sys-size-3);margin-top:var(--sys-size-3)}.dialog-header{display:flex;justify-content:space-between;align-items:center}.dialog-title{font-size:var(--sys-size-7);font-weight:var(--ref-typeface-weight-medium);color:var(--sys-color-on-surface)}.dialog-close-button{flex-shrink:0}
/*# sourceURL=${import.meta.resolve("./locationsSettingsTab.css")} */`;var{createRef:S,ref:I}=pt;var s={locations:"Locations",locationName:"Location name",lat:"Lat",long:"Long",timezoneId:"Timezone ID",locale:"Locale",latitude:"Latitude",longitude:"Longitude",accuracy:"Accuracy",locationNameCannotBeEmpty:"Location name can\u2019t be empty",locationNameMustBeLessThanS:"Location name must be less than {PH1} characters",latitudeMustBeANumber:"Latitude must be a number",latitudeMustBeGreaterThanOrEqual:"Latitude must be greater than or equal to {PH1}",latitudeMustBeLessThanOrEqualToS:"Latitude must be less than or equal to {PH1}",longitudeMustBeANumber:"Longitude must be a number",longitudeMustBeGreaterThanOr:"Longitude must be greater than or equal to {PH1}",longitudeMustBeLessThanOrEqualTo:"Longitude must be less than or equal to {PH1}",timezoneIdMustContainAlphabetic:"Timezone ID must contain alphabetic characters",localeMustContainAlphabetic:"Locale must contain alphabetic characters",accuracyMustBeANumber:"Accuracy must be a number",accuracyMustBeGreaterThanOrEqual:"Accuracy must be greater than or equal to {PH1}",addLocation:"Add location",editLocation:"Edit location",save:"Save",cancel:"Cancel",close:"Close"},ht=M.i18n.registerUIStrings("panels/sensors/LocationsSettingsTab.ts",s),r=M.i18n.getLocalizedString.bind(void 0,ht);function vt(o){return m`
    <div class="locations-list-item">
      <div class="locations-list-text locations-list-title">
        <div class="locations-list-title-text" title=${o.title}>${o.title}</div>
      </div>
      <div class="locations-list-separator"></div>
      <div class="locations-list-text">${o.lat}</div>
      <div class="locations-list-separator"></div>
      <div class="locations-list-text">${o.long}</div>
      <div class="locations-list-separator"></div>
      <div class="locations-list-text">${o.timezoneId}</div>
      <div class="locations-list-separator"></div>
      <div class="locations-list-text">${o.locale}</div>
      <div class="locations-list-separator"></div>
      <div class="locations-list-text">${o.accuracy??L.EmulationModel.Location.DEFAULT_ACCURACY}</div>
    </div>`}function W(o,t,e=!1){return e?m`
    <div class="editor-grid">
      <div class="editor-field editor-field-full-width ${t?.title?"has-error":""}">
        <label class="editor-field-label" for="location-title">${r(s.locationName)}</label>
        ${o.titleInput}
        ${t?.title?m`<div class="editor-field-error" role="alert">${t.title}</div>`:v}
      </div>
      <div class="editor-field ${t?.lat?"has-error":""}">
        <label class="editor-field-label" for="location-lat">${r(s.lat)}</label>
        ${o.latInput}
        ${t?.lat?m`<div class="editor-field-error" role="alert">${t.lat}</div>`:v}
      </div>
      <div class="editor-field ${t?.long?"has-error":""}">
        <label class="editor-field-label" for="location-long">${r(s.long)}</label>
        ${o.longInput}
        ${t?.long?m`<div class="editor-field-error" role="alert">${t.long}</div>`:v}
      </div>
      <div class="editor-field ${t?.timezoneId?"has-error":""}">
        <label class="editor-field-label" for="location-timezone">${r(s.timezoneId)}</label>
        ${o.timezoneIdInput}
        ${t?.timezoneId?m`<div class="editor-field-error" role="alert">${t.timezoneId}</div>`:v}
      </div>
      <div class="editor-field ${t?.locale?"has-error":""}">
        <label class="editor-field-label" for="location-locale">${r(s.locale)}</label>
        ${o.localeInput}
        ${t?.locale?m`<div class="editor-field-error" role="alert">${t.locale}</div>`:v}
      </div>
      <div class="editor-field editor-field-full-width ${t?.accuracy?"has-error":""}">
        <label class="editor-field-label" for="location-accuracy">${r(s.accuracy)}</label>
        ${o.accuracyInput}
        ${t?.accuracy?m`<div class="editor-field-error" role="alert">${t.accuracy}</div>`:v}
      </div>
    </div>
  `:m`
      <div class="locations-edit-row">
        <div class="locations-list-text locations-list-title">${r(s.locationName)}</div>
        <div class="locations-list-separator locations-list-separator-invisible"></div>
        <div class="locations-list-text">${r(s.lat)}</div>
        <div class="locations-list-separator locations-list-separator-invisible"></div>
        <div class="locations-list-text">${r(s.long)}</div>
        <div class="locations-list-separator locations-list-separator-invisible"></div>
        <div class="locations-list-text">${r(s.timezoneId)}</div>
        <div class="locations-list-separator locations-list-separator-invisible"></div>
        <div class="locations-list-text">${r(s.locale)}</div>
        <div class="locations-list-separator locations-list-separator-invisible"></div>
        <div class="locations-list-text">${r(s.accuracy)}</div>
      </div>
      <div class="locations-edit-row">
        <div class="locations-list-text locations-list-title locations-input-container">${o.titleInput}</div>
        <div class="locations-list-separator locations-list-separator-invisible"></div>
        <div class="locations-list-text locations-input-container">${o.latInput}</div>
        <div class="locations-list-separator locations-list-separator-invisible"></div>
        <div class="locations-list-text locations-list-text-longitude locations-input-container">${o.longInput}</div>
        <div class="locations-list-separator locations-list-separator-invisible"></div>
        <div class="locations-list-text locations-input-container">${o.timezoneIdInput}</div>
        <div class="locations-list-separator locations-list-separator-invisible"></div>
        <div class="locations-list-text locations-input-container">${o.localeInput}</div>
        <div class="locations-list-separator locations-list-separator-invisible"></div>
        <div class="locations-list-text locations-input-container">${o.accuracyInput}</div>
      </div>
      ${t?m`
        <div class="locations-edit-row locations-error-row" role="alert">
          <div class="locations-list-text locations-list-title locations-error-cell">${t.title??v}</div>
          <div class="locations-list-separator locations-list-separator-invisible"></div>
          <div class="locations-list-text locations-error-cell">${t.lat??v}</div>
          <div class="locations-list-separator locations-list-separator-invisible"></div>
          <div class="locations-list-text locations-list-text-longitude locations-error-cell">${t.long??v}</div>
          <div class="locations-list-separator locations-list-separator-invisible"></div>
          <div class="locations-list-text locations-error-cell">${t.timezoneId??v}</div>
          <div class="locations-list-separator locations-list-separator-invisible"></div>
          <div class="locations-list-text locations-error-cell">${t.locale??v}</div>
          <div class="locations-list-separator locations-list-separator-invisible"></div>
          <div class="locations-list-text locations-error-cell">${t.accuracy??v}</div>
        </div>
      `:v}`}function X(o){let t=S(),e=S(),i=S(),l=S(),a=S(),u=S(),n=()=>{let N=t.value?.value.trim()??"",O=e.value?.value.trim()??"",z=i.value?.value.trim()??"",B=l.value?.value.trim()??"",F=a.value?.value.trim()??"",k=u.value?.value.trim()??"",P=J(N),j=Q(O),R=tt(z),K=et(B),q=it(F),H=ot(k);if(P||j||R||K||q||H){o.onValidateErrors({title:P,lat:j,long:R,timezoneId:K,locale:q,accuracy:H});return}o.onSave({title:N,lat:O?parseFloat(O):0,long:z?parseFloat(z):0,timezoneId:B,locale:F,accuracy:k?parseFloat(k):L.EmulationModel.Location.DEFAULT_ACCURACY})},x={titleInput:m`<input id="location-title" aria-label=${r(s.locationName)} type="text" placeholder=${r(s.locationName)} .value=${o.location.title} ${I(t)}>`,latInput:m`<input id="location-lat" aria-label=${r(s.lat)} type="text" placeholder=${r(s.latitude)} .value=${String(o.location.lat)} ${I(e)}>`,longInput:m`<input id="location-long" aria-label=${r(s.long)} type="text" placeholder=${r(s.longitude)} .value=${String(o.location.long)} ${I(i)}>`,timezoneIdInput:m`<input id="location-timezone" aria-label=${r(s.timezoneId)} type="text" placeholder=${r(s.timezoneId)} .value=${o.location.timezoneId} ${I(l)}>`,localeInput:m`<input id="location-locale" aria-label=${r(s.locale)} type="text" placeholder=${r(s.locale)} .value=${o.location.locale} ${I(a)}>`,accuracyInput:m`<input id="location-accuracy" aria-label=${r(s.accuracy)} type="text" placeholder=${r(s.accuracy)} .value=${String(o.location.accuracy??L.EmulationModel.Location.DEFAULT_ACCURACY)} ${I(u)}>`},ut=m`
    <style>${E}</style>
      <div class="location-dialog-content">
      <div class="dialog-header">
        <span class="dialog-title">${o.isNew?r(s.addLocation):r(s.editLocation)}</span>
        <devtools-button
          class="dialog-close-button"
          .iconName=${"cross"}
          .variant=${"icon"}
          .title=${r(s.close)}
          .jslogContext=${"dialog-close"}
          @click=${o.onCancel}
          aria-label=${r(s.close)}>
        </devtools-button>
      </div>
        ${W(x,o.errors,!0)}
        <div class="dialog-buttons">
          <devtools-button
            class="save-button"
            .variant=${"primary"}
            @click=${n}>
            ${r(s.save)}
          </devtools-button>
          <devtools-button
            class="cancel-button"
            .variant=${"outlined"}
            @click=${o.onCancel}>
            ${r(s.cancel)}
          </devtools-button>
        </div>
      </div>
  `;return m`
    <style>${E}</style>
    <devtools-widget
      class="location-dialog-widget"
      ${w.Widget.widget(w.Dialog.DialogWidget,{open:!0,jslogContext:"location-dialog",dialogStack:!0,content:ut})}
      @hidden=${o.onCancel}>
    </devtools-widget>
  `}var Z=(o,t,e)=>{mt(m`
    <style>${E}</style>
    <div class="settings-card-container-wrapper">
      <div class="settings-card-container">
        <devtools-card .heading=${r(s.locations)}>
          <div>
            ${o.locations.length>0?m`
              <devtools-list
                class="locations-list square-corners"
                .editable=${!0}
                .deletable=${!0}
                @edit=${i=>o.onEditLocation(i.detail.index)}
                @delete=${i=>o.onRemoveLocation(i.detail.index)}>
                ${o.locations.map(i=>vt(i))}
              </devtools-list>
            `:v}
          </div>
          <devtools-button
            class="add-locations-button"
            .variant=${"outlined"}
            .iconName=${"plus"}
            .jslogContext=${"emulation.add-location"}
            @click=${o.onAddLocation}>
            ${r(s.addLocation)}
          </devtools-button>
        </devtools-card>
      </div>
    </div>
    ${o.activeDialog?X(o.activeDialog):v}
  `,e)},U=class extends w.Widget.VBox{customSetting;#i;#t;constructor(t,e=Z){super(t,{jslog:`${_.pane("emulation-locations")}`,useShadowDom:!0}),this.#i=e,this.customSetting=G.Settings.Settings.instance().moduleSetting("emulation.locations");let i=this.customSetting.get().map(a=>l(a,this.customSetting.defaultValue));function l(a,u){if(!a.title){let n=u.find(x=>x.lat===a.lat&&x.long===a.long&&x.timezoneId===a.timezoneId&&x.locale===a.locale);if(!n)console.error("Could not determine a location setting title");else return n}return a}this.customSetting.set(i),this.customSetting.addChangeListener(this.locationsUpdated,this)}wasShown(){super.wasShown(),this.locationsUpdated()}performUpdate(){let t;if(this.#t){let i=this.#t;t={location:i.location,isNew:i.isNew,errors:i.errors,onSave:l=>this.saveDialog(l),onCancel:()=>this.closeDialog(),onValidateErrors:l=>this.updateDialogErrors(l)}}let e={locations:this.customSetting.get(),onAddLocation:()=>this.addButtonClicked(),onEditLocation:i=>this.editLocationClicked(i),onRemoveLocation:i=>this.removeLocationClicked(i),activeDialog:t};this.#i(e,void 0,this.contentElement)}locationsUpdated(){this.requestUpdate()}addButtonClicked(){this.#t={location:{title:"",lat:0,long:0,timezoneId:"",locale:"",accuracy:L.EmulationModel.Location.DEFAULT_ACCURACY},isNew:!0},this.requestUpdate()}editLocationClicked(t){let i=this.customSetting.get()[t];i&&(this.#t={location:{...i},isNew:!1,index:t},this.requestUpdate())}removeLocationClicked(t){let e=this.customSetting.get();e.splice(t,1),this.customSetting.set(e)}saveDialog(t){if(!this.#t)return;let e=this.customSetting.get();this.#t.isNew?e.push(t):this.#t.index!==void 0&&(e[this.#t.index]=t),this.#t=void 0,this.customSetting.set(e)}closeDialog(){this.#t=void 0,this.requestUpdate()}updateDialogErrors(t){this.#t&&(this.#t.errors=t,this.requestUpdate())}};function J(o){let e=o.trim();return e.length?e.length>50?r(s.locationNameMustBeLessThanS,{PH1:50}):null:r(s.locationNameCannotBeEmpty)}function Q(o){let i=o.trim(),l=Number(i);return i?Number.isNaN(l)?r(s.latitudeMustBeANumber):l<-90?r(s.latitudeMustBeGreaterThanOrEqual,{PH1:-90}):l>90?r(s.latitudeMustBeLessThanOrEqualToS,{PH1:90}):null:null}function tt(o){let i=o.trim(),l=Number(i);return i?Number.isNaN(l)?r(s.longitudeMustBeANumber):l<-180?r(s.longitudeMustBeGreaterThanOr,{PH1:-180}):l>180?r(s.longitudeMustBeLessThanOrEqualTo,{PH1:180}):null:null}function et(o){let t=o.trim();return t===""||/[a-zA-Z]/.test(t)?null:r(s.timezoneIdMustContainAlphabetic)}function it(o){let t=o.trim();return t===""||/[a-zA-Z]{2}/.test(t)?null:r(s.localeMustContainAlphabetic)}function ot(o){let e=o.trim(),i=Number(e);return e?Number.isNaN(i)?r(s.accuracyMustBeANumber):i<0?r(s.accuracyMustBeGreaterThanOrEqual,{PH1:0}):null:null}var dt={};Y(dt,{NonPresetOptions:()=>f,PressureOptions:()=>bt,SensorsView:()=>A,ShiftDragOrientationSpeed:()=>ct,ShowActionDelegate:()=>V});import*as $ from"./../../core/common/common.js";import*as rt from"./../../core/host/host.js";import*as T from"./../../core/i18n/i18n.js";import*as p from"./../../core/sdk/sdk.js";import*as y from"./../../models/geometry/geometry.js";import"./../../ui/components/buttons/buttons.js";import*as C from"./../../ui/legacy/components/settings_ui/settings_ui.js";import*as b from"./../../ui/legacy/legacy.js";import{Directives as h,html as D,render as st}from"./../../ui/lit/lit.js";import*as g from"./../../ui/visual_logging/visual_logging.js";import*as lt from"./../mobile_throttling/mobile_throttling.js";var nt=`.sensors-view{padding:12px;display:block}.sensors-view input{width:100%;max-width:120px;margin:-5px 10px 0 0;text-align:end}.sensors-view input[readonly]{background-color:var(--sys-color-neutral-container)}.sensors-view fieldset{border:none;padding:10px 0;flex:0 0 auto;margin:0}.sensors-view fieldset[disabled]{opacity:50%}.orientation-axis-input-container input{max-width:120px}.concurrency-details{margin:var(--sys-size-5) var(--sys-size-10);display:flex;align-items:center}.concurrency-details input{width:50px;margin:0}.concurrency-hidden{visibility:hidden}.sensors-view input:focus::-webkit-input-placeholder{color:transparent!important}.sensors-view select{width:200px}.sensors-group-title{width:80px;line-height:24px}.sensors-group{display:flex;flex-wrap:wrap;margin-bottom:10px}.manage-locations{margin-left:var(--sys-size-4)}.geo-fields{flex:2 0 200px}.latlong-group{display:flex;margin-bottom:10px}.latlong-title{width:70px}.timezone-error,
.locale-error{margin-left:10px;color:var(--legacy-input-validation-error)}.orientation-content{display:flex;flex-wrap:wrap}.orientation-fields{margin-right:10px}.orientation-stage{--override-gradient-color-1:var(--ref-palette-cyan95);--override-gradient-color-2:var(--ref-palette-cyan90);perspective:700px;perspective-origin:50% 50%;width:160px;height:150px;background:linear-gradient(var(--override-gradient-color-1) 0%,var(--override-gradient-color-1) 64%,var(--override-gradient-color-2) 64%,var(--override-gradient-color-1) 100%);transition:0.2s ease opacity,0.2s ease filter;overflow:hidden;margin-bottom:10px}.theme-with-dark-background .orientation-stage,
:host-context(.theme-with-dark-background) .orientation-stage{--override-gradient-color-1:var(--ref-palette-cyan10);--override-gradient-color-2:var(--ref-palette-cyan30)}.orientation-stage.disabled{filter:grayscale();opacity:50%}.orientation-element,
.orientation-element::before,
.orientation-element::after{position:absolute;box-sizing:border-box;transform-style:preserve-3d;background:no-repeat;background-size:cover;backface-visibility:hidden}.orientation-box{width:62px;height:122px;inset:0;margin:auto;transform:rotate3d(1,0,0,90deg)}.orientation-layer{width:100%;height:100%;transform-style:preserve-3d}.orientation-box.is-animating,
.is-animating .orientation-layer{transition:transform 300ms cubic-bezier(0.4,0,0.2,1) 0ms}.orientation-front,
.orientation-back{width:62px;height:122px;border-radius:8px}.orientation-front{background-image:var(--image-file-accelerometer-front)}.orientation-back{transform:rotateY(180deg) translateZ(8px);background-image:var(--image-file-accelerometer-back)}.orientation-left,
.orientation-right{width:8px;height:106px;top:8px;background-position:center center}.orientation-left{left:-8px;transform-origin:right center;transform:rotateY(-90deg);background-image:var(--image-file-accelerometer-left)}.orientation-right{right:-8px;transform-origin:left center;transform:rotateY(90deg);background-image:var(--image-file-accelerometer-right)}.orientation-left::before,
.orientation-left::after,
.orientation-right::before,
.orientation-right::after{content:"";width:8px;height:6px}.orientation-left::before,
.orientation-left::after{background-image:var(--image-file-accelerometer-left)}.orientation-right::before,
.orientation-right::after{background-image:var(--image-file-accelerometer-right)}.orientation-left::before,
.orientation-right::before{top:-6px;transform-origin:center bottom;transform:rotateX(26deg);background-position:center top}.orientation-left::after,
.orientation-right::after{bottom:-6px;transform-origin:center top;transform:rotateX(-25deg);background-position:center bottom}.orientation-top,
.orientation-bottom{width:50px;height:8px;left:8px;background-position:center center}.orientation-top{top:-8px;transform-origin:center bottom;transform:rotateX(90deg);background-image:var(--image-file-accelerometer-top)}.orientation-bottom{bottom:-8px;transform-origin:center top;transform:rotateX(-90deg);background-image:var(--image-file-accelerometer-bottom)}.orientation-top::before,
.orientation-top::after,
.orientation-bottom::before,
.orientation-bottom::after{content:"";width:8px;height:8px}.orientation-top::before,
.orientation-top::after{background-image:var(--image-file-accelerometer-top)}.orientation-bottom::before,
.orientation-bottom::after{background-image:var(--image-file-accelerometer-bottom)}.orientation-top::before,
.orientation-bottom::before{left:-6px;transform-origin:right center;transform:rotateY(-26deg);background-position:left center}.orientation-top::after,
.orientation-bottom::after{right:-6px;transform-origin:left center;transform:rotateY(26deg);background-position:right center}.orientation-axis-input-container{margin-bottom:10px}.orientation-reset-button{min-width:80px}fieldset.device-orientation-override-section{margin:0;display:flex}.panel-section-separator{height:1px;margin-bottom:20px;margin-left:-12px;margin-right:-12px;background:var(--sys-color-divider)}button.text-button{margin:4px 0 0 10px}@media (forced-colors: active){.sensors-view fieldset[disabled]{opacity:100%}}.chrome-select-label{margin-bottom:16px}
/*# sourceURL=${import.meta.resolve("./sensors.css")} */`;var c={location:"Location",noOverride:"No override",overrides:"Overrides",manage:"Manage",manageTheListOfLocations:"Manage the list of locations",other:"Other\u2026",error:"Error",locationUnavailable:"Location unavailable",adjustWithMousewheelOrUpdownKeys:"Adjust with mousewheel or up/down keys. {PH1}: \xB110, Shift: \xB11, Alt: \xB10.01.",latitude:"Latitude",longitude:"Longitude",timezoneId:"Timezone ID",locale:"Locale",accuracy:"Accuracy",orientation:"Orientation",off:"Off",customOrientation:"Custom orientation",enableOrientationToRotate:"Enable orientation to rotate",shiftdragHorizontallyToRotate:"Shift+drag horizontally to rotate around the y-axis",deviceOrientationSetToAlphaSBeta:"Device orientation set to alpha: {PH1}, beta: {PH2}, gamma: {PH3}",reset:"Reset",resetDeviceOrientation:"Reset device orientation",forcesTouchInsteadOfClick:"Forces touch instead of click",forcesSelectedIdleStateEmulation:"Forces selected idle state emulation",forcesSelectedPressureStateEmulation:"Forces selected pressure state emulation",presets:"Presets",portrait:"Portrait",portraitUpsideDown:"Portrait upside down",landscapeLeft:"Landscape left",landscapeRight:"Landscape right",displayUp:"Display up",displayDown:"Display down",alpha:"\u03B1 (alpha)",beta:"\u03B2 (beta)",gamma:"\u03B3 (gamma)"},ft=T.i18n.registerUIStrings("panels/sensors/SensorsView.ts",c),d=T.i18n.getLocalizedString.bind(void 0,ft),A=class extends b.Widget.VBox{#i;#t;#e;#s;fieldsetElement;timezoneError;locationSelectElement;latitudeInput;longitudeInput;timezoneInput;localeInput;accuracyInput;localeError;accuracyError;deviceOrientationSetting;deviceOrientation;deviceOrientationOverrideEnabled;deviceOrientationFieldset;stageElement;orientationSelectElement;alphaElement;betaElement;gammaElement;orientationLayer;boxMatrix;mouseDownVector;originalBoxMatrix;constructor(){super({jslog:`${g.panel("sensors").track({resize:!0})}`,useShadowDom:!0}),this.registerRequiredCSS(nt),this.contentElement.classList.add("sensors-view"),this.#i=$.Settings.Settings.instance().createSetting("emulation.location-override",""),this.#t=p.EmulationModel.Location.parseSetting(this.#i.get()),this.#e=!1,this.#s=this.contentElement.createChild("section","sensors-group");let t=$.Settings.Settings.instance().moduleSetting("emulation.locations");this.renderLocationSection(this.#t,t),t.addChangeListener(()=>this.renderLocationSection(this.#t,t)),this.createPanelSeparator(),this.deviceOrientationSetting=$.Settings.Settings.instance().createSetting("emulation.device-orientation-override",""),this.deviceOrientation=p.EmulationModel.DeviceOrientation.parseSetting(this.deviceOrientationSetting.get()),this.deviceOrientationOverrideEnabled=!1,this.createDeviceOrientationSection(),this.createPanelSeparator(),this.appendTouchControl(),this.createPanelSeparator(),this.appendIdleEmulator(),this.createPanelSeparator(),this.createHardwareConcurrencySection(),this.createPanelSeparator(),this.createPressureSection(),this.createPanelSeparator()}createPanelSeparator(){this.contentElement.createChild("div").classList.add("panel-section-separator")}renderLocationSection(t,e){let i=e.get(),l=0;if(this.#e)if(t.unavailable)l=i.length+2;else{l=i.length+1;for(let[n,x]of i.entries())if(t.latitude===x.lat&&t.longitude===x.long&&t.timezoneId===x.timezoneId&&t.locale===x.locale){l=n+1;break}}let a=rt.Platform.isMac()?"\u2318":"Ctrl",u=d(c.adjustWithMousewheelOrUpdownKeys,{PH1:a});this.#s.setAttribute("jslog",`${g.section("location")}`),st(D`
      <label class="sensors-group-title" id="location-select-label" for="location-select">${d(c.location)}</label>
      <div class="geo-fields">
        <select
          id="location-select"
          ${h.ref(n=>{n&&(this.locationSelectElement=n)})}
          .selectedIndex=${l}
          @change=${this.#d.bind(this)}
          jslog=${g.dropDown().track({change:!0})}
        >
          <option value=${f.NoOverride} jslog=${g.item("no-override")}>${d(c.noOverride)}</option>
          <optgroup label=${d(c.overrides)}>
            ${i.map(n=>D`
              <option value=${JSON.stringify(n)} jslog=${g.item("custom")}>${n.title}</option>
            `)}
          </optgroup>
          <option value=${f.Custom} jslog=${g.item("other")}>${d(c.other)}</option>
          <optgroup label=${d(c.error)}>
            <option value=${f.Unavailable} jslog=${g.item("unavailable")}>${d(c.locationUnavailable)}</option>
          </optgroup>
        </select>
        <devtools-button
          .variant=${"outlined"}
          class="manage-locations"
          @click=${()=>$.Revealer.reveal(e)}
          aria-label=${d(c.manageTheListOfLocations)}
          jslog=${g.action("sensors.manage-locations").track({click:!0})}
        >
          ${d(c.manage)}
        </devtools-button>
        <fieldset
          id="location-override-section"
          ?disabled=${!this.#e}
          ${h.ref(n=>{n&&(this.fieldsetElement=n)})}
        >
          <div class="latlong-group">
            <!-- @ts-ignore -->
            <input
              id="latitude-input"
              type="number"
              min="-90"
              max="90"
              step="any"
              required
              .value=${String(t.latitude)}
              name="latitude"
              title=${u}
              jslog=${g.textField("latitude").track({change:!0})}
              ${h.ref(n=>{n&&(this.latitudeInput=n)})}
              @change=${this.#o.bind(this)}
              @keydown=${this.#a.bind(this)}
              @focus=${this.#n.bind(this)}
            >
            <label class="latlong-title" for="latitude-input">${d(c.latitude)}</label>
          </div>
          <div class="latlong-group">
            <!-- @ts-ignore -->
            <input
              id="longitude-input"
              type="number"
              min="-180"
              max="180"
              step="any"
              required
              .value=${String(t.longitude)}
              name="longitude"
              title=${u}
              jslog=${g.textField("longitude").track({change:!0})}
              ${h.ref(n=>{n&&(this.longitudeInput=n)})}
              @change=${this.#o.bind(this)}
              @keydown=${this.#a.bind(this)}
              @focus=${this.#n.bind(this)}
            >
            <label class="latlong-title" for="longitude-input">${d(c.longitude)}</label>
          </div>
          <div class="latlong-group">
            <input
              id="timezone-input"
              type="text"
              pattern=".*[a-zA-Z].*"
              .value=${t.timezoneId}
              name="timezone"
              jslog=${g.textField("timezone").track({change:!0})}
              ${h.ref(n=>{n&&(this.timezoneInput=n)})}
              @change=${this.#o.bind(this)}
              @keydown=${this.#a.bind(this)}
              @focus=${this.#n.bind(this)}
            >
            <label class="timezone-title" for="timezone-input">${d(c.timezoneId)}</label>
            <div class="timezone-error" ${h.ref(n=>{n&&(this.timezoneError=n)})}></div>
          </div>
          <div class="latlong-group">
            <input
              id="locale-input"
              type="text"
              pattern=".*[a-zA-Z]{2}.*"
              .value=${t.locale}
              name="locale"
              jslog=${g.textField("locale").track({change:!0})}
              ${h.ref(n=>{n&&(this.localeInput=n)})}
              @change=${this.#o.bind(this)}
              @keydown=${this.#a.bind(this)}
              @focus=${this.#n.bind(this)}
            >
            <label class="locale-title" for="locale-input">${d(c.locale)}</label>
            <div class="locale-error" ${h.ref(n=>{n&&(this.localeError=n)})}></div>
          </div>
          <div class="latlong-group">
            <!-- @ts-ignore -->
            <input
              id="accuracy-input"
              type="number"
              min="0"
              step="any"
              .value=${String(t.accuracy||p.EmulationModel.Location.DEFAULT_ACCURACY)}
              name="accuracy"
              jslog=${g.textField("accuracy").track({change:!0})}
              ${h.ref(n=>{n&&(this.accuracyInput=n)})}
              @change=${this.#o.bind(this)}
              @keydown=${this.#a.bind(this)}
              @focus=${this.#n.bind(this)}
            >
            <label class="accuracy-title" for="accuracy-input">${d(c.accuracy)}</label>
            <div class="accuracy-error" ${h.ref(n=>{n&&(this.accuracyError=n)})}></div>
          </div>
        </fieldset>
      </div>
    `,this.#s)}#d(){this.fieldsetElement.disabled=!1,this.timezoneError.textContent="",this.accuracyError.textContent="";let t=this.locationSelectElement.options[this.locationSelectElement.selectedIndex].value;if(t===f.NoOverride)this.#e=!1,this.clearFieldsetElementInputs(),this.fieldsetElement.disabled=!0;else if(t===f.Custom){this.#e=!0;let e=p.EmulationModel.Location.parseUserInput(this.latitudeInput.value.trim(),this.longitudeInput.value.trim(),this.timezoneInput.value.trim(),this.localeInput.value.trim(),this.accuracyInput.value.trim());if(!e)return;this.#t=e}else if(t===f.Unavailable)this.#e=!0,this.#t=new p.EmulationModel.Location(0,0,"","",p.EmulationModel.Location.DEFAULT_ACCURACY,!0);else{this.#e=!0;let e=JSON.parse(t);this.#t=new p.EmulationModel.Location(e.lat,e.long,e.timezoneId,e.locale,e.accuracy||p.EmulationModel.Location.DEFAULT_ACCURACY,!1),this.latitudeInput.value=e.lat,this.longitudeInput.value=e.long,this.timezoneInput.value=e.timezoneId,this.localeInput.value=e.locale,this.accuracyInput.value=String(e.accuracy||p.EmulationModel.Location.DEFAULT_ACCURACY)}this.applyLocation(),t===f.Custom&&this.latitudeInput.focus()}#o(t){t.currentTarget.checkValidity()&&this.applyLocationUserInput()}#a(t){let e=t.currentTarget;if(t.key==="Enter"){e.checkValidity()&&this.applyLocationUserInput(),t.preventDefault();return}if(!(e===this.latitudeInput||e===this.longitudeInput||e===this.accuracyInput))return;let l=e===this.accuracyInput?1:.1,a=b.UIUtils.modifiedFloatNumber(parseFloat(e.value),t,l);if(a===null)return;let u=e.value;e.value=String(a),e.checkValidity()?this.applyLocationUserInput():e.value=u,t.preventDefault()}#n(t){t.currentTarget.select()}applyLocationUserInput(){let t=p.EmulationModel.Location.parseUserInput(this.latitudeInput.value.trim(),this.longitudeInput.value.trim(),this.timezoneInput.value.trim(),this.localeInput.value.trim(),this.accuracyInput.value.trim());t&&(this.timezoneError.textContent="",this.accuracyError.textContent="",this.setSelectElementLabel(this.locationSelectElement,f.Custom),this.#t=t,this.applyLocation())}applyLocation(){this.#e?this.#i.set(this.#t.toSetting()):this.#i.set("");for(let t of p.TargetManager.TargetManager.instance().models(p.EmulationModel.EmulationModel))t.emulateLocation(this.#e?this.#t:null).catch(e=>{switch(e.type){case"emulation-set-timezone":{this.timezoneError.textContent=e.message;break}case"emulation-set-locale":{this.localeError.textContent=e.message;break}case"emulation-set-accuracy":{this.accuracyError.textContent=e.message;break}}})}clearFieldsetElementInputs(){this.latitudeInput.value="0",this.longitudeInput.value="0",this.timezoneInput.value="",this.localeInput.value="",this.accuracyInput.value=p.EmulationModel.Location.DEFAULT_ACCURACY.toString()}createDeviceOrientationSection(){let t=this.contentElement.createChild("section","sensors-group");t.setAttribute("jslog",`${g.section("device-orientation")}`);let e={title:d(c.off),orientation:f.NoOverride,jslogContext:"off"},i={title:d(c.customOrientation),orientation:f.Custom},l=[{title:d(c.presets),value:[{title:d(c.portrait),orientation:"[0, 90, 0]",jslogContext:"portrait"},{title:d(c.portraitUpsideDown),orientation:"[180, -90, 0]",jslogContext:"portrait-upside-down"},{title:d(c.landscapeLeft),orientation:"[90, 0, -90]",jslogContext:"landscape-left"},{title:d(c.landscapeRight),orientation:"[90, -180, -90]",jslogContext:"landscape-right"},{title:d(c.displayUp),orientation:"[0, 0, 0]",jslogContext:"display-up"},{title:d(c.displayDown),orientation:"[0, -180, 0]",jslogContext:"displayUp-down"}]}];st(D`
        <label class="sensors-group-title" for="orientation-select">${d(c.orientation)}</label>
        <div class="orientation-content">
          <div class="orientation-fields">
            <select
              id="orientation-select"
              ${h.ref(a=>{a&&(this.orientationSelectElement=a)})}
              @change=${this.orientationSelectChanged.bind(this)}
              jslog=${g.dropDown().track({change:!0})}
            >
              <option value=${e.orientation} jslog=${g.item(e.jslogContext)}>${e.title}</option>
              <option value=${i.orientation} jslog=${g.item("custom")}>${i.title}</option>
              ${l.map(a=>D`
                <optgroup label=${a.title}>
                  ${a.value.map(u=>D`
                    <option value=${u.orientation} jslog=${g.item(u.jslogContext)}>${u.title}</option>
                  `)}
                </optgroup>
              `)}
            </select>
            <fieldset
              class="device-orientation-override-section"
              ${h.ref(a=>{a&&(this.deviceOrientationFieldset=a)})}
            >
              <div class="orientation-inputs-cell">
                <div class="orientation-axis-input-container">
                  <!-- @ts-ignore -->
                  <input
                    id="alpha-input"
                    type="number"
                    min="0"
                    max="359.9999"
                    step="any"
                    required
                    ${h.ref(a=>{a&&(this.alphaElement=a)})}
                    @change=${this.#r.bind(this)}
                    @keydown=${this.#l.bind(this)}
                    @focus=${this.#c.bind(this)}
                  >
                  <label for="alpha-input">${d(c.alpha)}</label>
                </div>
                <div class="orientation-axis-input-container">
                  <!-- @ts-ignore -->
                  <input
                    id="beta-input"
                    type="number"
                    min="-180"
                    max="179.9999"
                    step="any"
                    required
                    ${h.ref(a=>{a&&(this.betaElement=a)})}
                    @change=${this.#r.bind(this)}
                    @keydown=${this.#l.bind(this)}
                    @focus=${this.#c.bind(this)}
                  >
                  <label for="beta-input">${d(c.beta)}</label>
                </div>
                <div class="orientation-axis-input-container">
                  <!-- @ts-ignore -->
                  <input
                    id="gamma-input"
                    type="number"
                    min="-90"
                    max="89.9999"
                    step="any"
                    required
                    ${h.ref(a=>{a&&(this.gammaElement=a)})}
                    @change=${this.#r.bind(this)}
                    @keydown=${this.#l.bind(this)}
                    @focus=${this.#c.bind(this)}
                  >
                  <label for="gamma-input">${d(c.gamma)}</label>
                </div>
                <devtools-button
                  .variant=${"outlined"}
                  class="orientation-reset-button"
                  type="reset"
                  aria-label=${d(c.resetDeviceOrientation)}
                  @click=${this.resetDeviceOrientation.bind(this)}
                  jslog=${g.action("sensors.reset-device-orientiation").track({click:!0})}
                >
                  ${d(c.reset)}
                </devtools-button>
              </div>
            </fieldset>
          </div>
          <div
            class="orientation-stage"
            jslog=${g.preview().track({drag:!0})}
            ${h.ref(a=>{a&&!this.stageElement&&(this.stageElement=a,b.UIUtils.installDragHandle(this.stageElement,this.onBoxDragStart.bind(this),u=>{this.onBoxDrag(u)},null,"-webkit-grabbing","-webkit-grab"))})}
          >
            <div class="orientation-layer" ${h.ref(a=>{a&&(this.orientationLayer=a)})}>
              <section
                class="orientation-box orientation-element"
              >
                <section class="orientation-front orientation-element"></section>
                <section class="orientation-top orientation-element"></section>
                <section class="orientation-back orientation-element"></section>
                <section class="orientation-left orientation-element"></section>
                <section class="orientation-right orientation-element"></section>
                <section class="orientation-bottom orientation-element"></section>
              </section>
            </div>
          </div>
        </div>
      `,t),this.enableOrientationFields(!0),this.setBoxOrientation(this.deviceOrientation,!1),this.alphaElement.value=String(this.deviceOrientation.alpha),this.betaElement.value=String(this.deviceOrientation.beta),this.gammaElement.value=String(this.deviceOrientation.gamma)}createPressureSection(){let t=this.contentElement.createChild("div","pressure-section"),e=C.SettingsUI.createControlForSetting($.Settings.Settings.instance().resolve(p.SDKSettings.cpuPressureSettingDescriptor),d(c.forcesSelectedPressureStateEmulation));e&&t.appendChild(e)}enableOrientationFields(t){t?(this.deviceOrientationFieldset.disabled=!0,this.stageElement.classList.add("disabled"),b.Tooltip.Tooltip.install(this.stageElement,d(c.enableOrientationToRotate))):(this.deviceOrientationFieldset.disabled=!1,this.stageElement.classList.remove("disabled"),b.Tooltip.Tooltip.install(this.stageElement,d(c.shiftdragHorizontallyToRotate)))}orientationSelectChanged(){let t=this.orientationSelectElement.options[this.orientationSelectElement.selectedIndex].value;if(this.enableOrientationFields(!1),t===f.NoOverride)this.deviceOrientationOverrideEnabled=!1,this.enableOrientationFields(!0),this.applyDeviceOrientation();else if(t===f.Custom)this.deviceOrientationOverrideEnabled=!0,this.resetDeviceOrientation(),this.alphaElement.focus();else{let e=JSON.parse(t);this.deviceOrientationOverrideEnabled=!0,this.deviceOrientation=new p.EmulationModel.DeviceOrientation(e[0],e[1],e[2]),this.setDeviceOrientation(this.deviceOrientation,"selectPreset")}}applyDeviceOrientation(){this.deviceOrientationOverrideEnabled&&this.deviceOrientationSetting.set(this.deviceOrientation.toSetting());for(let t of p.TargetManager.TargetManager.instance().models(p.EmulationModel.EmulationModel))t.emulateDeviceOrientation(this.deviceOrientationOverrideEnabled?this.deviceOrientation:null)}setSelectElementLabel(t,e){let i=Array.prototype.map.call(t.options,l=>l.value);t.selectedIndex=i.indexOf(e)}applyDeviceOrientationUserInput(){this.setDeviceOrientation(p.EmulationModel.DeviceOrientation.parseUserInput(this.alphaElement.value.trim(),this.betaElement.value.trim(),this.gammaElement.value.trim()),"userInput"),this.setSelectElementLabel(this.orientationSelectElement,f.Custom)}resetDeviceOrientation(){this.setDeviceOrientation(new p.EmulationModel.DeviceOrientation(0,90,0),"resetButton"),this.setSelectElementLabel(this.orientationSelectElement,"[0, 90, 0]")}setDeviceOrientation(t,e){if(!t)return;function i(a){return Math.round(a*1e4)/1e4}e!=="userInput"&&(this.alphaElement.value=String(i(t.alpha)),this.betaElement.value=String(i(t.beta)),this.gammaElement.value=String(i(t.gamma)));let l=e!=="userDrag";this.setBoxOrientation(t,l),this.deviceOrientation=t,this.applyDeviceOrientation(),b.ARIAUtils.LiveAnnouncer.alert(d(c.deviceOrientationSetToAlphaSBeta,{PH1:t.alpha,PH2:t.beta,PH3:t.gamma}))}#r(t){t.currentTarget.checkValidity()&&this.applyDeviceOrientationUserInput()}#l(t){let e=t.currentTarget;if(t.key==="Enter"){e.checkValidity()&&this.applyDeviceOrientationUserInput(),t.preventDefault();return}let i=b.UIUtils.modifiedFloatNumber(parseFloat(e.value),t,1);if(i===null)return;let l=e.value;e.value=String(i),e.checkValidity()?this.applyDeviceOrientationUserInput():e.value=l,t.preventDefault()}#c(t){t.currentTarget.select()}setBoxOrientation(t,e){e?this.stageElement.classList.add("is-animating"):this.stageElement.classList.remove("is-animating");let{alpha:i,beta:l,gamma:a}=t;this.boxMatrix=new DOMMatrixReadOnly().rotate(0,0,i).rotate(l,0,0).rotate(0,a,0),this.orientationLayer.style.transform=`rotateY(${i}deg) rotateX(${-l}deg) rotateZ(${a}deg)`}onBoxDrag(t){let e=this.calculateRadiusVector(t.x,t.y);if(!e||!this.mouseDownVector)return!0;t.consume(!0);let i,l;t.shiftKey?(i=new y.Vector(0,0,1),l=(e.x-this.mouseDownVector.x)*ct):(i=y.crossProduct(this.mouseDownVector,e),l=y.calculateAngle(this.mouseDownVector,e));let a=new DOMMatrixReadOnly().rotateAxisAngle(-i.x,i.z,i.y,l).multiply(this.originalBoxMatrix),u=y.EulerAngles.fromDeviceOrientationRotationMatrix(a),n=new p.EmulationModel.DeviceOrientation(u.alpha,u.beta,u.gamma);return this.setDeviceOrientation(n,"userDrag"),this.setSelectElementLabel(this.orientationSelectElement,f.Custom),!1}onBoxDragStart(t){return!this.deviceOrientationOverrideEnabled||(this.mouseDownVector=this.calculateRadiusVector(t.x,t.y),this.originalBoxMatrix=this.boxMatrix,!this.mouseDownVector)?!1:(t.consume(!0),!0)}calculateRadiusVector(t,e){let i=this.stageElement.getBoundingClientRect(),l=Math.max(i.width,i.height)/2,a=(t-i.left-i.width/2)/l,u=(e-i.top-i.height/2)/l,n=a*a+u*u;return n>.5?new y.Vector(a,u,.5/Math.sqrt(n)):new y.Vector(a,u,Math.sqrt(1-n))}appendTouchControl(){let t=this.contentElement.createChild("div","touch-section"),e=C.SettingsUI.createControlForSetting($.Settings.Settings.instance().resolve(p.SDKSettings.touchSettingDescriptor),d(c.forcesTouchInsteadOfClick));e&&t.appendChild(e)}appendIdleEmulator(){let t=this.contentElement.createChild("div","idle-section"),e=C.SettingsUI.createControlForSetting($.Settings.Settings.instance().resolve(p.SDKSettings.idleDetectionSettingDescriptor),d(c.forcesSelectedIdleStateEmulation));e&&t.appendChild(e)}createHardwareConcurrencySection(){let t=this.contentElement.createChild("div","concurrency-section"),{checkbox:e,numericInput:i,reset:l,warning:a}=lt.ThrottlingManager.throttlingManager().createHardwareConcurrencySelector(),u=document.createElement("div");u.classList.add("concurrency-details"),u.append(i.element,l.element,a.element),t.append(e,u)}},bt={NoOverride:"no-override",Nominal:"nominal",Fair:"fair",Serious:"serious",Critical:"critical"},f={NoOverride:"noOverride",Custom:"custom",Unavailable:"unavailable"},V=class{handleAction(t,e){return b.ViewManager.ViewManager.instance().showView("sensors"),!0}},ct=16;export{at as LocationsSettingsTab,dt as SensorsView};
//# sourceMappingURL=sensors.js.map
