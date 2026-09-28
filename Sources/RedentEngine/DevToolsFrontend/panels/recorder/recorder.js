var Pr=Object.defineProperty;var _=(t,e)=>{for(var r in e)Pr(t,r,{get:e[r],enumerable:!0})};var Ut={};_(Ut,{ControlButton:()=>se,DEFAULT_VIEW:()=>At});import*as Mt from"./../../ui/legacy/legacy.js";import*as Ye from"./../../ui/lit/lit.js";var Pt=`*{margin:0;padding:0;box-sizing:border-box;font-size:inherit}.control{background:none;border:none;display:flex;flex-direction:column;align-items:center}.control[disabled]{filter:grayscale(100%);cursor:auto}.icon{display:flex;width:40px;height:40px;border-radius:50%;background:var(--sys-color-error-bright);margin-bottom:8px;position:relative;transition:background 200ms;place-content:center center;align-items:center}.icon::before{--override-white:#fff;box-sizing:border-box;content:"";display:block;width:14px;height:14px;border:1px solid var(--override-white);position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);background-color:var(--override-white)}.icon.square::before{border-radius:0}.icon.circle::before{border-radius:50%}.icon:hover{background:color-mix(in srgb,var(--sys-color-error-bright),var(--sys-color-state-hover-on-prominent) 10%)}.icon:active{background:color-mix(in srgb,var(--sys-color-error-bright),var(--sys-color-state-ripple-neutral-on-prominent) 16%)}.control[disabled] .icon:hover{background:var(--sys-color-error)}.label{font-size:12px;line-height:16px;text-align:center;letter-spacing:0.02em;color:var(--sys-color-on-surface)}
/*# sourceURL=${import.meta.resolve("./controlButton.css")} */`;var{html:Mr}=Ye,At=(t,e,r)=>{let{label:o,shape:i,disabled:s,onClick:n}=t;Ye.render(Mr`
    <style>${Pt}</style>
    <button
        @click=${g=>{s?(g.stopPropagation(),g.preventDefault()):n(g)}}
        .disabled=${s}
        class="control">
      <div class="icon ${i}"></div>
      <div class="label">${o}</div>
    </button>
  `,r,{container:{attributes:{classes:"flex-none"}}})},se=class extends Mt.Widget.Widget{#t="";#e="square";#o=!1;#i=()=>{};#r;constructor(e,r){super(e,{useShadowDom:"pure"}),this.#r=r||At}set label(e){this.#t=e,this.requestUpdate()}set shape(e){this.#e=e,this.requestUpdate()}set disabled(e){this.#o=e,this.requestUpdate()}set onClick(e){this.#i=e,this.requestUpdate()}performUpdate(){this.#r({label:this.#t,shape:this.#e,disabled:this.#o,onClick:this.#i},{},this.contentElement)}};var Dt={};_(Dt,{CreateRecordingView:()=>ce,DEFAULT_VIEW:()=>Nt});import"./../../ui/kit/kit.js";import*as Ze from"./../../core/i18n/i18n.js";import*as Ne from"./../../models/badges/badges.js";import"./../../ui/components/buttons/buttons.js";import*as De from"./../../ui/components/input/input.js";import*as Qe from"./../../ui/legacy/legacy.js";import*as et from"./../../ui/lit/lit.js";import*as W from"./../../ui/visual_logging/visual_logging.js";var Lt=`*{margin:0;padding:0;outline:none;box-sizing:border-box;font-size:inherit}.wrapper{padding:24px;flex:1}h1{font-size:18px;line-height:24px;letter-spacing:0.02em;color:var(--sys-color-on-surface);margin:0;font-weight:normal}.row-label{font-weight:500;font-size:11px;line-height:16px;letter-spacing:0.8px;text-transform:uppercase;color:var(--sys-color-secondary);margin-bottom:8px;margin-top:32px;display:flex;align-items:center;gap:3px}.footer{display:flex;justify-content:center;border-top:1px solid var(--sys-color-divider);padding:12px;background:var(--sys-color-cdt-base-container)}.controls{display:flex}.error{margin:16px 0 0;padding:8px;background:var(--sys-color-error-container);color:var(--sys-color-error)}.row-label .link:focus-visible{outline:var(--sys-color-state-focus-ring) auto 1px}.header-wrapper{display:flex;align-items:baseline;justify-content:space-between}.checkbox-label{display:inline-flex;align-items:center;overflow:hidden;text-overflow:ellipsis;gap:4px;line-height:1.1;padding:4px}.checkbox-container{display:flex;flex-flow:row wrap;gap:10px}input[type="checkbox"]:focus-visible{outline:var(--sys-color-state-focus-ring) auto 1px}devtools-icon[name="help"]{width:16px;height:16px}
/*# sourceURL=${import.meta.resolve("./createRecordingView.css")} */`;import*as B from"./models/models.js";var{html:Je,Directives:{ref:Ar,createRef:Ur,repeat:Lr}}=et,A={recordingName:"Recording name",startRecording:"Start recording",createRecording:"Create a new recording",recordingNameIsRequired:"Recording name is required",selectorAttribute:"Selector attribute",cancelRecording:"Cancel recording",selectorTypeCSS:"CSS",selectorTypePierce:"Pierce",selectorTypeARIA:"ARIA",selectorTypeText:"Text",selectorTypeXPath:"XPath",selectorTypes:"Selector types to record",includeNecessarySelectors:"You must choose CSS, Pierce, or XPath as one of your options. Only these selectors are guaranteed to be recorded since ARIA and text selectors may not be unique.",learnMore:"Learn more"},Nr=Ze.i18n.registerUIStrings("panels/recorder/CreateRecordingView.ts",A),L=Ze.i18n.getLocalizedString.bind(void 0,Nr),{widget:Dr}=Qe.Widget,Nt=(t,e,r)=>{let{name:o,selectorAttribute:i,selectorTypes:s,error:n,onUpdate:l,onRecordingStarted:g,onRecordingCancelled:h,onErrorReset:a}=t,x=Ur(),c=p=>{n&&a(),p.key==="Enter"&&(g(),p.stopPropagation(),p.preventDefault())};e.focusInput=()=>{x.value?.focus()};let d=new Map([[B.Schema.SelectorType.ARIA,L(A.selectorTypeARIA)],[B.Schema.SelectorType.CSS,L(A.selectorTypeCSS)],[B.Schema.SelectorType.Text,L(A.selectorTypeText)],[B.Schema.SelectorType.XPath,L(A.selectorTypeXPath)],[B.Schema.SelectorType.Pierce,L(A.selectorTypePierce)]]);et.render(Je`
      <style>${Lt}</style>
      <style>${De.textInputStyles}</style>
      <style>${De.checkboxStyles}</style>
      <div class="wrapper" jslog=${W.section("create-recording-view")}>
        <div class="header-wrapper">
          <h1>${L(A.createRecording)}</h1>
          <devtools-button
            title=${L(A.cancelRecording)}
            jslog=${W.close().track({click:!0})}
            .data=${{variant:"icon",size:"SMALL",iconName:"cross"}}
            @click=${h}
          ></devtools-button>
        </div>
        <label class="row-label" for="user-flow-name">${L(A.recordingName)}</label>
        <input
          value=${o}
          @focus=${()=>x.value?.select()}
          @keydown=${c}
          jslog=${W.textField("user-flow-name").track({change:!0})}
          class="devtools-text-input"
          id="user-flow-name"
          ${Ar(x)}
          @input=${p=>l({name:p.target.value.trim()})}
        />
        <label class="row-label" for="selector-attribute">
          <span>${L(A.selectorAttribute)}</span>
          <devtools-link
            class="link" href="https://g.co/devtools/recorder#selector"
            title=${L(A.learnMore)}
            .jslogContext=${"recorder-selector-help"}>
            <devtools-icon name="help">
            </devtools-icon>
          </devtools-link>
        </label>
        <input
          value=${i}
          placeholder="data-testid"
          @keydown=${c}
          jslog=${W.textField("selector-attribute").track({change:!0})}
          class="devtools-text-input"
          id="selector-attribute"
          @input=${p=>l({selectorAttribute:p.target.value.trim()})}
        />
        <label class="row-label">
          <span>${L(A.selectorTypes)}</span>
          <devtools-link
            class="link" href="https://g.co/devtools/recorder#selector"
            title=${L(A.learnMore)}
            .jslogContext=${"recorder-selector-help"}>
            <devtools-icon name="help">
            </devtools-icon>
          </devtools-link>
        </label>
        <div class="checkbox-container">
          ${Lr(s,p=>Je`
              <label class="checkbox-label selector-type">
                <input
                  @keydown=${c}
                  .value=${p.selectorType}
                  jslog=${W.toggle().track({click:!0}).context(`selector-${p.selectorType}`)}
                  ?checked=${p.checked}
                  type="checkbox"
                  @change=${N=>l({selectorType:p.selectorType,checked:N.target.checked})}
                />
                ${d.get(p.selectorType)||p.selectorType}
              </label>
            `)}
        </div>
        ${n&&Je` <div class="error" role="alert"> ${n.message} </div>`}
      </div>
      <div class="footer">
        <div class="controls">
          <devtools-widget
            class="control-button"
            ${Dr(se,{label:L(A.startRecording),shape:"circle",onClick:g})}
            jslog=${W.action("chrome-recorder.start-recording").track({click:!0})}
            title=${B.Tooltip.getTooltipForActions(L(A.startRecording),"chrome-recorder.start-recording")}
          ></devtools-widget>
        </div>
      </div>
    `,r)},ce=class extends Qe.Widget.Widget{#t;#e="";#o="";#i=[];#r;#s={};#n;onRecordingStarted=()=>{};onRecordingCancelled=()=>{};set recorderSettings(e){this.#n=e,this.#e=this.#n.defaultTitle,this.#o=this.#n.selectorAttribute,this.#i=Object.values(B.Schema.SelectorType).map(r=>({selectorType:r,checked:this.#n?.getSelectorByType(r)??!0})),this.requestUpdate()}constructor(e,r){super(e,{useShadowDom:!0}),this.#r=r||Nt}wasShown(){super.wasShown(),this.requestUpdate(),this.updateComplete.then(()=>this.#s.focusInput?.())}startRecording(){if(!this.#n)throw new Error("settings not set");if(!this.#e.trim()){this.#t=new Error(L(A.recordingNameIsRequired)),this.requestUpdate();return}let e=this.#i.filter(o=>o.checked).map(o=>o.selectorType);if(!e.includes(B.Schema.SelectorType.CSS)&&!e.includes(B.Schema.SelectorType.XPath)&&!e.includes(B.Schema.SelectorType.Pierce)){this.#t=new Error(L(A.includeNecessarySelectors)),this.requestUpdate();return}for(let o of Object.values(B.Schema.SelectorType))this.#n.setSelectorByType(o,e.includes(o));let r=this.#o.trim();r&&(this.#n.selectorAttribute=r),this.onRecordingStarted({name:this.#e,selectorTypesToRecord:e,selectorAttribute:this.#o?this.#o:void 0}),Ne.UserBadges.instance().recordAction(Ne.BadgeAction.RECORDER_RECORDING_STARTED)}performUpdate(){this.#r({name:this.#e,selectorAttribute:this.#o,selectorTypes:this.#i,error:this.#t,onRecordingCancelled:this.onRecordingCancelled,onUpdate:e=>{"name"in e?this.#e=e.name:"selectorAttribute"in e?this.#o=e.selectorAttribute:this.#i=this.#i.map(r=>r.selectorType===e.selectorType?{...r,checked:e.checked}:r),this.requestUpdate()},onRecordingStarted:()=>{this.startRecording()},onErrorReset:()=>{this.#t=void 0,this.requestUpdate()}},this.#s,this.contentElement)}};var tt={};_(tt,{RecordingStateChangedEvent:()=>ge,ReplayFinishedEvent:()=>pe,SetRecordingFinishedEvent:()=>Re});var pe=class t extends Event{static eventName="replayfinished";constructor(){super(t.eventName,{bubbles:!0,composed:!0})}},Re=class t extends Event{static eventName="setrecordingfinished";constructor(){super(t.eventName,{bubbles:!0,composed:!0})}},ge=class t extends Event{recording;static eventName="recordingstatechanged";constructor(e){super(t.eventName,{bubbles:!0,composed:!0}),this.recording=e}};var Tr={};_(Tr,{ActionDelegate:()=>Et,DEFAULT_VIEW:()=>Er,RecorderPanel:()=>Le});import"./../../ui/kit/kit.js";import*as ie from"./../../core/common/common.js";import*as k from"./../../core/host/host.js";import*as Tt from"./../../core/i18n/i18n.js";import*as wr from"./../../core/platform/platform.js";import*as Ct from"./../../core/root/root.js";import*as F from"./../../core/sdk/sdk.js";import*as Sr from"./../../models/bindings/bindings.js";import*as xr from"./../../models/emulation/emulation.js";import*as Xe from"./../../models/extensions/extensions.js";import*as Rr from"./../../services/tracing/tracing.js";import"./../../ui/components/buttons/buttons.js";import*as kr from"./../../ui/components/dialogs/dialogs.js";import*as $ from"./../../ui/legacy/legacy.js";import{Directives as bo,html as Z,render as yo}from"./../../ui/lit/lit.js";import*as H from"./../../ui/visual_logging/visual_logging.js";import*as q from"./converters/converters.js";import*as $r from"./extensions/extensions.js";import*as S from"./models/models.js";var Vt=`*{margin:0;padding:0;box-sizing:border-box;font-size:inherit}*:focus,
*:focus-visible{outline:none}:host{overflow-x:auto}:host,
devtools-create-recording-view{display:flex;flex-direction:column;flex:1;min-height:0}.wrapper{display:flex;flex-direction:column;height:100%}.header{background-color:var(--sys-color-cdt-base-container);display:flex;flex-flow:row wrap;align-items:center;border-bottom:1px solid var(--sys-color-divider);padding:0 5px;gap:3px;flex-shrink:0}.separator{background-color:var(--sys-color-divider);width:1px;height:17px;margin:0}select{appearance:none;user-select:none;border:none;border-radius:var(--sys-shape-corner-extra-small);height:var(--sys-size-9);max-width:140px;min-width:140px;padding:0 var(--sys-size-6) 0 var(--sys-size-5);position:relative;color:var(--sys-color-on-surface);background-color:transparent;text-overflow:ellipsis;background-image:var(--combobox-dropdown-arrow);background-position:right center;background-repeat:no-repeat;&:hover{background-color:var(--sys-color-state-hover-on-subtle)}&:active{background-color:var(--sys-color-state-ripple-neutral-on-subtle)}&:hover:active{background:var(--combobox-dropdown-arrow),linear-gradient(var(--sys-color-state-hover-on-subtle),var(--sys-color-state-hover-on-subtle)),linear-gradient(var(--sys-color-state-ripple-neutral-on-subtle),var(--sys-color-state-ripple-neutral-on-subtle));background-position:right center;background-repeat:no-repeat}&:disabled{pointer-events:none;color:var(--sys-color-state-disabled);background-color:var(--sys-color-state-disabled-container)}&:focus-visible{outline:var(--sys-size-2) solid var(--sys-color-state-focus-ring)}}select option{background-color:var(--sys-color-cdt-base-container);color:var(--sys-color-on-surface)}devtools-menu{width:0;height:0;position:absolute}devtools-recording-list-view{overflow:auto}.error{color:var(--sys-color-error);border:1px solid var(--sys-color-error);background-color:var(--sys-color-error-container);padding:4px}.feedback{margin-left:auto;margin-right:4px}.feedback .devtools-link{letter-spacing:0.03em;text-decoration-line:underline;font-size:var(--sys-typescale-body4-size);line-height:16px;color:var(--sys-color-primary);outline-offset:3px}.feedback .devtools-link:focus-visible,
.empty-state-description .devtools-link:focus-visible{outline:-webkit-focus-ring-color auto 1px}.empty-state{margin:var(--sys-size-5);display:flex;flex-grow:1;justify-content:center;align-items:center;flex-direction:column;text-align:center;min-height:fit-content;min-width:fit-content;> *{max-width:var(--sys-size-29)}.empty-state-header{font:var(--sys-typescale-headline5);margin-bottom:var(--sys-size-3)}.empty-state-description{font:var(--sys-typescale-body4-regular);color:var(--sys-color-on-surface-subtle);> devtools-link{white-space:nowrap;margin-left:var(--sys-size-3);cursor:pointer;text-decoration:underline;color:var(--sys-color-primary);outline-offset:var(--sys-size-2)}}> devtools-button{margin-top:var(--sys-size-7)}}
/*# sourceURL=${import.meta.resolve("./recorderPanel.css")} */`;var zt={};_(zt,{DEFAULT_VIEW:()=>jt,RecordingListView:()=>ke});import"./../../ui/kit/kit.js";import*as ot from"./../../core/i18n/i18n.js";import"./../../ui/components/buttons/buttons.js";import*as Ot from"./../../ui/legacy/legacy.js";import*as it from"./../../ui/lit/lit.js";import*as Ft from"./../../ui/visual_logging/visual_logging.js";import*as qt from"./models/models.js";var Bt=`@scope to (devtools-widget > *){*{margin:0;padding:0;box-sizing:border-box;font-size:inherit}*:focus,
  *:focus-visible{outline:none}.wrapper{padding:24px}.header{display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:10px}h1{font-size:16px;line-height:19px;color:var(--sys-color-on-surface);font-weight:normal}.icon,
  .icon devtools-icon{width:20px;height:20px;color:var(--sys-color-primary)}.table{margin-top:35px}.title{font-size:13px;color:var(--sys-color-on-surface);margin-left:10px;flex:1;overflow-x:hidden;white-space:nowrap;text-overflow:ellipsis}.row{display:flex;align-items:center;padding-right:5px;height:28px;border-bottom:1px solid var(--sys-color-divider)}.row:focus-within,
  .row:hover{background-color:var(--sys-color-state-hover-on-subtle)}.row:last-child{border-bottom:none}.actions{display:flex;align-items:center}.actions button{border:none;background-color:transparent;width:24px;height:24px;border-radius:50%}.actions .divider{width:1px;height:17px;background-color:var(--sys-color-divider);margin:0 6px}}
/*# sourceURL=${import.meta.resolve("./recordingListView.css")} */`;var{html:rt}=it,ne={savedRecordings:"Saved recordings",createRecording:"Create a new recording",playRecording:"Play recording",deleteRecording:"Delete recording",openRecording:"Open recording"},Vr=ot.i18n.registerUIStrings("panels/recorder/RecordingListView.ts",ne),ue=ot.i18n.getLocalizedString.bind(void 0,Vr),jt=(t,e,r)=>{let{recordings:o,replayAllowed:i,onCreateClick:s,onDeleteClick:n,onOpenClick:l,onPlayRecordingClick:g,onKeyDown:h}=t;it.render(rt`
      <style>${Bt}</style>
      <div class="wrapper">
        <div class="header">
          <h1>${ue(ne.savedRecordings)}</h1>
          <devtools-button
            .variant=${"primary"}
            @click=${s}
            title=${qt.Tooltip.getTooltipForActions(ue(ne.createRecording),"chrome-recorder.create-recording")}
            .jslogContext=${"create-recording"}
          >
            ${ue(ne.createRecording)}
          </devtools-button>
        </div>
        <div class="table">
          ${o.map(a=>rt`
                <div
                  role="button"
                  tabindex="0"
                  aria-label=${ue(ne.openRecording)}
                  class="row"
                  @keydown=${x=>h(a.storageName,x)}
                  @click=${x=>l(a.storageName,x)}
                  jslog=${Ft.item().track({click:!0,resize:!0}).context("recording")}>
                  <div class="icon">
                    <devtools-icon name="flow">
                    </devtools-icon>
                  </div>
                  <div class="title">${a.name}</div>
                  <div class="actions">
                    ${i?rt`
                              <devtools-button
                                title=${ue(ne.playRecording)}
                                .data=${{variant:"icon",iconName:"play",jslogContext:"play-recording"}}
                                @click=${x=>g(a.storageName,x)}
                                @keydown=${x=>x.stopPropagation()}
                              ></devtools-button>
                              <div class="divider"></div>`:""}
                    <devtools-button
                      class="delete-recording-button"
                      title=${ue(ne.deleteRecording)}
                      .data=${{variant:"icon",iconName:"bin",jslogContext:"delete-recording"}}
                      @click=${x=>n(a.storageName,x)}
                      @keydown=${x=>x.stopPropagation()}
                    ></devtools-button>
                  </div>
                </div>
              `)}
        </div>
      </div>
    `,r)},ke=class extends Ot.Widget.Widget{#t=[];#e=!0;#o;onCreateRecording;onDeleteRecording;onOpenRecording;onPlayRecording;constructor(e,r){super(e,{useShadowDom:!0}),this.#o=r||jt}set recordings(e){this.#t=e,this.performUpdate()}set replayAllowed(e){this.#e=e,this.performUpdate()}#i(){this.onCreateRecording?.()}#r(e,r){r.stopPropagation(),this.onDeleteRecording?.(e)}#s(e,r){r.stopPropagation(),this.onOpenRecording?.(e)}#n(e,r){r.stopPropagation(),this.onPlayRecording?.(e)}#l(e,r){r.key==="Enter"&&this.#s(e,r)}performUpdate(){this.#o({recordings:this.#t,replayAllowed:this.#e,onCreateClick:this.#i.bind(this),onDeleteClick:this.#r.bind(this),onOpenClick:this.#s.bind(this),onPlayRecordingClick:this.#n.bind(this),onKeyDown:this.#l.bind(this)},{},this.contentElement)}wasShown(){super.wasShown(),this.performUpdate()}};var yr={};_(yr,{DEFAULT_VIEW:()=>br,RecordingView:()=>xe});import"./../../ui/kit/kit.js";import*as We from"./../../core/host/host.js";import*as ye from"./../../core/i18n/i18n.js";import*as xt from"./../../core/platform/platform.js";import*as X from"./../../core/sdk/sdk.js";import*as we from"./../../third_party/codemirror.next/codemirror.next.js";import"./../../ui/components/buttons/buttons.js";import*as fr from"./../../ui/components/code_highlighter/code_highlighter.js";import"./../../ui/components/dialogs/dialogs.js";import*as vr from"./../../ui/components/input/input.js";import*as Ge from"./../../ui/components/text_editor/text_editor.js";import*as oe from"./../../ui/legacy/legacy.js";import*as M from"./../../ui/lit/lit.js";import*as R from"./../../ui/visual_logging/visual_logging.js";import*as nt from"./../../core/i18n/i18n.js";import"./../../ui/components/buttons/buttons.js";import*as _t from"./../../ui/legacy/legacy.js";import*as at from"./../../ui/lit/lit.js";import*as Be from"./../../ui/visual_logging/visual_logging.js";import*as Ve from"./extensions/extensions.js";var Kt=`*{margin:0;padding:0;outline:none;box-sizing:border-box;font-size:inherit}.extension-view{display:flex;flex-direction:column;height:100%}main{flex:1}iframe{border:none;height:100%;width:100%}header{display:flex;padding:3px 8px;justify-content:space-between;border-bottom:1px solid var(--sys-color-divider)}header > div{align-self:center}.icon{display:block;width:16px;height:16px;color:var(--sys-color-secondary)}.title{display:flex;flex-direction:row;gap:6px;color:var(--sys-color-secondary);align-items:center;font-weight:500}
/*# sourceURL=${import.meta.resolve("./extensionView.css")} */`;var{html:Br}=at,st={closeView:"Close",extension:"Content provided by a browser extension"},Or=nt.i18n.registerUIStrings("panels/recorder/ExtensionView.ts",st),Ht=nt.i18n.getLocalizedString.bind(void 0,Or),Fr=(t,e,r)=>{let{descriptor:o,iframe:i}=t;at.render(Br`
      <style>${Kt}</style>
      <div class="extension-view">
        <header>
          <div class="title">
            <devtools-icon
              class="icon"
              title=${Ht(st.extension)}
              name="extension">
            </devtools-icon>
            ${o.title}
          </div>
          <devtools-button
            title=${Ht(st.closeView)}
            jslog=${Be.close().track({click:!0})}
            .data=${{variant:"icon",size:"SMALL",iconName:"cross"}}
            @click=${e.closeView}
          ></devtools-button>
        </header>
        <main>
          ${i}
        </main>
    </div>
  `,r,{container:{attributes:{jslog:Be.section("extension-view")}}})},$e=class extends _t.Widget.VBox{#t;#e;#o;#i={closeView:()=>{this.#o?.()}};set onClose(e){this.#o=e}constructor(e,r=Fr){super(e,{useShadowDom:!0}),this.#e=r}get descriptor(){return this.#t}set descriptor(e){this.#t=e,e&&Ve.ExtensionManager.ExtensionManager.instance().getView(e.id).show(),this.requestUpdate()}willHide(){super.willHide(),this.#t&&Ve.ExtensionManager.ExtensionManager.instance().getView(this.#t.id).hide()}performUpdate(){if(!this.#t)return;let e=Ve.ExtensionManager.ExtensionManager.instance().getView(this.#t.id).frame();this.#e({descriptor:this.#t,iframe:e},this.#i,this.contentElement)}};import*as Y from"./models/models.js";var Wt=`@scope to (devtools-widget > *){*{padding:0;margin:0;box-sizing:border-box;font-size:inherit}.wrapper{display:flex;flex-direction:row;flex:1;height:100%}.main{overflow:hidden;display:flex;flex-direction:column;flex:1}.sections{min-height:0;background-color:var(--sys-color-cdt-base-container);z-index:0;position:relative;container:sections/inline-size}.section{display:flex;padding:0 16px;gap:8px;position:relative}.section::after{content:'';border-bottom:1px solid var(--sys-color-divider);position:absolute;left:0;right:0;bottom:0;z-index:-1}.section:last-child::after{content:none}.screenshot-wrapper{flex:0 0 80px;padding-top:32px;z-index:2}@container sections (max-width: 400px){.screenshot-wrapper{display:none}}.screenshot{object-fit:cover;object-position:top center;max-width:100%;width:200px;height:auto;border:1px solid var(--sys-color-divider);border-radius:1px}.content{flex:1;min-width:0}.steps{flex:1;position:relative;align-self:flex-start;overflow:visible}.step{position:relative;padding-left:40px;margin:16px 0}.step .action{font-size:13px;line-height:16px;letter-spacing:0.03em}.recording{color:var(--sys-color-primary);font-style:italic;margin-top:8px;margin-bottom:0}.add-assertion-button{margin-top:8px}.details{max-width:240px;display:flex;flex-direction:column;align-items:flex-end}.url{font-size:12px;line-height:16px;letter-spacing:0.03em;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;color:var(--sys-color-secondary);max-width:100%;margin-bottom:16px}.header{flex-shrink:0;align-items:center;border-bottom:1px solid var(--sys-color-divider);display:flex;flex-wrap:wrap;gap:10px;justify-content:space-between;padding:16px}.header-title-wrapper{max-width:100%}.header-title{align-items:center;display:flex;flex:1;max-width:100%}.header-title::before{content:'';min-width:12px;height:12px;display:inline-block;background:var(--sys-color-primary);border-radius:50%;margin-right:7px}#title-input{font-family:inherit;field-sizing:content;font-size:18px;line-height:22px;letter-spacing:0.02em;padding:1px 4px;border:1px solid transparent;border-radius:1px;word-break:break-all}#title-input:hover,
  #title-input:focus-visible{border-color:var(--input-outline)}#title-input.has-error{border-color:var(--sys-color-error)}#title-input.disabled{color:var(--sys-color-state-disabled)}.title-input-error-text{margin-top:4px;margin-left:19px;color:var(--sys-color-error)}.title-button-bar{flex-shrink:0;padding-left:2px;display:flex}#title-input:focus + .title-button-bar{display:none}.settings-row{padding:16px 28px;border-bottom:1px solid var(--sys-color-divider);display:flex;flex-flow:row wrap;justify-content:space-between}.settings-title{font-size:14px;line-height:24px;letter-spacing:0.03em;color:var(--sys-color-on-surface);display:flex;align-items:center;align-content:center;gap:5px;width:fit-content}.settings-title:focus-visible{outline:2px solid var(--sys-color-state-focus-ring);outline-offset:2px}.settings{margin-top:4px;display:flex;flex-wrap:wrap;font-size:12px;line-height:20px;letter-spacing:0.03em;color:var(--sys-color-on-surface-subtle)}.settings.expanded{gap:10px}.settings .separator{width:1px;height:20px;background-color:var(--sys-color-divider);margin:0 5px}.actions{display:flex;align-items:center;flex-wrap:wrap;gap:12px}.actions .separator{width:1px;height:24px;background-color:var(--sys-color-divider)}.is-recording .header-title::before{background:var(--sys-color-error-bright)}.footer{display:flex;justify-content:center;border-top:1px solid var(--sys-color-divider);padding:12px;background:var(--sys-color-cdt-base-container);z-index:1}.controls{align-items:center;display:flex;justify-content:center;position:relative;width:100%}.chevron{width:14px;height:14px;transform:rotate(-90deg);color:var(--sys-color-on-surface)}.expanded .chevron{transform:rotate(0)}.editable-setting{display:flex;flex-direction:row;gap:12px;align-items:center}.editable-setting .devtools-text-input{width:fit-content;height:var(--sys-size-9)}.wrapping-label{display:inline-flex;align-items:center;gap:12px}.text-editor{height:100%;overflow:auto}.section-toolbar{display:flex;align-items:center;padding:3px 5px;justify-content:space-between;gap:3px}.section-toolbar > devtools-select-menu{height:24px;min-width:50px}.sections .section-toolbar{justify-content:flex-end}devtools-split-view{flex:1 1 0%;min-height:0}[slot='main']{overflow:hidden auto}[slot='sidebar']{display:flex;flex-direction:column;overflow:auto;height:100%;width:100%}[slot='sidebar'] .section-toolbar{border-bottom:1px solid var(--sys-color-divider)}.recorder-extension-view{flex:1}}
/*# sourceURL=${import.meta.resolve("./recordingView.css")} */`;var Qt={};_(Qt,{DEFAULT_VIEW:()=>Zt,ReplaySection:()=>Ce});import*as lt from"./../../core/i18n/i18n.js";import*as Yt from"./../../core/platform/platform.js";import"./../../ui/components/buttons/buttons.js";import*as qe from"./../../ui/legacy/legacy.js";import*as Ee from"./../../ui/lit/lit.js";import*as he from"./../../ui/visual_logging/visual_logging.js";import*as Jt from"./models/models.js";var Gt=`.select-button{display:flex;gap:var(--sys-size-6)}.groups-label{display:inline-block;padding:0 var(--sys-size-4) var(--sys-size-4) 0}.select-button devtools-button{position:relative}
/*# sourceURL=${import.meta.resolve("./replaySection.css")} */`;var{html:Oe,Directives:{ifDefined:qr,repeat:Xt}}=Ee,j={Replay:"Replay",ReplayNormalButtonLabel:"Normal speed",ReplayNormalItemLabel:"Normal (Default)",ReplaySlowButtonLabel:"Slow speed",ReplaySlowItemLabel:"Slow",ReplayVerySlowButtonLabel:"Very slow speed",ReplayVerySlowItemLabel:"Very slow",ReplayExtremelySlowButtonLabel:"Extremely slow speed",ReplayExtremelySlowItemLabel:"Extremely slow",speedGroup:"Speed",extensionGroup:"Extensions"},jr=lt.i18n.registerUIStrings("panels/recorder/ReplaySection.ts",j),G=lt.i18n.getLocalizedString.bind(void 0,jr),Fe="extension";function zr(t){return t==="normal"||t==="slow"||t==="very_slow"||t==="extremely_slow"}var Zt=(t,e,r)=>{let{disabled:o,groups:i,selectedItem:s,actionTitle:n,onButtonClick:l,onItemSelected:g}=t,h="primary",a=c=>{c.stopPropagation(),l()},x=c=>{c.target instanceof HTMLSelectElement&&g(c.target.value)};Ee.render(Oe`
      <style>
        ${qe.inspectorCommonStyles}
      </style>
      <style>
        ${Gt}
      </style>
      <div
        class="select-button"
        title=${qr(n)}
      >
        <label>
          ${i.length>1?Oe`
                <div
                  class="groups-label"
                  >${i.map(c=>c.name).join(" & ")}</div>`:Ee.nothing}
          <select
            class="primary"
            ?disabled=${o}
            jslog=${he.dropDown("network-conditions").track({change:!0})}
            @change=${x}
          >
            ${Xt(i,c=>c.name,c=>Oe`
                <optgroup label=${c.name}>
                  ${Xt(c.items,d=>d.value,d=>{let p=d.value===s.value;return Oe`
                      <option
                        .title=${d.label()}
                        value=${d.value}
                        ?selected=${p}
                        jslog=${he.item(Yt.StringUtilities.toKebabCase(d.value)).track({click:!0})}
                      >
                        ${p&&d.buttonLabel?d.buttonLabel():d.label()}
                      </option>
                    `})}
                </optgroup>
              `)}
          </select>
        </label>
        <devtools-button
          .disabled=${o}
          .variant=${h}
          .iconName=${s.buttonIconName}
          @click=${a}
          jslog=${he.action("chrome-recorder.replay-recording").track({click:!0})}
        >
          ${G(j.Replay)}
        </devtools-button>
      </div>`,r)},Ce=class extends qe.Widget.Widget{onStartReplay;#t=!1;#e;#o=[];#i;#r=[];constructor(e,r){super(e,{useShadowDom:!0}),this.#i=r||Zt,this.#r=this.#s()}set settings(e){this.#e=e,this.performUpdate()}set replayExtensions(e){this.#o=e,this.#r=this.#s(),this.performUpdate()}get disabled(){return this.#t}set disabled(e){this.#t=e,this.performUpdate()}wasShown(){super.wasShown(),this.performUpdate()}performUpdate(){let e=this.#n();this.#i({disabled:this.#t,groups:this.#r,selectedItem:e,actionTitle:Jt.Tooltip.getTooltipForActions(e.label(),"chrome-recorder.replay-recording"),onButtonClick:()=>this.#l(),onItemSelected:r=>this.#c(r)},void 0,this.contentElement)}#s(){let e=[{name:G(j.speedGroup),items:[{value:"normal",buttonIconName:"play",buttonLabel:()=>G(j.ReplayNormalButtonLabel),label:()=>G(j.ReplayNormalItemLabel)},{value:"slow",buttonIconName:"play",buttonLabel:()=>G(j.ReplaySlowButtonLabel),label:()=>G(j.ReplaySlowItemLabel)},{value:"very_slow",buttonIconName:"play",buttonLabel:()=>G(j.ReplayVerySlowButtonLabel),label:()=>G(j.ReplayVerySlowItemLabel)},{value:"extremely_slow",buttonIconName:"play",buttonLabel:()=>G(j.ReplayExtremelySlowButtonLabel),label:()=>G(j.ReplayExtremelySlowItemLabel)}]}];return this.#o.length&&e.push({name:G(j.extensionGroup),items:this.#o.map(r=>({value:Fe+r.getOrigin(),buttonIconName:"play",buttonLabel:()=>r.getName(),label:()=>r.getName()}))}),e}#n(){let e=this.#e?.replayExtension||this.#e?.speed||"";for(let r of this.#r)for(let o of r.items)if(o.value===e)return o;return this.#r[0].items[0]}#l(){let e=this.#e?.replayExtension||this.#e?.speed||"";if(e.startsWith(Fe)){let r=e.substring(Fe.length),o=this.#o.find(i=>i.getOrigin()===r);if(o){this.#e&&(this.#e.replayExtension=Fe+o.getOrigin()),this.onStartReplay&&this.onStartReplay("normal",o),this.performUpdate();return}}this.onStartReplay&&this.onStartReplay(this.#e?this.#e.speed:"normal"),this.performUpdate()}#c(e){this.#e&&(zr(e)?(this.#e.speed=e,this.#e.replayExtension=""):this.#e.replayExtension=e,this.performUpdate())}};var mr={};_(mr,{DEFAULT_VIEW:()=>hr,StepView:()=>be});import"./../../ui/kit/kit.js";import*as wt from"./../../core/i18n/i18n.js";import*as yt from"./../../core/platform/platform.js";import*as _e from"./../../ui/components/menus/menus.js";import*as Ae from"./../../ui/legacy/legacy.js";import*as Ue from"./../../ui/lit/lit.js";import*as re from"./../../ui/visual_logging/visual_logging.js";import*as D from"./models/models.js";var lr={};_(lr,{EditorState:()=>ae,StepEditor:()=>ve});import*as mt from"./../../core/i18n/i18n.js";import*as ht from"./../../core/platform/platform.js";import"./../../ui/components/buttons/buttons.js";import*as Ke from"./../../ui/components/suggestion_input/suggestion_input.js";import*as ft from"./../../ui/legacy/legacy.js";import*as Wr from"./../../ui/lit/lit.js";import*as T from"./../../ui/visual_logging/visual_logging.js";import*as C from"./models/models.js";var sr={};_(sr,{DEFAULT_VIEW:()=>ir,SelectorPicker:()=>Te});import*as ct from"./../../core/common/common.js";import*as pt from"./../../core/i18n/i18n.js";import*as je from"./../../core/platform/platform.js";import*as z from"./../../core/sdk/sdk.js";import"./../../ui/components/buttons/buttons.js";import*as tr from"./../../ui/legacy/legacy.js";import*as gt from"./../../ui/lit/lit.js";import*as rr from"./../../ui/visual_logging/visual_logging.js";import*as me from"./models/models.js";var er=`:host{display:inline-block}.selector-picker{width:18px;height:18px}
/*# sourceURL=${import.meta.resolve("./selectorPicker.css")} */`;import*as J from"./util/util.js";var{html:Kr}=gt,dt="captureSelectors",or={selectorPicker:"Select an element in the page to update selectors"},Hr=pt.i18n.registerUIStrings("panels/recorder/SelectorPicker.ts",or),_r=pt.i18n.getLocalizedString.bind(void 0,Hr),ir=(t,e,r)=>{let{active:o,disabled:i,onClick:s}=t;gt.render(Kr`
      <style>${er}</style>
      <devtools-button
        @click=${s}
        .title=${_r(or.selectorPicker)}
        class="selector-picker"
        .size=${"SMALL"}
        .iconName=${"select-element"}
        .active=${o}
        .disabled=${i}
        .variant=${"icon"}
        jslog=${rr.toggle("selector-picker").track({click:!0})}
      ></devtools-button>
    `,r)},Te=class t extends tr.Widget.Widget{#t;#e=!1;#o=!1;#i;#r=new ct.Mutex.Mutex;#s=new Map;#n=new Map;onSelectorPicked;onAttributeRequested;constructor(e,r){super(e,{useShadowDom:!0}),this.#t=r||ir}static get#l(){return z.TargetManager.TargetManager.instance()}set disabled(e){this.#e=e,this.requestUpdate()}performUpdate(){this.#t({active:this.#o,disabled:this.#e,onClick:this.#c.bind(this)},{},this.contentElement)}#c(e){e.preventDefault(),e.stopPropagation(),this.#u()}async#u(){return this.#o?await this.#a():await this.#m()}#m=()=>this.#r.run(async()=>{this.#o||(this.#o=!0,this.#i=await new Promise((e,r)=>{let o=setTimeout(r,1e3);this.onAttributeRequested?this.onAttributeRequested(i=>{clearTimeout(o),e(i)}):(clearTimeout(o),e(void 0))}),t.#l.observeTargets(this),this.requestUpdate())});#a=()=>this.#r.run(async()=>{this.#o&&(this.#o=!1,t.#l.unobserveTargets(this),t.#l.targets().map(this.targetRemoved.bind(this)),this.#i=void 0,this.requestUpdate())});targetAdded(e){if(e.type()!==z.Target.Type.FRAME)return;let r=this.#s.get(e);r||(r=new ct.Mutex.Mutex,this.#s.set(e,r)),r.run(async()=>{await this.#x(e),await this.#y(e)})}targetRemoved(e){let r=this.#s.get(e);r&&r.run(async()=>{try{await this.#S(e),await this.#R(e)}catch{}})}#f=e=>{if(e.data.name!==dt)return;let r=e.data.executionContextId,o=z.TargetManager.TargetManager.instance().targets(),i=me.SDKUtils.findTargetByExecutionContext(o,r),s=me.SDKUtils.findFrameIdByExecutionContext(o,r);if(!i||!s)throw new Error(`No execution context found for the binding call + ${JSON.stringify(e.data)}`);let n=i.model(z.ResourceTreeModel.ResourceTreeModel);if(!n)throw new Error(`ResourceTreeModel instance is missing for the target: ${i.id()}`);let l=n.frameForId(s);if(!l)throw new Error("Frame is not found");this.onSelectorPicked&&this.onSelectorPicked({...JSON.parse(e.data.payload),...me.SDKUtils.getTargetFrameContext(i,l)}),this.#a()};async#y(e){let o=`${await J.InjectedScript.get()};DevToolsRecorder.startSelectorPicker({getAccessibleName, getAccessibleRole}, ${JSON.stringify(this.#i?this.#i:void 0)}, ${J.isDebugBuild})`,[{identifier:i}]=await Promise.all([e.pageAgent().invoke_addScriptToEvaluateOnNewDocument({source:o,worldName:J.DEVTOOLS_RECORDER_WORLD_NAME,includeCommandLineAPI:!0}),me.SDKUtils.evaluateInAllFrames(J.DEVTOOLS_RECORDER_WORLD_NAME,e,o)]);this.#n.set(e,i)}async#S(e){let r=this.#n.get(e);je.assertNotNullOrUndefined(r),this.#n.delete(e),await e.pageAgent().invoke_removeScriptToEvaluateOnNewDocument({identifier:r}),await me.SDKUtils.evaluateInAllFrames(J.DEVTOOLS_RECORDER_WORLD_NAME,e,"DevToolsRecorder.stopSelectorPicker()")}async#x(e){let r=e.model(z.RuntimeModel.RuntimeModel);je.assertNotNullOrUndefined(r),r.addEventListener(z.RuntimeModel.Events.BindingCalled,this.#f),await r.addBinding({name:dt,executionContextName:J.DEVTOOLS_RECORDER_WORLD_NAME})}async#R(e){await e.runtimeAgent().invoke_removeBinding({name:dt});let r=e.model(z.RuntimeModel.RuntimeModel);je.assertNotNullOrUndefined(r),r.removeEventListener(z.RuntimeModel.Events.BindingCalled,this.#f)}wasShown(){super.wasShown(),this.requestUpdate()}wasHidden(){super.wasHidden(),this.#a()}};var nr=`*{box-sizing:border-box;padding:0;margin:0;font-size:inherit}:host{display:block}.row{display:flex;flex-direction:row;color:var(--sys-color-token-property-special);font-family:var(--monospace-font-family);font-size:var(--monospace-font-size);align-items:center;line-height:18px;margin-top:3px}.row devtools-button{line-height:1;margin-left:0.5em}.separator{margin-right:0.5em;color:var(--sys-color-on-surface)}.padded{margin-left:2em}.padded.double{margin-left:4em}.inline-button{width:18px;height:18px;opacity:0%;visibility:hidden;transition:opacity 200ms;flex-shrink:0}.row:focus-within .inline-button,
.row:hover .inline-button{opacity:100%;visibility:visible}.wrapped.row{flex-wrap:wrap}.gap.row{gap:5px}.gap.row devtools-button{margin-left:0}.regular-font{font-family:inherit;font-size:inherit}.no-margin{margin:0}.row-buttons{margin-top:3px}.error{margin:3px 0 6px;padding:8px 12px;background:var(--sys-color-error-container);color:var(--sys-color-error)}
/*# sourceURL=${import.meta.resolve("./stepEditor.css")} */`;import{ArrayAssignments as I,assert as ut,deepFreeze as He,immutableDeepAssign as fe,InsertAssignment as ze,SharedObject as Gr}from"./util/util.js";var{html:U,render:Xr,Directives:Yr}=Wr,{live:Q}=Yr,{widget:Jr}=ft.Widget,Zr=Object.freeze({string:t=>t.trim(),number:t=>{let e=parseFloat(t);return Number.isNaN(e)?0:e},boolean:t=>t.toLowerCase()==="true"}),ar=Object.freeze({selectors:"string",offsetX:"number",offsetY:"number",target:"string",frame:"number",assertedEvents:"string",value:"string",key:"string",operator:"string",count:"number",expression:"string",x:"number",y:"number",url:"string",type:"string",timeout:"number",duration:"number",button:"string",deviceType:"string",width:"number",height:"number",deviceScaleFactor:"number",isMobile:"boolean",hasTouch:"boolean",isLandscape:"boolean",download:"number",upload:"number",latency:"number",name:"string",parameters:"string",visible:"boolean",properties:"string",attributes:"string"}),P=He({selectors:[[".cls"]],offsetX:1,offsetY:1,target:"main",frame:[0],assertedEvents:[{type:"navigation",url:"https://example.com",title:"Title"}],value:"Value",key:"Enter",operator:">=",count:1,expression:"true",x:0,y:0,url:"https://example.com",timeout:5e3,duration:50,deviceType:"mouse",button:"primary",type:"click",width:800,height:600,deviceScaleFactor:1,isMobile:!1,hasTouch:!1,isLandscape:!0,download:1e3,upload:1e3,latency:25,name:"customParam",parameters:"{}",properties:"{}",attributes:[{name:"attribute",value:"value"}],visible:!0}),vt=He({[C.Schema.StepType.Click]:{required:["selectors","offsetX","offsetY"],optional:["assertedEvents","button","deviceType","duration","frame","target","timeout"]},[C.Schema.StepType.DoubleClick]:{required:["offsetX","offsetY","selectors"],optional:["assertedEvents","button","deviceType","frame","target","timeout"]},[C.Schema.StepType.Hover]:{required:["selectors"],optional:["assertedEvents","frame","target","timeout"]},[C.Schema.StepType.Change]:{required:["selectors","value"],optional:["assertedEvents","frame","target","timeout"]},[C.Schema.StepType.KeyDown]:{required:["key"],optional:["assertedEvents","target","timeout"]},[C.Schema.StepType.KeyUp]:{required:["key"],optional:["assertedEvents","target","timeout"]},[C.Schema.StepType.Scroll]:{required:[],optional:["assertedEvents","frame","target","timeout","x","y"]},[C.Schema.StepType.Close]:{required:[],optional:["assertedEvents","target","timeout"]},[C.Schema.StepType.Navigate]:{required:["url"],optional:["assertedEvents","target","timeout"]},[C.Schema.StepType.WaitForElement]:{required:["selectors"],optional:["assertedEvents","attributes","count","frame","operator","properties","target","timeout","visible"]},[C.Schema.StepType.WaitForExpression]:{required:["expression"],optional:["assertedEvents","frame","target","timeout"]},[C.Schema.StepType.CustomStep]:{required:["name","parameters"],optional:["assertedEvents","target","timeout"]},[C.Schema.StepType.EmulateNetworkConditions]:{required:["download","latency","upload"],optional:["assertedEvents","target","timeout"]},[C.Schema.StepType.SetViewport]:{required:["deviceScaleFactor","hasTouch","height","isLandscape","isMobile","width"],optional:["assertedEvents","target","timeout"]}}),O={notSaved:"Not saved: {error}",addAttribute:"Add {attributeName}",deleteRow:"Delete row",addFrameIndex:"Add frame index within the frame tree",removeFrameIndex:"Remove frame index",addSelectorPart:"Add a selector part",removeSelectorPart:"Remove a selector part",addSelector:"Add a selector",removeSelector:"Remove a selector",unknownActionType:"Enter a valid action type"},Qr=mt.i18n.registerUIStrings("panels/recorder/StepEditor.ts",O),K=mt.i18n.getLocalizedString.bind(void 0,Qr),eo=t=>JSON.parse(JSON.stringify(t)),ae=class{static#t=new Gr.SharedObject(()=>C.RecordingPlayer.RecordingPlayer.connectPuppeteer(),({browser:e})=>C.RecordingPlayer.RecordingPlayer.disconnectPuppeteer(e));static async default(e){let r={type:e},o=vt[r.type],i=Promise.resolve();for(let s of o.required)i=Promise.all([i,(async()=>Object.assign(r,{[s]:await this.defaultByAttribute(r,s)}))()]);return await i,Object.freeze(r)}static async defaultByAttribute(e,r){return await this.#t.run(o=>{switch(r){case"assertedEvents":return fe(P.assertedEvents,new I({0:{url:o.page.url()||P.assertedEvents[0].url}}));case"url":return o.page.url()||P.url;case"height":return o.page.evaluate(()=>visualViewport.height).then(i=>i||P.height);case"width":return o.page.evaluate(()=>visualViewport.width).then(i=>i||P.width);default:return P[r]}})}static fromStep(e){let r=structuredClone(e);for(let o of["parameters","properties"])o in e&&e[o]!==void 0&&(r[o]=JSON.stringify(e[o]));if("attributes"in e&&e.attributes){r.attributes=[];for(let[o,i]of Object.entries(e.attributes))r.attributes.push({name:o,value:i})}return"selectors"in e&&(r.selectors=e.selectors.map(o=>typeof o=="string"?[o]:[...o])),He(r)}static toStep(e){let r=structuredClone(e);for(let o of["parameters","properties"]){let i=e[o];i&&Object.assign(r,{[o]:JSON.parse(i)})}if(e.attributes)if(e.attributes.length!==0){let o={};for(let{name:i,value:s}of e.attributes)Object.assign(o,{[i]:s});Object.assign(r,{attributes:o})}else"attributes"in r&&delete r.attributes;if(e.selectors){let o=e.selectors.filter(i=>i.length>0).map(i=>i.length===1?i[0]:[...i]);o.length!==0?Object.assign(r,{selectors:o}):"selectors"in r&&delete r.selectors}return e.frame?.length===0&&"frame"in r&&delete r.frame,eo(C.SchemaUtils.parseStep(r))}};function ee(t,e){if(!t.disabled)return U`
    <devtools-button
      title=${e.title}
      .accessibleLabel=${e.title}
      .size=${"SMALL"}
      .iconName=${e.iconName}
      .variant=${"icon"}
      jslog=${T.action(e.class).track({click:!0})}
      class="inline-button ${e.class}"
      @click=${e.onClick}
    ></devtools-button>
  `}function Ie(t,e){if(!(t.disabled||![...vt[t.state.type].optional].includes(e)||t.disabled))return U`<devtools-button
    .size=${"SMALL"}
    .iconName=${"bin"}
    .variant=${"icon"}
    .title=${K(O.deleteRow)}
    class="inline-button delete-row"
    data-attribute=${e}
    jslog=${T.action("delete").track({click:!0})}
    @click=${t.handleDeleteRowClick(e)}
  ></devtools-button>`}var to=(t,e,r)=>{let o=new Set;function i(c){return o.add("type"),U`<div class="row attribute" data-attribute="type" jslog=${T.treeItem("type").track({resize:!0})}>
      <div id="type">type<span class="separator">:</span></div>
      <devtools-suggestion-input
        aria-labelledby="type"
        .disabled=${!c||t.disabled}
        .options=${Object.values(C.Schema.StepType)}
        .placeholder=${P.type}
        .value=${Q(t.state.type)}
        @blur=${t.handleTypeInputBlur}
      ></devtools-suggestion-input>
    </div>`}function s(c){o.add(c);let d=t.state[c]?.toString();if(d!==void 0)return U`<div class="row attribute" data-attribute=${c} jslog=${T.treeItem(ht.StringUtilities.toKebabCase(c)).track({resize:!0})}>
      <div id=${c}>${c}<span class="separator">:</span></div>
      <devtools-suggestion-input
        .disabled=${t.disabled}
        aria-labelledby=${c}
        .placeholder=${P[c].toString()}
        .value=${Q(d)}
        .mimeType=${(()=>{switch(c){case"expression":return"text/javascript";case"properties":return"application/json";default:return""}})()}
        @blur=${t.handleInputBlur({attribute:c,from(p){if(!(t.state[c]===void 0||t.state[c]===p))return{[c]:p}}})}
      ></devtools-suggestion-input>
      ${Ie(t,c)}
    </div>`}function n(){if(o.add("frame"),t.state.frame!==void 0)return U`
      <div class="attribute" data-attribute="frame" jslog=${T.treeItem("frame").track({resize:!0})}>
        <div class="row">
          <div id="frame">frame<span class="separator">:</span></div>
          ${Ie(t,"frame")}
        </div>
        ${t.state.frame.map((c,d,p)=>U`
            <div class="padded row">
              <devtools-suggestion-input
                aria-labelledby="frame"
                .disabled=${t.disabled}
                .placeholder=${P.frame[0].toString()}
                .value=${Q(c.toString())}
                data-path=${`frame.${d}`}
                @blur=${t.handleInputBlur({attribute:"frame",from(N){if(!(t.state.frame?.[d]===void 0||t.state.frame[d]===N))return{frame:new I({[d]:N})}}})}
              ></devtools-suggestion-input>
              ${ee(t,{class:"add-frame",title:K(O.addFrameIndex),iconName:"plus",onClick:t.handleAddOrRemoveClick({frame:new I({[d+1]:new ze(P.frame[0])})},`devtools-suggestion-input[data-path="frame.${d+1}"]`)})}
              ${ee(t,{class:"remove-frame",title:K(O.removeFrameIndex),iconName:"minus",onClick:t.handleAddOrRemoveClick({frame:new I({[d]:void 0})},`devtools-suggestion-input[data-path="frame.${Math.min(d,p.length-2)}"]`)})}
            </div>
          `)}
      </div>
    `}function l(){if(o.add("selectors"),t.state.selectors!==void 0)return U`<div class="attribute" data-attribute="selectors" jslog=${T.treeItem("selectors")}>
      <div class="row">
        <div>selectors<span class="separator">:</span></div>
        ${Jr(Te,{disabled:t.disabled,onSelectorPicked:t.handleSelectorPicked,onAttributeRequested:t.handleAttributeRequested})}
        ${Ie(t,"selectors")}
      </div>
      ${t.state.selectors.map((c,d,p)=>U`<div class="padded row" data-selector-path=${d}>
            <div id="selector-${d}">selector #${d+1}<span class="separator">:</span></div>
            ${ee(t,{class:"add-selector",title:K(O.addSelector),iconName:"plus",onClick:t.handleAddOrRemoveClick({selectors:new I({[d+1]:new ze(structuredClone(P.selectors[0]))})},`devtools-suggestion-input[data-path="selectors.${d+1}.0"]`)})}
            ${ee(t,{class:"remove-selector",title:K(O.removeSelector),iconName:"minus",onClick:t.handleAddOrRemoveClick({selectors:new I({[d]:void 0})},`devtools-suggestion-input[data-path="selectors.${Math.min(d,p.length-2)}.0"]`)})}
          </div>
          ${c.map((N,E,V)=>U`<div
              class="double padded row"
              data-selector-path="${d}.${E}"
            >
              <devtools-suggestion-input
                aria-labelledby="selector-${d}"
                .disabled=${t.disabled}
                .placeholder=${P.selectors[0][0]}
                .value=${Q(N)}
                data-path=${`selectors.${d}.${E}`}
                @blur=${t.handleInputBlur({attribute:"selectors",from(de){if(!(t.state.selectors?.[d]?.[E]===void 0||t.state.selectors[d][E]===de))return{selectors:new I({[d]:new I({[E]:de})})}}})}
              ></devtools-suggestion-input>
              ${ee(t,{class:"add-selector-part",title:K(O.addSelectorPart),iconName:"plus",onClick:t.handleAddOrRemoveClick({selectors:new I({[d]:new I({[E+1]:new ze(P.selectors[0][0])})})},`devtools-suggestion-input[data-path="selectors.${d}.${E+1}"]`)})}
              ${ee(t,{class:"remove-selector-part",title:K(O.removeSelectorPart),iconName:"minus",onClick:t.handleAddOrRemoveClick({selectors:new I({[d]:new I({[E]:void 0})})},`devtools-suggestion-input[data-path="selectors.${d}.${Math.min(E,V.length-2)}"]`)})}
            </div>`)}`)}
    </div>`}function g(){if(o.add("assertedEvents"),t.state.assertedEvents!==void 0)return U`<div class="attribute" data-attribute="assertedEvents" jslog=${T.treeItem("asserted-events")}>
      <div class="row">
        <div>asserted events<span class="separator">:</span></div>
        ${Ie(t,"assertedEvents")}
      </div>
      ${t.state.assertedEvents.map((c,d)=>U` <div class="padded row" jslog=${T.treeItem("event-type")}>
            <div id="event-type">type<span class="separator">:</span></div>
            <div aria-labelledby="event-type">${c.type}</div>
          </div>
          <div class="padded row" jslog=${T.treeItem("event-title")}>
            <div id="event-title">title<span class="separator">:</span></div>
            <devtools-suggestion-input
              aria-labelledby="event-title"
              .disabled=${t.disabled}
              .placeholder=${P.assertedEvents[0].title}
              .value=${Q(c.title??"")}
              @blur=${t.handleInputBlur({attribute:"assertedEvents",from(p){if(!(t.state.assertedEvents?.[d]?.title===void 0||t.state.assertedEvents[d].title===p))return{assertedEvents:new I({[d]:{title:p}})}}})}
            ></devtools-suggestion-input>
          </div>
          <div  id="event-url" class="padded row" jslog=${T.treeItem("event-url")}>
            <div>url<span class="separator">:</span></div>
            <devtools-suggestion-input
              aria-labelledby="event-url"
              .disabled=${t.disabled}
              .placeholder=${P.assertedEvents[0].url}
              .value=${Q(c.url??"")}
              @blur=${t.handleInputBlur({attribute:"url",from(p){if(!(t.state.assertedEvents?.[d]?.url===void 0||t.state.assertedEvents[d].url===p))return{assertedEvents:new I({[d]:{url:p}})}}})}
            ></devtools-suggestion-input>
          </div>`)}
    </div> `}function h(){if(o.add("attributes"),t.state.attributes!==void 0)return U`<div class="attribute" data-attribute="attributes" jslog=${T.treeItem("attributes")}>
      <div class="row">
        <div>attributes<span class="separator">:</span></div>
        ${Ie(t,"attributes")}
      </div>
      ${t.state.attributes.map(({name:c,value:d},p,N)=>U`<div class="padded row" jslog=${T.treeItem("attribute")}>
          <devtools-suggestion-input
            .disabled=${t.disabled}
            .placeholder=${P.attributes[0].name}
            .value=${Q(c)}
            data-path=${`attributes.${p}.name`}
            jslog=${T.key().track({change:!0})}
            @blur=${t.handleInputBlur({attribute:"attributes",from(E){if(!(t.state.attributes?.[p]?.name===void 0||t.state.attributes[p].name===E))return{attributes:new I({[p]:{name:E}})}}})}
          ></devtools-suggestion-input>
          <span class="separator">:</span>
          <devtools-suggestion-input
            .disabled=${t.disabled}
            .placeholder=${P.attributes[0].value}
            .value=${Q(d)}
            data-path=${`attributes.${p}.value`}
            @blur=${t.handleInputBlur({attribute:"attributes",from(E){if(!(t.state.attributes?.[p]?.value===void 0||t.state.attributes[p].value===E))return{attributes:new I({[p]:{value:E}})}}})}
          ></devtools-suggestion-input>
          ${ee(t,{class:"add-attribute-assertion",title:K(O.addSelectorPart),iconName:"plus",onClick:t.handleAddOrRemoveClick({attributes:new I({[p+1]:new ze((()=>{{let E=new Set(N.map(({name:Ir})=>Ir)),V=P.attributes[0],de=V.name,It=0;for(;E.has(de);)++It,de=`${V.name}-${It}`;return{...V,name:de}}})())})},`devtools-suggestion-input[data-path="attributes.${p+1}.name"]`)})}
          ${ee(t,{class:"remove-attribute-assertion",title:K(O.removeSelectorPart),iconName:"minus",onClick:t.handleAddOrRemoveClick({attributes:new I({[p]:void 0})},`devtools-suggestion-input[data-path="attributes.${Math.min(p,N.length-2)}.value"]`)})}
        </div>`)}
    </div>`}function a(){return[...vt[t.state.type].optional].filter(d=>t.state[d]===void 0).map(d=>U`<devtools-button
          .variant=${"outlined"}
          class="add-row"
          data-attribute=${d}
          jslog=${T.action(`add-${ht.StringUtilities.toKebabCase(d)}`)}
          @click=${t.handleAddRowClickEvent}
        >
          ${K(O.addAttribute,{attributeName:d})}
        </devtools-button>`)}let x=U`
    <style>${nr}</style>
    <div class="wrapper" jslog=${T.tree("step-editor")} >
      ${i(t.isTypeEditable)} ${s("target")}
      ${n()} ${l()}
      ${s("deviceType")} ${s("button")}
      ${s("url")} ${s("x")}
      ${s("y")} ${s("offsetX")}
      ${s("offsetY")} ${s("value")}
      ${s("key")} ${s("operator")}
      ${s("count")} ${s("expression")}
      ${s("duration")} ${g()}
      ${s("timeout")} ${s("width")}
      ${s("height")} ${s("deviceScaleFactor")}
      ${s("isMobile")} ${s("hasTouch")}
      ${s("isLandscape")} ${s("download")}
      ${s("upload")} ${s("latency")}
      ${s("name")} ${s("parameters")}
      ${s("visible")} ${s("properties")}
      ${h()}
      ${t.error?U`
            <div class="error">
              ${K(O.notSaved,{error:t.error})}
            </div>
          `:void 0}
      ${t.disabled?void 0:U`<div
            class="row-buttons wrapped gap row regular-font no-margin"
          >
            ${a()}
          </div>`}
    </div>
  `;for(let c of Object.keys(ar))if(!o.has(c))throw new Error(`The editable attribute ${c} does not have UI`);Xr(x,r,{container:{listeners:{keydown:t.handleKeyDownEvent}}})},ve=class extends ft.Widget.Widget{#t;#e;#o=!0;#i=!1;#r;onStepEdited;onAttributeRequested;constructor(e,r=to){super(e,{useShadowDom:!0}),this.#t={type:C.Schema.StepType.WaitForElement},this.#r=r}set isTypeEditable(e){this.#o=e,this.requestUpdate()}set disabled(e){this.#i=e,this.requestUpdate()}set step(e){this.#t=He(ae.fromStep(e)),this.#e=void 0,this.requestUpdate()}performUpdate(){let e={state:this.#t,disabled:this.#i,error:this.#e,isTypeEditable:this.#o,handleInputBlur:this.#f,handleTypeInputBlur:this.#y,handleAddRowClickEvent:this.#S,handleDeleteRowClick:this.#u,handleSelectorPicked:this.#n,handleAttributeRequested:this.#l,handleAddOrRemoveClick:this.#c,handleKeyDownEvent:this.#a};this.#r(e,void 0,this.contentElement)}#s(e){try{this.onStepEdited?.(ae.toStep(e)),this.#t=e}catch(r){this.#e=r.message}this.requestUpdate()}#n=e=>{this.#s(fe(this.#t,{target:e.target,frame:e.frame,selectors:e.selectors.map(r=>typeof r=="string"?[r]:r),offsetX:e.offsetX,offsetY:e.offsetY}))};#l=e=>{this.onAttributeRequested?.(e)};#c=(e,r)=>o=>{o.preventDefault(),o.stopPropagation(),this.#s(fe(this.#t,e)),this.#m(r)};#u=e=>r=>{r.preventDefault(),r.stopPropagation(),this.#s(fe(this.#t,{[e]:void 0}))};#m=e=>{this.updateComplete.then(()=>{this.contentElement.querySelector(e)?.focus()})};#a=e=>{if(ut(e instanceof KeyboardEvent),e.target instanceof Ke.SuggestionInput.SuggestionInput&&e.key==="Enter"){e.preventDefault(),e.stopPropagation();let r=this.contentElement.querySelectorAll("devtools-suggestion-input"),o=[...r].findIndex(i=>i===e.target);o>=0&&o+1<r.length?r[o+1].focus():e.target.blur()}};#f=e=>r=>{if(ut(r.target instanceof Ke.SuggestionInput.SuggestionInput),r.target.disabled)return;let o=ar[e.attribute],i=Zr[o](r.target.value),s=e.from.bind(this)(i);s&&this.#s(fe(this.#t,s))};#y=async e=>{if(ut(e.target instanceof Ke.SuggestionInput.SuggestionInput),e.target.disabled)return;let r=e.target.value;if(r!==this.#t.type){if(!Object.values(C.Schema.StepType).includes(r)){this.#e=K(O.unknownActionType),this.requestUpdate();return}this.#s(await ae.default(r))}};#S=async e=>{e.preventDefault(),e.stopPropagation();let r=e.target.dataset.attribute;this.#s(fe(this.#t,{[r]:await ae.defaultByAttribute(this.#t,r)})),this.#m(`[data-attribute=${r}].attribute devtools-suggestion-input`)}};var dr=`*{margin:0;padding:0;box-sizing:border-box;font-size:inherit}.title-container{min-width:0;font-size:var(--sys-size-7);display:flex;flex-direction:row;gap:var(--sys-size-2);outline-offset:var(--sys-size-2);flex-grow:1;align-items:center}.action{display:flex;align-items:center}.title{flex:1;min-width:0}.is-start-of-group .title{font-weight:bold}.error-icon{display:none}.breakpoint-icon{visibility:hidden;cursor:pointer;opacity:0%;fill:var(--sys-color-primary);stroke:#1a73e8;transform:translate(-1.92px,-3px)}.circle-icon{fill:var(--sys-color-primary);stroke:var(--sys-color-cdt-base-container);stroke-width:4px;r:5px;cx:8px;cy:8px}.is-start-of-group:not(:first-of-type) .circle-icon{r:7px;fill:var(--sys-color-cdt-base-container);stroke:var(--sys-color-primary);stroke-width:2px}.step.is-success .circle-icon{fill:var(--sys-color-primary);stroke:var(--sys-color-primary)}.step.is-current .circle-icon{stroke-dasharray:24 10;animation:rotate 1s linear infinite;fill:var(--sys-color-cdt-base-container);stroke:var(--sys-color-primary);stroke-width:2px}.error{margin:16px 0 0;padding:8px;background:var(--sys-color-error-container);color:var(--sys-color-error);position:relative}@keyframes rotate{0%{transform:translate(8px,8px) rotate(0) translate(-8px,-8px)}100%{transform:translate(8px,8px) rotate(360deg) translate(-8px,-8px)}}.step.is-error .circle-icon{fill:var(--sys-color-error);stroke:var(--sys-color-error)}.step.is-error .error-icon{display:block;transform:translate(4px,4px)}:host-context(.was-successful) .circle-icon{animation:flash-circle 2s}:host-context(.was-successful) .breakpoint-icon{animation:flash-breakpoint-icon 2s}@keyframes flash-circle{25%{fill:var(--override-color-recording-successful-text);stroke:var(--override-color-recording-successful-text)}75%{fill:var(--override-color-recording-successful-text);stroke:var(--override-color-recording-successful-text)}}@keyframes flash-breakpoint-icon{25%{fill:var(--override-color-recording-successful-text);stroke:var(--override-color-recording-successful-text)}75%{fill:var(--override-color-recording-successful-text);stroke:var(--override-color-recording-successful-text)}}.chevron{width:14px;height:14px;transition:200ms;position:absolute;top:14px;left:24px;transform:rotate(-90deg);color:var(--sys-color-on-surface)}.expanded .chevron{transform:rotate(0deg)}.is-start-of-group .chevron{top:34px}.details{display:none;margin-top:8px;position:relative}.expanded .details{display:block}.step-details{overflow:auto}devtools-recorder-step-editor{border:1px solid var(--sys-color-neutral-outline);padding:3px 6px 6px;margin-left:-6px;border-radius:3px}devtools-recorder-step-editor:hover{border:1px solid var(--sys-color-neutral-outline)}devtools-recorder-step-editor.is-selected{background-color:color-mix(in srgb,var(--sys-color-tonal-container),var(--sys-color-cdt-base-container) 50%);border:1px solid var(--sys-color-tonal-outline)}.summary{display:flex;flex-flow:row nowrap}.subtitle{font-weight:normal;color:var(--sys-color-on-surface-subtle);word-break:break-all;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.main-title{word-break:break-all;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.step-actions{border:none;border-radius:0;height:24px;--override-select-menu-show-button-border-radius:0;--override-select-menu-show-button-outline:none;--override-select-menu-show-button-padding:0}.step.has-breakpoint .circle-icon{visibility:hidden}.step:not(.is-start-of-group).has-breakpoint .breakpoint-icon{visibility:visible;opacity:100%}.step:not(.is-start-of-group, .has-breakpoint) .icon:hover .circle-icon{transition:opacity 0.2s;opacity:0%}.step:not(.is-start-of-group, .has-breakpoint) .icon:hover .error-icon{visibility:hidden}.step:not(.is-start-of-group, .has-breakpoint) .icon:hover .breakpoint-icon{transition:opacity 0.2s;visibility:visible;opacity:50%}
/*# sourceURL=${import.meta.resolve("./stepView.css")} */`;var ur={};_(ur,{DEFAULT_VIEW:()=>gr,TimelineSection:()=>Pe});import*as pr from"./../../ui/legacy/legacy.js";import*as Me from"./../../ui/lit/lit.js";var cr=`*{margin:0;padding:0;box-sizing:border-box;font-size:inherit}.timeline-section{position:relative;padding:8px 0 8px 40px;margin-left:8px;--override-color-recording-successful-text:#36a854;--override-color-recording-successful-background:#e6f4ea}.overlay{position:absolute;width:100vw;height:100%;left:calc(-32px - 80px);top:0;z-index:-1;pointer-events:none}@container (max-width: 400px){.overlay{left:-32px}}:hover .overlay{background:var(--sys-color-state-hover-on-subtle)}.is-selected .overlay{background:var(--sys-color-tonal-container)}:host-context(.is-stopped) .overlay{background:var(--sys-color-state-ripple-primary);outline:1px solid var(--sys-color-state-focus-ring);z-index:4}.is-start-of-group:not(:first-of-type){padding-top:16px}.is-end-of-group{padding-bottom:16px}.icon{position:absolute;left:4px;transform:translateX(-50%);z-index:2}.bar{position:absolute;left:4px;display:block;transform:translateX(-50%);top:18px;height:100%;z-index:1}.bar .background{fill:var(--sys-color-state-hover-on-subtle)}.bar .line{fill:var(--sys-color-primary)}.is-first-section .bar{height:100%;display:none}.is-first-section:not(.is-last-section) .bar{display:block}.is-last-section .bar .line{display:none}.is-last-section .bar .background{display:none}:host-context(.is-error) .bar .line{fill:var(--sys-color-error)}:host-context(.is-error) .bar .background{fill:var(--sys-color-error-container)}:host-context(.was-successful) .bar .background{animation:flash-background 2s}:host-context(.was-successful) .bar .line{animation:flash-line 2s}@keyframes flash-background{25%{fill:var(--override-color-recording-successful-background)}75%{fill:var(--override-color-recording-successful-background)}}@keyframes flash-line{25%{fill:var(--override-color-recording-successful-text)}75%{fill:var(--override-color-recording-successful-text)}}
/*# sourceURL=${import.meta.resolve("./timelineSection.css")} */`;var{html:ro}=Me,gr=(t,e,r)=>{let o={"timeline-section":!0,"is-end-of-group":t.isEndOfGroup,"is-start-of-group":t.isStartOfGroup,"is-first-section":t.isFirstSection,"is-last-section":t.isLastSection,"is-selected":t.isSelected};Me.render(ro`
    <style>${cr}</style>
    <div class=${Me.Directives.classMap(o)}>
      <div class="overlay"></div>
      <div class="icon"><slot name="icon"></slot></div>
      <svg width="24" height="100%" class="bar">
        <rect class="line" x="7" y="0" width="2" height="100%" />
      </svg>
      <slot></slot>
    </div>
  `,r)},Pe=class extends pr.Widget.Widget{#t=!1;#e=!1;#o=!1;#i=!1;#r=!1;#s;constructor(e,r=gr){super(e,{useShadowDom:!0}),this.#s=r}set isEndOfGroup(e){this.#t=e,this.requestUpdate()}set isStartOfGroup(e){this.#e=e,this.requestUpdate()}set isFirstSection(e){this.#o=e,this.requestUpdate()}set isLastSection(e){this.#i=e,this.requestUpdate()}set isSelected(e){this.#r=e,this.requestUpdate()}performUpdate(){this.#s({isEndOfGroup:this.#t,isStartOfGroup:this.#e,isFirstSection:this.#o,isLastSection:this.#i,isSelected:this.#r},{},this.contentElement)}};var{html:le}=Ue,{widget:bt}=Ae.Widget,m={setViewportClickTitle:"Set viewport",customStepTitle:"Custom step",clickStepTitle:"Click",doubleClickStepTitle:"Double click",hoverStepTitle:"Hover",emulateNetworkConditionsStepTitle:"Emulate network conditions",changeStepTitle:"Change",closeStepTitle:"Close",scrollStepTitle:"Scroll",keyUpStepTitle:"Key up",navigateStepTitle:"Navigate",keyDownStepTitle:"Key down",waitForElementStepTitle:"Wait for element",waitForExpressionStepTitle:"Wait for expression",elementRoleButton:"Button",elementRoleInput:"Input",elementRoleFallback:"Element",addStepBefore:"Add step before",addStepAfter:"Add step after",removeStep:"Remove step",openStepActions:"Open step actions",addBreakpoint:"Add breakpoint",removeBreakpoint:"Remove breakpoint",copyAs:"Copy as",stepManagement:"Manage steps",breakpoints:"Breakpoints"},oo=wt.i18n.registerUIStrings("panels/recorder/StepView.ts",m),f=wt.i18n.getLocalizedString.bind(void 0,oo),te="copy-step-as-";function io(t){if(t.section)return t.section.title?t.section.title:le`<span class="fallback">(No Title)</span>`;if(!t.step)throw new Error("Missing both step and section");switch(t.step.type){case D.Schema.StepType.CustomStep:return f(m.customStepTitle);case D.Schema.StepType.SetViewport:return f(m.setViewportClickTitle);case D.Schema.StepType.Click:return f(m.clickStepTitle);case D.Schema.StepType.DoubleClick:return f(m.doubleClickStepTitle);case D.Schema.StepType.Hover:return f(m.hoverStepTitle);case D.Schema.StepType.EmulateNetworkConditions:return f(m.emulateNetworkConditionsStepTitle);case D.Schema.StepType.Change:return f(m.changeStepTitle);case D.Schema.StepType.Close:return f(m.closeStepTitle);case D.Schema.StepType.Scroll:return f(m.scrollStepTitle);case D.Schema.StepType.KeyUp:return f(m.keyUpStepTitle);case D.Schema.StepType.KeyDown:return f(m.keyDownStepTitle);case D.Schema.StepType.WaitForElement:return f(m.waitForElementStepTitle);case D.Schema.StepType.WaitForExpression:return f(m.waitForExpressionStepTitle);case D.Schema.StepType.Navigate:return f(m.navigateStepTitle)}}function so(t){switch(t){case"button":return f(m.elementRoleButton);case"input":return f(m.elementRoleInput);default:return f(m.elementRoleFallback)}}function no(t){if(!("selectors"in t))return"";let e=t.selectors.flat().find(o=>o.startsWith("aria/"));if(!e)return"";let r=e.match(/^aria\/(.+?)(\[role="(.+)"\])?$/);return r?`${so(r[3])} "${r[1]}"`:""}function ao(t){return t?t.url:""}function lo(t){return le`
    <devtools-menu-button
      class="step-actions"
      title=${f(m.openStepActions)}
      aria-label=${f(m.openStepActions)}
      .populateMenuCall=${t.populateStepContextMenu}
      @keydown=${e=>{e.stopPropagation()}}
      jslog=${re.dropDown("step-actions").track({click:!0})}
      .iconName=${"dots-vertical"}
    ></devtools-menu-button>
  `}var hr=(t,e,r)=>{if(!t.step&&!t.section)return;let o={step:!0,expanded:t.showDetails,"is-success":t.state==="success","is-current":t.state==="current","is-outstanding":t.state==="outstanding","is-error":t.state==="error","is-stopped":t.state==="stopped","is-start-of-group":t.isStartOfGroup,"is-first-section":t.isFirstSection,"has-breakpoint":t.hasBreakpoint},i=!!t.step,s=io({step:t.step,section:t.section}),n=t.step?no(t.step):ao(t.section);Ue.render(le`
    <style>${dr}</style>
    <div>
      <devtools-widget ${bt(Pe,{isFirstSection:t.isFirstSection,isLastSection:t.isLastSection,isStartOfGroup:t.isStartOfGroup,isEndOfGroup:t.isEndOfGroup,isSelected:t.isSelected})}
        @contextmenu=${l=>{let g=new Ae.ContextMenu.ContextMenu(l);t.populateStepContextMenu(g),g.show()}}
        data-step-index=${t.stepIndex}
        data-section-index=${t.sectionIndex}
        @click=${l=>{l.stopPropagation();let g=t.step||t.section;g&&t.onStepClick(g)}}
        @mouseover=${()=>{let l=t.step||t.section;l&&t.onStepHover(l)}}
        class=${Ue.Directives.classMap(o)}>
        <svg slot="icon" width="24" height="24" class="icon">
          <circle class="circle-icon"/>
          <g class="error-icon">
            <path d="M1.5 1.5L6.5 6.5" stroke="white" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
            <path d="M1.5 6.5L6.5 1.5" stroke="white" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
          </g>
          <path @click=${t.onBreakpointClick} jslog=${re.action("breakpoint").track({click:!0})} class="breakpoint-icon" d="M2.5 5.5H17.7098L21.4241 12L17.7098 18.5H2.5V5.5Z"/>
        </svg>
        <div class="summary">
          <div class="title-container ${i?"action":""}"
            @click=${i?t.toggleShowDetails:void 0}
            @keydown=${i?t.onToggleShowDetailsKeydown:void 0}
            tabindex="0"
            jslog=${re.sectionHeader().track({click:!0})}
            aria-role=${i?"button":""}
            aria-label=${i?"Show details for step":""}
          >
            ${i?le`<devtools-icon
                    class="chevron"
                    jslog=${re.expand().track({click:!0})}
                    name="triangle-down">
                  </devtools-icon>`:""}
            <div class="title">
              <div class="main-title" title=${s}>${s}</div>
              <div class="subtitle" title=${n}>${n}</div>
            </div>
          </div>
          ${lo(t)}
        </div>
        <div class="details">
          ${t.step&&le`<devtools-widget ${bt(ve,{step:t.step,disabled:t.isPlaying,onStepEdited:t.stepEdited,onAttributeRequested:t.onAttributeRequested})}
            class=${t.isSelected?"is-selected":""}></devtools-widget>`}
          ${t.section?.causingStep&&le`<devtools-widget ${bt(ve,{step:t.section.causingStep,isTypeEditable:!1,disabled:t.isPlaying,onStepEdited:t.stepEdited,onAttributeRequested:t.onAttributeRequested})}></devtools-widget>`}
          }
        </div>
        ${t.error&&le`
          <div class="error" role="alert">
            ${t.error.message}
          </div>
        `}
      </devtools-widget>
    </div>
  `,r,{container:{classes:["step-view-widget"]}})},be=class extends Ae.Widget.Widget{#t=new IntersectionObserver(e=>{this.#e.isVisible=e[0].isIntersecting});onStepChanged;onAddStep;onRemoveStep;onAddBreakpoint;onRemoveBreakpoint;onCopyStep;onAttributeRequested;#e={state:"default",showDetails:!1,isEndOfGroup:!1,isStartOfGroup:!1,stepIndex:0,sectionIndex:0,isFirstSection:!1,isLastSection:!1,isRecording:!1,isPlaying:!1,isVisible:!1,hasBreakpoint:!1,removable:!0,builtInConverters:[],extensionConverters:[],isSelected:!1,actions:[],stepEdited:this.#s.bind(this),onAttributeRequested:e=>this.onAttributeRequested?.(e),onBreakpointClick:this.#l.bind(this),handleStepAction:this.#n.bind(this),toggleShowDetails:this.#i.bind(this),onToggleShowDetailsKeydown:this.#r.bind(this),populateStepContextMenu:this.#u.bind(this),onStepClick:()=>{},onStepHover:()=>{}};#o;constructor(e,r){super(e,{useShadowDom:"pure"}),this.#o=r||hr}set step(e){this.#e.step=e,this.requestUpdate()}set section(e){this.#e.section=e,this.requestUpdate()}set state(e){let r=this.#e.state;this.#e.state=e,this.performUpdate(),this.#e.state!==r&&this.#e.state==="current"&&!this.#e.isVisible&&this.element.scrollIntoView()}set error(e){this.#e.error=e,this.requestUpdate()}set isEndOfGroup(e){this.#e.isEndOfGroup=e,this.requestUpdate()}set isStartOfGroup(e){this.#e.isStartOfGroup=e,this.requestUpdate()}set stepIndex(e){this.#e.stepIndex=e,this.requestUpdate()}set sectionIndex(e){this.#e.sectionIndex=e,this.requestUpdate()}set isFirstSection(e){this.#e.isFirstSection=e,this.requestUpdate()}set isLastSection(e){this.#e.isLastSection=e,this.requestUpdate()}set isRecording(e){this.#e.isRecording=e,this.requestUpdate()}set isPlaying(e){this.#e.isPlaying=e,this.requestUpdate()}set hasBreakpoint(e){this.#e.hasBreakpoint=e,this.requestUpdate()}set removable(e){this.#e.removable=e,this.requestUpdate()}set builtInConverters(e){this.#e.builtInConverters=e,this.requestUpdate()}set extensionConverters(e){this.#e.extensionConverters=e,this.requestUpdate()}set isSelected(e){this.#e.isSelected=e,this.requestUpdate()}set recorderSettings(e){this.#e.recorderSettings=e,this.requestUpdate()}set onStepClick(e){this.#e.onStepClick=e,this.requestUpdate()}set onStepHover(e){this.#e.onStepHover=e,this.requestUpdate()}get step(){return this.#e.step}get section(){return this.#e.section}wasShown(){super.wasShown(),this.#t.observe(this.element),this.requestUpdate()}willHide(){super.willHide(),this.#t.unobserve(this.element)}#i(){this.#e.showDetails=!this.#e.showDetails,this.requestUpdate()}#r(e){let r=e;(r.key==="Enter"||r.key===" ")&&(this.#i(),e.stopPropagation(),e.preventDefault())}#s(e){let r=this.#e.step||this.#e.section?.causingStep;if(!r)throw new Error("Expected step.");this.onStepChanged?.(r,e)}#n(e){switch(e.itemValue){case"add-step-before":{let r=this.#e.step||this.#e.section;if(!r)throw new Error("Expected step or section.");this.onAddStep?.(r,"before");break}case"add-step-after":{let r=this.#e.step||this.#e.section;if(!r)throw new Error("Expected step or section.");this.onAddStep?.(r,"after");break}case"remove-step":{let r=this.#e.section?.causingStep;if(!this.#e.step&&!r)throw new Error("Expected step.");this.onRemoveStep?.(this.#e.step||r);break}case"add-breakpoint":{if(!this.#e.step)throw new Error("Expected step");this.onAddBreakpoint?.(this.#e.stepIndex);break}case"remove-breakpoint":{if(!this.#e.step)throw new Error("Expected step");this.onRemoveBreakpoint?.(this.#e.stepIndex);break}default:{let r=e.itemValue;if(!r.startsWith(te))throw new Error("Unknown step action.");let o=this.#e.step||this.#e.section?.causingStep;if(!o)throw new Error("Step not found.");let i=r.substring(te.length);this.#e.recorderSettings&&(this.#e.recorderSettings.preferredCopyFormat=i),this.onCopyStep?.(structuredClone(o))}}}#l(){this.#e.hasBreakpoint?this.onRemoveBreakpoint?.(this.#e.stepIndex):this.onAddBreakpoint?.(this.#e.stepIndex),this.requestUpdate()}#c=()=>{let e=[];if(this.#e.isPlaying||(this.#e.step&&e.push({id:"add-step-before",label:f(m.addStepBefore),group:"stepManagement",groupTitle:f(m.stepManagement)}),e.push({id:"add-step-after",label:f(m.addStepAfter),group:"stepManagement",groupTitle:f(m.stepManagement)}),this.#e.removable&&e.push({id:"remove-step",group:"stepManagement",groupTitle:f(m.stepManagement),label:f(m.removeStep)})),this.#e.step&&!this.#e.isRecording&&(this.#e.hasBreakpoint?e.push({id:"remove-breakpoint",label:f(m.removeBreakpoint),group:"breakPointManagement",groupTitle:f(m.breakpoints)}):e.push({id:"add-breakpoint",label:f(m.addBreakpoint),group:"breakPointManagement",groupTitle:f(m.breakpoints)})),this.#e.step){for(let r of this.#e.builtInConverters||[])e.push({id:te+yt.StringUtilities.toKebabCase(r.getId()),label:r.getFormatName(),group:"copy",groupTitle:f(m.copyAs)});for(let r of this.#e.extensionConverters||[])e.push({id:te+yt.StringUtilities.toKebabCase(r.getId()),label:r.getFormatName(),group:"copy",groupTitle:f(m.copyAs),jslogContext:te+"extension"})}return e};#u(e){let r=this.#c(),o=r.filter(n=>n.id.startsWith(te)),i=r.filter(n=>!n.id.startsWith(te));for(let n of i)e.section(n.group).appendItem(n.label,()=>{this.#n(new _e.Menu.MenuItemSelectedEvent(n.id))},{jslogContext:n.id});let s=o.find(n=>n.id===te+this.#e.recorderSettings?.preferredCopyFormat);if(s&&e.section("copy").appendItem(s.label,()=>{this.#n(new _e.Menu.MenuItemSelectedEvent(s.id))},{jslogContext:s.id}),o.length){let n=e.section("copy").appendSubMenuItem(f(m.copyAs),!1,"copy");for(let l of o)l!==s&&n.section(l.group).appendItem(l.label,()=>{this.#n(new _e.Menu.MenuItemSelectedEvent(l.id))},{jslogContext:l.id})}}performUpdate(){this.#e.actions=this.#c(),this.#o(this.#e,void 0,this.contentElement)}};var{html:u}=M,{widget:Se}=oe.Widget,b={mobile:"Mobile",desktop:"Desktop",latency:"Latency: {value} ms",upload:"Upload: {value}",download:"Download: {value}",editReplaySettings:"Edit replay settings",replaySettings:"Replay settings",default:"Default",environment:"Environment",screenshotForSection:"Screenshot for this section",editTitle:"Edit title",requiredTitleError:"Title is required",recording:"Recording\u2026",endRecording:"End recording",recordingIsBeingStopped:"Stopping recording\u2026",timeout:"Timeout: {value} ms",network:"Network",timeoutLabel:"Timeout",timeoutExplanation:"The timeout setting (in milliseconds) applies to every action when replaying the recording. For example, if a DOM element identified by a CSS selector does not appear on the page within the specified timeout, the replay fails with an error.",cancelReplay:"Cancel replay",showCode:"Show code",hideCode:"Hide code",addAssertion:"Add assertion",performancePanel:"Performance panel",codeSidebarOpened:"Code sidebar opened",codeSidebarClosed:"Code sidebar closed"},co=ye.i18n.registerUIStrings("panels/recorder/RecordingView.ts",b),w=ye.i18n.getLocalizedString.bind(void 0,co),St=[X.NetworkManager.NoThrottlingConditions,X.NetworkManager.OfflineConditions,X.NetworkManager.Slow3GConditions,X.NetworkManager.Slow4GConditions,X.NetworkManager.Fast4GConditions];function po({settings:t,replaySettingsExpanded:e,onSelectMenuLabelClick:r,onNetworkConditionsChange:o,onTimeoutInput:i,isRecording:s,replayState:n,onReplaySettingsKeydown:l,onToggleReplaySettings:g}){if(!t)return M.nothing;let h=[];t.viewportSettings&&(h.push(u`<div>${t.viewportSettings.isMobile?w(b.mobile):w(b.desktop)}</div>`),h.push(u`<div class="separator"></div>`),h.push(u`<div>${t.viewportSettings.width}×${t.viewportSettings.height} px</div>`));let a=[];if(!e)t.networkConditionsSettings?t.networkConditionsSettings.title?a.push(u`<div>${t.networkConditionsSettings.title}</div>`):a.push(u`<div>
          ${w(b.download,{value:ye.ByteUtilities.bytesToString(t.networkConditionsSettings.download)})},
          ${w(b.upload,{value:ye.ByteUtilities.bytesToString(t.networkConditionsSettings.upload)})},
          ${w(b.latency,{value:t.networkConditionsSettings.latency})}
        </div>`):a.push(u`<div>${X.NetworkManager.NoThrottlingConditions.title instanceof Function?X.NetworkManager.NoThrottlingConditions.title():X.NetworkManager.NoThrottlingConditions.title}</div>`),a.push(u`<div class="separator"></div>`),a.push(u`<div>${w(b.timeout,{value:t.timeout||Y.RecordingPlayer.defaultTimeout})}</div>`);else{let p=t.networkConditionsSettings?.i18nTitleKey||X.NetworkManager.NoThrottlingConditions.i18nTitleKey,N=St.find(V=>V.i18nTitleKey===p),E="";N&&(E=N.title instanceof Function?N.title():N.title),a.push(u`<div class="editable-setting">
      <label class="wrapping-label" @click=${r}>
        ${w(b.network)}
        <select
            title=${E}
            jslog=${R.dropDown("network-conditions").track({change:!0})}
            @change=${o}>
      ${St.map(V=>u`
        <option jslog=${R.item(xt.StringUtilities.toKebabCase(V.i18nTitleKey||""))}
                value=${V.i18nTitleKey||""} ?selected=${p===V.i18nTitleKey}>
                ${V.title instanceof Function?V.title():V.title}
        </option>`)}
    </select>
      </label>
    </div>`),a.push(u`<div class="editable-setting">
      <label class="wrapping-label" title=${w(b.timeoutExplanation)}>
        ${w(b.timeoutLabel)}
        <input
          @input=${i}
          required
          min=${Y.SchemaUtils.minTimeout}
          max=${Y.SchemaUtils.maxTimeout}
          value=${t.timeout||Y.RecordingPlayer.defaultTimeout}
          jslog=${R.textField("timeout").track({change:!0})}
          class="devtools-text-input"
          type="number">
      </label>
    </div>`)}let x=!s&&!n.isPlaying,c={"settings-title":!0,expanded:e},d={expanded:e,settings:!0};return u`
    <div class="settings-row">
      <div class="settings-container">
        <div
          class=${M.Directives.classMap(c)}
          @keydown=${x&&l}
          @click=${x&&g}
          aria-expanded=${c.expanded??!1}
          tabindex="0"
          role="button"
          jslog=${R.action("replay-settings").track({click:!0})}
          aria-label=${w(b.editReplaySettings)}>
          <span>${w(b.replaySettings)}</span>
          ${x?u`<devtools-icon
                  class="chevron"
                  name="triangle-down">
                </devtools-icon>`:""}
        </div>
        <div class=${M.Directives.classMap(d)}>
          ${a.length?a:u`<div>${w(b.default)}</div>`}
        </div>
      </div>
      <div class="settings-container">
        <div class="settings-title">${w(b.environment)}</div>
        <div class="settings">
          ${h.length?h:u`<div>${w(b.default)}</div>`}
        </div>
      </div>
    </div>
  `}function go(t,e){return t.extensionDescriptor?u`
        <devtools-widget class="recorder-extension-view" ${Se($e,{descriptor:t.extensionDescriptor})}>
        </devtools-widget>
      `:u`
        <devtools-split-view
          direction="auto"
          sidebar-position="second"
          sidebar-initial-size="300"
          sidebar-visibility=${t.showCodeView?"":"hidden"}
        >
          <div slot="main">
            ${fo(t)}
          </div>
          <div slot="sidebar" jslog=${R.pane("source-code").track({resize:!0})}>
            ${t.showCodeView?u`
            <div class="section-toolbar" jslog=${R.toolbar()}>
              <devtools-select-menu
                @selectmenuselected=${t.onCodeFormatChange}
                .showDivider=${!0}
                .showArrow=${!0}
                .sideButton=${!1}
                .showSelectedItem=${!0}
                .position=${"bottom"}
                .buttonTitle=${t.converterName||""}
                .jslogContext=${"code-format"}
              >
                ${t.builtInConverters.map(r=>u`<devtools-menu-item
                    .value=${r.getId()}
                    .selected=${t.converterId===r.getId()}
                    jslog=${R.action().track({click:!0}).context(`converter-${xt.StringUtilities.toKebabCase(r.getId())}`)}
                  >
                    ${r.getFormatName()}
                  </devtools-menu-item>`)}
                ${t.extensionConverters.map(r=>u`<devtools-menu-item
                    .value=${r.getId()}
                    .selected=${t.converterId===r.getId()}
                    jslog=${R.action().track({click:!0}).context("converter-extension")}
                  >
                    ${r.getFormatName()}
                  </devtools-menu-item>`)}
              </devtools-select-menu>
              <devtools-button
                title=${Y.Tooltip.getTooltipForActions(w(b.hideCode),"chrome-recorder.toggle-code-view")}
                .data=${{variant:"icon",size:"SMALL",iconName:"cross"}}
                @click=${t.showCodeToggle}
                jslog=${R.close().track({click:!0})}
              ></devtools-button>
            </div>
            ${uo(t,e)}`:M.nothing}
          </div>
        </devtools-split-view>
      `}function uo(t,e){if(!t.editorState)throw new Error("Unexpected: trying to render the text editor without editorState");return u`
    <div class="text-editor" jslog=${R.textField().track({change:!0})}>
      <devtools-text-editor .state=${t.editorState} ${M.Directives.ref(r=>{!r||!(r instanceof Ge.TextEditor.TextEditor)||(e.highlightLinesInEditor=(o,i,s=!1)=>{let n=r.editor,l=r.createSelection({lineNumber:o+i,columnNumber:0},{lineNumber:o,columnNumber:0}),g=r.state.doc.lineAt(l.main.anchor);l=r.createSelection({lineNumber:o+i-1,columnNumber:g.length+1},{lineNumber:o,columnNumber:0}),n.dispatch({selection:l,effects:s?[we.EditorView.scrollIntoView(l.main,{y:"nearest"})]:void 0})})})}></devtools-text-editor>
    </div>
  `}function ho(t){return t.screenshot?u`
      <img class="screenshot" src=${t.screenshot} alt=${w(b.screenshotForSection)} />
    `:null}function mo(t){return t.replayState.isPlaying?u`
        <devtools-button .jslogContext=${"abort-replay"} @click=${t.onAbortReplay} .iconName=${"pause"} .variant=${"outlined"}>
          ${w(b.cancelReplay)}
        </devtools-button>`:t.recorderSettings?u`${Se(Ce,{settings:t.recorderSettings,replayExtensions:t.replayExtensions,onStartReplay:t.onTogglePlaying,disabled:t.replayState.isPlaying})}`:M.nothing}function fo(t){return u`
      <div class="sections">
      ${t.showCodeView?"":u`<div class="section-toolbar">
        <devtools-button
          @click=${t.showCodeToggle}
          class="show-code"
          .data=${{variant:"outlined",title:Y.Tooltip.getTooltipForActions(w(b.showCode),"chrome-recorder.toggle-code-view")}}
          jslog=${R.toggleSubpane("chrome-recorder.toggle-code-view").track({click:!0})}
        >
          ${w(b.showCode)}
        </devtools-button>
      </div>`}
      ${t.sections.map((e,r)=>u`
            <div class="section">
              <div class="screenshot-wrapper">
                ${ho(e)}
              </div>
              <div class="content">
                <div class="steps">
                  ${Se(be,{section:e,state:t.getSectionState(e),isStartOfGroup:!0,isEndOfGroup:e.steps.length===0,isFirstSection:r===0,isLastSection:r===t.sections.length-1&&e.steps.length===0,isSelected:t.selectedStep===(e.causingStep||null),sectionIndex:r,isRecording:t.isRecording,isPlaying:t.replayState.isPlaying,error:t.getSectionState(e)==="error"?t.currentError??void 0:void 0,hasBreakpoint:!1,removable:t.recording.steps.length>1&&!!e.causingStep,onStepClick:t.onStepClick,onStepHover:t.onStepHover,onStepChanged:t.onStepChanged,onAddStep:t.onAddStep,onRemoveStep:t.onRemoveStep,onAddBreakpoint:t.onAddBreakpoint,onRemoveBreakpoint:t.onRemoveBreakpoint,onAttributeRequested:t.onAttributeRequested,onCopyStep:t.onCopyStep})}
                  ${e.steps.map(o=>{let i=t.recording.steps.indexOf(o);return u`
                      <devtools-widget
                      ${Se(be,{step:o,state:t.getStepState(o),error:t.currentStep===o?t.currentError??void 0:void 0,isFirstSection:!1,isLastSection:r===t.sections.length-1&&t.recording.steps[t.recording.steps.length-1]===o,isStartOfGroup:!1,isEndOfGroup:e.steps[e.steps.length-1]===o,stepIndex:i,hasBreakpoint:t.breakpointIndexes.has(i),sectionIndex:-1,isRecording:t.isRecording,isPlaying:t.replayState.isPlaying,removable:t.recording.steps.length>1,builtInConverters:t.builtInConverters,extensionConverters:t.extensionConverters,isSelected:t.selectedStep===o,recorderSettings:t.recorderSettings??void 0,onStepClick:t.onStepClick,onStepHover:t.onStepHover,onCopyStep:t.onCopyStep,onStepChanged:t.onStepChanged,onAddStep:t.onAddStep,onRemoveStep:t.onRemoveStep,onAddBreakpoint:t.onAddBreakpoint,onRemoveBreakpoint:t.onRemoveBreakpoint,onAttributeRequested:t.onAttributeRequested})}
                      jslog=${R.section("step").track({click:!0})}
                      ></devtools-widget>
                    `})}
                  ${!t.recordingTogglingInProgress&&t.isRecording&&r===t.sections.length-1?u`<devtools-button
                    class="step add-assertion-button"
                    .data=${{variant:"outlined",title:w(b.addAssertion),jslogContext:"add-assertion"}}
                    @click=${t.onAddAssertion}
                  >${w(b.addAssertion)}</devtools-button>`:void 0}
                  ${t.isRecording&&r===t.sections.length-1?u`<div class="step recording">${w(b.recording)}</div>`:null}
                </div>
              </div>
            </div>
      `)}
      </div>
    `}function vo(t){if(!t.recording)return M.nothing;let{title:e}=t.recording,r=!t.replayState.isPlaying&&!t.isRecording;return u`
    <div class="header">
      <div class="header-title-wrapper">
        <div class="header-title">
          <input @blur=${t.onTitleBlur}
                @keydown=${t.onTitleInputKeyDown}
                id="title-input"
                jslog=${R.value("title").track({change:!0})}
                class=${M.Directives.classMap({"has-error":t.isTitleInvalid,disabled:!r})}
                .value=${M.Directives.live(e)}
                .disabled=${!r}
                maxlength="300"
                >
          <div class="title-button-bar">
            <devtools-button
              @click=${t.onEditTitleButtonClick}
              .data=${{disabled:!r,variant:"toolbar",iconName:"edit",title:w(b.editTitle),jslogContext:"edit-title"}}
            ></devtools-button>
          </div>
        </div>
        ${t.isTitleInvalid?u`<div class="title-input-error-text">
          ${w(b.requiredTitleError)}
        </div>`:M.nothing}
      </div>
      ${!t.isRecording&&t.replayAllowed?u`<div class="actions">
              <devtools-button
                @click=${t.onMeasurePerformanceClick}
                .data=${{disabled:t.replayState.isPlaying,variant:"outlined",iconName:"performance",title:w(b.performancePanel),jslogContext:"measure-performance"}}
              >
                ${w(b.performancePanel)}
              </devtools-button>
              <div class="separator"></div>
              ${mo(t)}
            </div>`:M.nothing}
    </div>`}var br=(t,e,r)=>{let o={wrapper:!0,"is-recording":t.isRecording,"is-playing":t.replayState.isPlaying,"was-successful":t.lastReplayResult==="Success","was-failure":t.lastReplayResult==="Failure"},i=t.recordingTogglingInProgress?w(b.recordingIsBeingStopped):w(b.endRecording);M.render(u`
    <style>${oe.inspectorCommonStyles}</style>
    <style>${Wt}</style>
    <style>${vr.textInputStyles}</style>
    <div @click=${t.onWrapperClick} class=${M.Directives.classMap(o)}>
      <div class="recording-view main">
        ${vo(t)}
        ${t.extensionDescriptor?u`
            <devtools-widget class="recorder-extension-view" ${Se($e,{descriptor:t.extensionDescriptor,onClose:()=>{r.dispatchEvent(new Event("recorderextensionviewclosed",{bubbles:!0,composed:!0}))}})}>
            </devtools-widget>`:u`
          ${po(t)}
          ${go(t,e)}
        `}
        ${t.isRecording?u`<div class="footer">
          <div class="controls">
            <devtools-widget
              class="control-button"
              ${Se(se,{label:i,shape:"square",disabled:t.recordingTogglingInProgress,onClick:t.onRecordingFinished})}
              jslog=${R.toggle("toggle-recording").track({click:!0})}
              title=${Y.Tooltip.getTooltipForActions(i,"chrome-recorder.start-recording")}
            >
            </devtools-widget>
          </div>
        </div>`:M.nothing}
      </div>
    </div>
  `,r)},xe=class extends oe.Widget.Widget{replayState={isPlaying:!1,isPausedOnBreakpoint:!1};isRecording=!1;recordingTogglingInProgress=!1;recording={title:"",steps:[]};currentStep;currentError;sections=[];settings;lastReplayResult;replayAllowed=!1;breakpointIndexes=new Set;extensionConverters=[];replayExtensions;extensionDescriptor;onPlayRecording;onNetworkConditionsChanged;onTimeoutChanged;onTitleChanged;onAddAssertion;onRecordingFinished;onAbortReplay;onStepChanged;onAddStep;onRemoveStep;onAddBreakpoint;onRemoveBreakpoint;onAttributeRequested;#t;get recorderSettings(){return this.#t}set recorderSettings(e){this.#t=e,this.#l=this.recorderSettings?.preferredCopyFormat??this.#e[0]?.getId(),this.#b()}#e=[];get builtInConverters(){return this.#e}set builtInConverters(e){this.#e=e,this.#l=this.recorderSettings?.preferredCopyFormat??this.#e[0]?.getId(),this.#b()}#o=!1;#i=null;#r=!1;#s=!1;#n="";#l="";#c;#u;#m=this.#U.bind(this);#a;#f={};constructor(e,r){super(e,{useShadowDom:!0}),this.#a=r||br}performUpdate(){let e=[...this.builtInConverters||[],...this.extensionConverters||[]].find(r=>r.getId()===this.#l)??this.builtInConverters[0];this.#a({breakpointIndexes:this.breakpointIndexes,builtInConverters:this.builtInConverters,converterId:this.#l,converterName:e?.getFormatName(),currentError:this.currentError??null,currentStep:this.currentStep??null,editorState:this.#u??null,extensionConverters:this.extensionConverters,extensionDescriptor:this.extensionDescriptor,isRecording:this.isRecording,isTitleInvalid:this.#o,lastReplayResult:this.lastReplayResult??null,recorderSettings:this.#t??null,recording:this.recording,recordingTogglingInProgress:this.recordingTogglingInProgress,replayAllowed:this.replayAllowed,replayExtensions:this.replayExtensions??[],replaySettingsExpanded:this.#r,replayState:this.replayState,sections:this.sections,selectedStep:this.#i??null,settings:this.settings??null,showCodeView:this.#s,onAddAssertion:()=>{this.onAddAssertion?.()},onRecordingFinished:()=>{this.onRecordingFinished?.()},getSectionState:this.#S.bind(this),getStepState:this.#y.bind(this),onAbortReplay:()=>{this.onAbortReplay?.()},onMeasurePerformanceClick:this.#D.bind(this),onTogglePlaying:(r,o)=>{this.onPlayRecording?.({targetPanel:"chrome-recorder",speed:r,extension:o})},onStepChanged:(r,o)=>this.onStepChanged?.(r,o),onAddStep:(r,o)=>this.onAddStep?.(r,o),onRemoveStep:r=>this.onRemoveStep?.(r),onAddBreakpoint:r=>this.onAddBreakpoint?.(r),onRemoveBreakpoint:r=>this.onRemoveBreakpoint?.(r),onAttributeRequested:r=>this.onAttributeRequested?.(r),onCodeFormatChange:this.#L.bind(this),onCopyStep:this.#A.bind(this),onEditTitleButtonClick:this.#M.bind(this),onNetworkConditionsChange:this.#d.bind(this),onReplaySettingsKeydown:this.#T.bind(this),onSelectMenuLabelClick:this.#p.bind(this),onStepClick:this.#R.bind(this),onStepHover:this.#x.bind(this),onTimeoutInput:this.#$.bind(this),onTitleBlur:this.#I.bind(this),onTitleInputKeyDown:this.#P.bind(this),onToggleReplaySettings:this.#k.bind(this),onWrapperClick:this.#E.bind(this),showCodeToggle:this.showCodeToggle.bind(this)},this.#f,this.contentElement)}wasShown(){super.wasShown(),document.addEventListener("copy",this.#m),this.performUpdate()}willHide(){super.willHide(),document.removeEventListener("copy",this.#m)}scrollToBottom(){let e=this.contentElement?.querySelector(".sections");e&&(e.scrollTop=e.scrollHeight)}#y(e){if(!this.currentStep)return"default";if(e===this.currentStep)return this.currentError?"error":this.replayState?.isPlaying?this.replayState?.isPausedOnBreakpoint?"stopped":"current":"success";let r=this.recording.steps.indexOf(this.currentStep);return r===-1?"default":this.recording.steps.indexOf(e)<r?"success":"outstanding"}#S(e){let r=this.currentStep;if(!r)return"default";let o=this.sections.find(n=>n.steps.includes(r));if(!o&&this.currentError)return"error";if(e===o)return"success";let i=this.sections.indexOf(o),s=this.sections.indexOf(e);return i>=s?"success":"outstanding"}#x=e=>{let r="type"in e?e:e.causingStep;!r||this.#i||this.#C(r)};#R(e){let r="type"in e?e:e.causingStep||null;this.#i!==r&&(this.#i=r,this.performUpdate(),r&&this.#C(r,!0))}#E(){this.#i&&(this.#i=null,this.performUpdate())}#T(e){e.key==="Enter"&&(e.preventDefault(),this.#k(e))}#k(e){e.stopPropagation(),this.#r=!this.#r,this.performUpdate()}#d(e){let r=e.target;if(r instanceof HTMLSelectElement){let o=St.find(i=>i.i18nTitleKey===r.value);this.onNetworkConditionsChanged?.(o?.i18nTitleKey===X.NetworkManager.NoThrottlingConditions.i18nTitleKey?void 0:o)}}#$(e){let r=e.target;if(!r.checkValidity()){r.reportValidity();return}this.onTimeoutChanged?.(Number(r.value))}#I=e=>{let o=e.target.value.trim();if(!o){this.#o=!0,this.performUpdate();return}this.onTitleChanged?.(o)};#P=e=>{switch(e.code){case"Escape":case"Enter":e.target.blur(),e.stopPropagation();break}};#M=()=>{let e=this.contentElement.querySelector("#title-input");if(!e)throw new Error("Missing #title-input");e.focus()};#p=e=>{let r=e.target;r.matches(".wrapping-label")&&r.querySelector("devtools-select-menu")?.click()};async#v(e){let r=[...this.builtInConverters,...this.extensionConverters].find(i=>i.getId()===this.recorderSettings?.preferredCopyFormat);if(r||(r=this.builtInConverters[0]),!r)throw new Error("No default converter found");let o="";e?o=await r.stringifyStep(e):this.recording&&([o]=await r.stringify(this.recording)),We.InspectorFrontendHost.InspectorFrontendHostInstance.copyText(o)}#A(e){this.#v(e)}async#U(e){e.target===document.body&&(e.preventDefault(),await this.#v(this.#i),We.userMetrics.keyboardShortcutFired("chrome-recorder.copy-recording-or-step"))}#D(e){e.stopPropagation(),this.onPlayRecording?.({targetPanel:"timeline",speed:"normal"})}showCodeToggle=()=>{this.#s=!this.#s,this.#s?oe.ARIAUtils.LiveAnnouncer.alert(w(b.codeSidebarOpened)):oe.ARIAUtils.LiveAnnouncer.alert(w(b.codeSidebarClosed)),this.#b()};#b=async()=>{if(!this.recording)return;let e=[...this.builtInConverters||[],...this.extensionConverters||[]].find(n=>n.getId()===this.#l)??this.builtInConverters[0];if(!e)return;let[r,o]=await e.stringify(this.recording);this.#n=r,this.#c=o,this.#c?.shift();let i=e.getMediaType(),s=i?await fr.CodeHighlighter.languageFromMIME(i):null;this.#u=we.EditorState.create({doc:this.#n,extensions:[Ge.Config.baseConfiguration(this.#n),we.EditorState.readOnly.of(!0),we.EditorView.lineWrapping,s||[]]}),this.performUpdate(),this.contentElement.dispatchEvent(new Event("code-generated"))};#C=(e,r=!1)=>{if(!this.#c)return;let o=this.recording.steps.indexOf(e);if(o===-1)return;let i=this.#c[o*2],s=this.#c[o*2+1];this.#f.highlightLinesInEditor?.(i,s,r)};#L=e=>{this.#l=e.itemValue,this.recorderSettings&&(this.recorderSettings.preferredCopyFormat=e.itemValue),this.#b()}};var{ref:wo,repeat:Rt}=bo,kt,v={createRecording:"Create recording",importRecording:"Import recording",recordingImported:"Recording imported",deleteRecording:"Delete recording",recordingDeleted:"Recording deleted",noRecordings:"No recordings",numberOfRecordings:"recording(s)",continueReplay:"Continue",stepOverReplay:"Execute one step",exportRecording:"Export recording",startStopRecording:"Start/stop recording",replayRecording:"Replay recording",copyShortcut:"Copy recording or selected step",toggleCode:"Toggle code view",export:"Export",recordingExported:"Recording exported",exportViaExtensions:"Export via extensions",getExtensions:"Get extensions\u2026",sendFeedback:"Send feedback",header:"Nothing recorded yet",recordingDescription:"Use recordings to create automated end-to-end tests or performance traces.",learnMore:"Learn more",doYouTrustThisCode:"Do you trust this recording?",doNotImport:'Don\u2019t import recordings you don\u2019t understand or haven\u2019t reviewed yourself into DevTools. This could allow attackers to steal your identity or take control of your computer. Type "{PH1}" below to allow importing.',allowImporting:"allow importing",typeAllowImporting:'Type "{PH1}"'},So=Tt.i18n.registerUIStrings("panels/recorder/RecorderPanel.ts",v),y=Tt.i18n.getLocalizedString.bind(void 0,So),{widget:$t}=$.Widget,Cr="get-extensions-link",xo="https://goo.gle/recorder-extension-list",Ro="https://developer.chrome.com/docs/devtools/recorder",ko="https://goo.gle/recorder-feedback";function $o(t){if(t.steps.length>4096)throw new Error("Recording with steps over 4096 is not allowed");if(t.title.length>300)throw new Error("Recording with title over 300 characters is not allowed")}var Er=(t,e,r)=>{function o(){switch(t.currentPage){case"StartPage":return s();case"AllRecordingsPage":return i();case"RecordingPage":return n();case"CreateRecordingPage":return l()}}function i(){return Z`
      <devtools-widget
        ${$t(ke,{recordings:t.recordings.map(a=>({storageName:a.storageName,name:a.flow.title})),replayAllowed:t.replayAllowed,onCreateRecording:t.onCreateNewRecording,onDeleteRecording:t.onDeleteRecording,onOpenRecording:t.onRecordingSelected,onPlayRecording:t.onPlayRecordingByName})}
      >
      </devtools-widget>
    `}function s(){return Z`
      <div class="empty-state" jslog=${H.section().context("start-view")}>
        <div class="empty-state-header">${y(v.header)}</div>
        <div class="empty-state-description">
          <span>${y(v.recordingDescription)}</span>
          <devtools-link
            class="devtools-link"
            href=${Ro}
            jslogcontext="learn-more"
          >${y(v.learnMore)}</devtools-link>
        </div>
        <devtools-button .variant=${"tonal"} jslogContext=${"chrome-recorder.create-recording"} @click=${t.onCreateNewRecording}>${y(v.createRecording)}</devtools-button>
      </div>
    `}function n(){return Z`
      <devtools-widget
          class="recording-view"
          ${$t(xe,{recording:t.currentRecording?.flow??{title:"",steps:[]},replayState:t.replayState,isRecording:t.isRecording,recordingTogglingInProgress:t.isToggling,currentStep:t.currentStep,currentError:t.recordingError,sections:t.sections??[],settings:t.settings,recorderSettings:t.recorderSettings,lastReplayResult:t.lastReplayResult,replayAllowed:t.replayAllowed,breakpointIndexes:t.breakpointIndexes,builtInConverters:t.builtInConverters,extensionConverters:t.extensionConverters,replayExtensions:t.replayExtensions,extensionDescriptor:t.extensionDescriptor,onRecordingFinished:t.onRecordingFinished,onAddAssertion:t.handleAddAssertionEvent,onAbortReplay:t.onAbortReplay,onPlayRecording:t.onPlayRecording,onNetworkConditionsChanged:t.onNetworkConditionsChanged,onTimeoutChanged:t.onTimeoutChanged,onTitleChanged:t.handleRecordingTitleChanged,onStepChanged:t.handleRecordingChanged,onAddStep:t.handleStepAdded,onRemoveStep:t.handleStepRemoved,onAddBreakpoint:t.onAddBreakpoint,onRemoveBreakpoint:t.onRemoveBreakpoint,onAttributeRequested:a=>{a(t.currentRecording?.flow.selectorAttribute)}})}
          @recorderextensionviewclosed=${t.onExtensionViewClosed}
          ${$.Widget.widgetRef(xe,a=>{e.recordingView=a})}
        ></devtools-widget>
    `}function l(){return Z`
      <devtools-widget
        class="recording-view"
        ${$t(ce,{recorderSettings:t.recorderSettings,onRecordingStarted:t.onRecordingStarted,onRecordingCancelled:t.onRecordingCancelled})}
        ${$.Widget.widgetRef(ce,a=>{e.createRecordingView=a})}
      ></devtools-widget>
    `}let g=t.currentRecording?t.currentRecording.storageName:t.currentPage,h=[t.recordings.length===0?{value:"StartPage",name:y(v.noRecordings),selected:g==="StartPage"}:{value:"AllRecordingsPage",name:`${t.recordings.length} ${y(v.numberOfRecordings)}`,selected:g==="AllRecordingsPage"},...t.recordings.map(a=>({value:a.storageName,name:a.flow.title,selected:g===a.storageName}))];yo(Z`
        <style>${$.inspectorCommonStyles}</style>
        <style>${Vt}</style>
        <div class="wrapper">
          <div class="header" jslog=${H.toolbar()}>
            <devtools-button
              @click=${t.onCreateNewRecording}
              .data=${{variant:"toolbar",iconName:"plus",disabled:t.replayState.isPlaying||t.isRecording||t.isToggling,title:S.Tooltip.getTooltipForActions(y(v.createRecording),"chrome-recorder.create-recording"),jslogContext:"chrome-recorder.create-recording"}}
            ></devtools-button>
            <div class="separator"></div>
            <select
              .disabled=${t.recordings.length===0||t.replayState.isPlaying||t.isRecording||t.isToggling}
              @click=${a=>a.stopPropagation()}
              @change=${t.onRecordingSelected}
              jslog=${H.dropDown("recordings").track({change:!0})}
            >
              ${Rt(h,a=>a.value,a=>Z`<option .selected=${a.selected} value=${a.value}>${a.name}</option>`)}
            </select>
            <div class="separator"></div>
            <devtools-button
              @click=${t.onImportRecording}
              .data=${{variant:"toolbar",iconName:"import",title:y(v.importRecording),jslogContext:"import-recording"}}
            ></devtools-button>
            <devtools-button
              id='origin'
              @click=${t.onExportRecording}
              ${wo(a=>{a instanceof HTMLElement&&(e.exportMenuButton=a)})}
              .data=${{variant:"toolbar",iconName:"download",title:y(v.exportRecording),disabled:!t.currentRecording}}
              jslog=${H.dropDown("export-recording").track({click:!0})}
            ></devtools-button>
            <devtools-menu
              @menucloserequest=${t.onExportMenuClosed}
              @menuitemselected=${t.onExportOptionSelected}
              .origin=${t.getExportMenuButton}
              .showDivider=${!1}
              .showSelectedItem=${!1}
              .open=${t.exportMenuExpanded}
            >
              <devtools-menu-group .name=${y(v.export)}>
                ${Rt(t.builtInConverters,a=>Z`
                    <devtools-menu-item
                      .value=${a.getId()}
                      jslog=${H.item(`converter-${wr.StringUtilities.toKebabCase(a.getId())}`).track({click:!0})}>
                      ${a.getFormatName()}
                    </devtools-menu-item>
                  `)}
              </devtools-menu-group>
              <devtools-menu-group .name=${y(v.exportViaExtensions)}>
                ${Rt(t.extensionConverters,a=>Z`
                    <devtools-menu-item
                     .value=${a.getId()}
                      jslog=${H.item("converter-extension").track({click:!0})}>
                    ${a.getFormatName()}
                    </devtools-menu-item>
                  `)}
                <devtools-menu-item .value=${Cr}>
                  ${y(v.getExtensions)}
                </devtools-menu-item>
              </devtools-menu-group>
            </devtools-menu>
            <devtools-button
              @click=${t.onDeleteRecording}
              .data=${{variant:"toolbar",iconName:"bin",disabled:!t.currentRecording||t.replayState.isPlaying||t.isRecording||t.isToggling,title:y(v.deleteRecording),jslogContext:"delete-recording"}}
            ></devtools-button>
            <div class="separator"></div>
            <devtools-button
              @click=${t.onContinueReplay}
              .data=${{variant:"primary_toolbar",iconName:"resume",disabled:!t.replayState.isPausedOnBreakpoint,title:y(v.continueReplay),jslogContext:"continue-replay"}}
            ></devtools-button>
            <devtools-button
              @click=${t.onStepOverReplay}
              .data=${{variant:"toolbar",iconName:"step-over",disabled:!t.replayState.isPausedOnBreakpoint,title:y(v.stepOverReplay),jslogContext:"step-over"}}
            ></devtools-button>
            <div class="feedback">
              <devtools-link class="devtools-link" title=${y(v.sendFeedback)} href=${ko} jslogcontext="feedback">${y(v.sendFeedback)}</devtools-link>
            </div>
            <div class="separator"></div>
            <devtools-shortcut-dialog
              .data=${{shortcuts:t.shortcutsInfo}} jslog=${H.action("show-shortcuts").track({click:!0})}
            ></devtools-shortcut-dialog>
          </div>
          ${t.importError?Z`<div class='error'>Import error: ${t.importError.message}</div>`:""}
          ${o()}
        </div>
    `,r,{container:{listeners:{setrecording:t.onSetRecording}}})},Le=class t extends $.Widget.VBox{static panelName="chrome-recorder";static instance(e={}){let{forceNew:r}=e;return(!kt||r)&&(kt=new t),kt}#t;get currentRecordingSession(){return this.#t}set currentRecordingSession(e){this.#t!==e&&(this.#t=e,this.requestUpdate())}#e;get currentRecording(){return this.#e}set currentRecording(e){this.#e!==e&&(this.#e=e,this.requestUpdate())}#o;get currentStep(){return this.#o}set currentStep(e){this.#o!==e&&(this.#o=e,this.requestUpdate())}#i;get recordingError(){return this.#i}set recordingError(e){this.#i!==e&&(this.#i=e,this.requestUpdate())}#r=S.RecordingStorage.RecordingStorage.instance();#s=S.ScreenshotStorage.ScreenshotStorage.instance();#n=!1;get isRecording(){return this.#n}set isRecording(e){this.#n!==e&&(this.#n=e,this.requestUpdate())}#l=!1;get isToggling(){return this.#l}set isToggling(e){this.#l!==e&&(this.#l=e,this.requestUpdate())}#c=!0;#u;get recordingPlayer(){return this.#u}set recordingPlayer(e){this.#u!==e&&(this.#u=e,this.requestUpdate())}#m;get lastReplayResult(){return this.#m}set lastReplayResult(e){this.#m!==e&&(this.#m=e,this.requestUpdate())}#a={isPlaying:!1,isPausedOnBreakpoint:!1};#f="StartPage";get currentPage(){return this.#f}set currentPage(e){this.#f!==e&&(this.#f=e,this.requestUpdate())}#y;get previousPage(){return this.#y}set previousPage(e){this.#y!==e&&(this.#y=e,this.requestUpdate())}#S;#x;get sections(){return this.#x}set sections(e){this.#x!==e&&(this.#x=e,this.requestUpdate())}#R;get settings(){return this.#R}set settings(e){this.#R!==e&&(this.#R=e,this.requestUpdate())}#E;get importError(){return this.#E}set importError(e){this.#E!==e&&(this.#E=e,this.requestUpdate())}#T=!1;get exportMenuExpanded(){return this.#T}set exportMenuExpanded(e){this.#T!==e&&(this.#T=e,this.requestUpdate())}#k;#d=new Set;#$;#I=[];get extensionConverters(){return this.#I}set extensionConverters(e){this.#I!==e&&(this.#I=e,this.requestUpdate())}#P=[];get replayExtensions(){return this.#P}set replayExtensions(e){this.#P!==e&&(this.#P=e,this.requestUpdate())}#M;get viewDescriptor(){return this.#M}set viewDescriptor(e){this.#M!==e&&(this.#M=e,this.requestUpdate())}#p;#v=new S.RecorderSettings.RecorderSettings;#A=new S.RecorderShortcutHelper.RecorderShortcutHelper;#U=ie.Settings.Settings.instance().createSetting("disable-recorder-import-warning",!1,"Synced");#D=ie.Settings.Settings.instance().createSetting("disable-self-xss-warning",!1,"Synced");#b;#C;#L;constructor(e,r){let o=e||document.createElement("devtools-recorder-panel");super(o,{useShadowDom:"pure"}),this.#L=r||Er,this.setHideOnDetach(),this.isRecording=!1,this.isToggling=!1,this.exportMenuExpanded=!1,this.currentPage="StartPage",this.#r.getRecordings().length&&this.#h("AllRecordingsPage");let i=ie.Settings.Settings.instance().moduleSetting("text-editor-indent").get();this.#$=Object.freeze([new q.JSONConverter.JSONConverter(i),new q.PuppeteerReplayConverter.PuppeteerReplayConverter(i),new q.PuppeteerConverter.PuppeteerConverter(i),new q.PuppeteerFirefoxConverter.PuppeteerFirefoxConverter(i),new q.LighthouseConverter.LighthouseConverter(i)]);let s=$r.ExtensionManager.ExtensionManager.instance();this.#O(s.extensions()),s.addEventListener("extensionsUpdated",n=>{this.#O(n.data)})}wasShown(){super.wasShown(),$.Context.Context.instance().setFlavor(t,this),this.requestUpdate(),this.updateComplete.then(()=>{this.focus()})}willHide(){super.willHide(),$.Context.Context.instance().setFlavor(t,null)}onDetach(){super.onDetach(),this.currentRecordingSession&&this.currentRecordingSession.stop(),this.#p&&(Xe.RecorderPluginManager.RecorderPluginManager.instance().removeEventListener("showViewRequested",this.#p),this.#p=void 0)}#O(e){this.extensionConverters=e.filter(r=>r.getCapabilities().includes("export")).map((r,o)=>new q.ExtensionConverter.ExtensionConverter(o,r)),this.replayExtensions=e.filter(r=>r.getCapabilities().includes("replay"))}setIsRecordingStateForTesting(e){this.isRecording=e}setRecordingStateForTesting(e){this.#a.isPlaying=e.isPlaying,this.#a.isPausedOnBreakpoint=e.isPausedOnBreakpoint}setCurrentPageForTesting(e){this.#h(e)}getCurrentPageForTesting(){return this.currentPage}getCurrentRecordingForTesting(){return this.currentRecording}getStepBreakpointIndexesForTesting(){return[...this.#d.values()]}#w(){this.importError=void 0}async#_(e){let r=new ie.StringOutputStream.StringOutputStream,o=new Sr.FileUtils.ChunkedFileReader(e,1e7);if(!await o.read(r))throw o.error()??new Error("Unknown");let s;try{s=S.SchemaUtils.parse(JSON.parse(r.data())),$o(s)}catch(n){this.importError=n;return}this.#g(await this.#r.upsertRecording(s)),this.#h("RecordingPage"),this.#w(),$.ARIAUtils.LiveAnnouncer.alert(y(v.recordingImported))}setCurrentRecordingForTesting(e){this.#g(e)}getSectionsForTesting(){return this.sections}#g(e,r={}){let{keepBreakpoints:o=!1,updateSession:i=!1}=r;this.recordingPlayer?.abort(),this.currentStep=void 0,this.recordingError=void 0,this.lastReplayResult=void 0,this.recordingPlayer=void 0,this.#a.isPlaying=!1,this.#a.isPausedOnBreakpoint=!1,this.#d=o?this.#d:new Set,e?(this.currentRecording=e,this.sections=S.Section.buildSections(e.flow.steps),this.settings=this.#W(e.flow),i&&this.currentRecordingSession&&this.currentRecordingSession.overwriteUserFlow(e.flow)):(this.currentRecording=void 0,this.sections=void 0,this.settings=void 0),this.#F()}#h(e){e!==this.currentPage&&(this.previousPage=this.currentPage,this.currentPage=e)}#W(e){let r=e.steps,o=r.findIndex(s=>s.type==="navigate"),i={timeout:e.timeout};for(let s=o-1;s>=0;s--){let n=r[s];if(!i.viewportSettings&&n.type==="setViewport"&&(i.viewportSettings=n),!i.networkConditionsSettings&&n.type==="emulateNetworkConditions"){i.networkConditionsSettings={...n};for(let l of[F.NetworkManager.OfflineConditions,F.NetworkManager.Slow3GConditions,F.NetworkManager.Slow4GConditions,F.NetworkManager.Fast4GConditions])F.NetworkManager.networkConditionsEqual({...l,title:l.i18nTitleKey||""},{...n,title:l.i18nTitleKey||"",key:`step_${s}_recorder_key`})&&(i.networkConditionsSettings.title=l.title instanceof Function?l.title():l.title,i.networkConditionsSettings.i18nTitleKey=l.i18nTitleKey)}}return i}#N(){let e=F.TargetManager.TargetManager.instance().primaryPageTarget();if(!e)throw new Error("Missing main page target");return e}#G(e){if(!this.sections)return null;for(let r of this.sections)if(r.steps.indexOf(e)!==-1)return r;return null}#F(){if(!this.sections||!this.currentRecording)return;let e=this.currentRecording.storageName;for(let r=0;r<this.sections.length;r++){let o=this.#s.getScreenshotForSection(e,r);this.sections[r].screenshot=o||void 0}this.requestUpdate()}#X(){this.recordingPlayer?.abort()}async#Y(e){if(!this.currentRecording||!this.#c)return;let r=Xe.RecorderPluginManager.RecorderPluginManager.instance();this.#p&&(r.removeEventListener("showViewRequested",this.#p),this.#p=void 0);let o,i=new Promise(n=>{o=n});this.#p=n=>{let l=n.data;l.extensionOrigin===e.getOrigin()&&(this.#p&&(r.removeEventListener("showViewRequested",this.#p),this.#p=void 0),o(l))},r.addEventListener("showViewRequested",this.#p),e.replay(this.currentRecording.flow);let s=await i;this.viewDescriptor=s,k.userMetrics.recordingReplayStarted(k.UserMetrics.RecordingReplayStarted.REPLAY_VIA_EXTENSION)}async#V(e){if(!this.currentRecording||!this.#c)return;if(this.viewDescriptor&&(this.viewDescriptor=void 0),this.#p&&(Xe.RecorderPluginManager.RecorderPluginManager.instance().removeEventListener("showViewRequested",this.#p),this.#p=void 0),e.extension)return await this.#Y(e.extension);k.userMetrics.recordingReplayStarted(e.targetPanel!=="chrome-recorder"?k.UserMetrics.RecordingReplayStarted.REPLAY_WITH_PERFORMANCE_TRACING:k.UserMetrics.RecordingReplayStarted.REPLAY_ONLY),this.#a.isPlaying=!0,this.currentStep=void 0,this.recordingError=void 0,this.lastReplayResult=void 0;let r=this.currentRecording;this.#w(),await this.#q(),this.recordingPlayer=new S.RecordingPlayer.RecordingPlayer(this.currentRecording.flow,{speed:e.speed,breakpointIndexes:this.#d});let o=e.targetPanel==="timeline",i=new Set;this.recordingPlayer.addEventListener("Step",async({data:{step:g,resolve:h}})=>{this.currentStep=g;let a=this.#G(g);if(this.sections&&a&&!i.has(a)){i.add(a);let x=this.sections.indexOf(a),c=await S.ScreenshotUtils.takeScreenshot();a.screenshot=c,S.ScreenshotStorage.ScreenshotStorage.instance().storeScreenshotForSection(r.storageName,x,c)}h()}),this.recordingPlayer.addEventListener("Stop",()=>{this.#a.isPausedOnBreakpoint=!0,this.requestUpdate()}),this.recordingPlayer.addEventListener("Continue",()=>{this.#a.isPausedOnBreakpoint=!1,this.requestUpdate()}),this.recordingPlayer.addEventListener("Error",({data:g})=>{this.recordingError=g,o||(this.#a.isPlaying=!1,this.recordingPlayer=void 0),this.lastReplayResult="Failure";let h=g.message.toLowerCase();h.startsWith("could not find element")?k.userMetrics.recordingReplayFinished(k.UserMetrics.RecordingReplayFinished.TIMEOUT_ERROR_SELECTORS):h.startsWith("waiting for target failed")?k.userMetrics.recordingReplayFinished(k.UserMetrics.RecordingReplayFinished.TIMEOUT_ERROR_TARGET):k.userMetrics.recordingReplayFinished(k.UserMetrics.RecordingReplayFinished.OTHER_ERROR),this.element.dispatchEvent(new pe)}),this.recordingPlayer.addEventListener("Done",()=>{o||(this.#a.isPlaying=!1,this.recordingPlayer=void 0),this.lastReplayResult="Success",this.element.dispatchEvent(new pe),k.userMetrics.recordingReplayFinished(k.UserMetrics.RecordingReplayFinished.SUCCESS)}),this.recordingPlayer.addEventListener("Abort",()=>{this.currentStep=void 0,this.recordingError=void 0,this.lastReplayResult=void 0,this.#a.isPlaying=!1});let s=g=>{},n=new Promise(g=>{s=g}),l=null;switch(e.targetPanel){case"timeline":l=new Rr.PerformanceTracing.PerformanceTracing(this.#N(),{tracingBufferUsage(){},eventsRetrievalProgress(){},tracingComplete(g){s(g)}});break}if(l&&await l.start(),this.#j(!1),await this.recordingPlayer.play(),this.#j(!0),l){await l.stop();let g=await n;if(this.#a.isPlaying=!1,this.recordingPlayer=void 0,await $.InspectorView.InspectorView.instance().showPanel(e.targetPanel),e.targetPanel==="timeline"){let h=new F.TraceObject.TraceObject(g);ie.Revealer.reveal(h)}}}async#q(){try{let e=xr.DeviceModeModel.DeviceModeModel.instance();e.isDeviceModeOn()&&(e.toggleDeviceMode(),await this.#N().model(F.EmulationModel.EmulationModel)?.emulateDevice(null))}catch{}}#j(e){this.#N().model(F.EmulationModel.EmulationModel)?.setTouchEmulationAllowed(e)}async#J(e){let r=JSON.parse(e.detail);this.#g(await this.#r.upsertRecording(S.SchemaUtils.parse(r))),this.#h("RecordingPage"),this.#w(),this.element.dispatchEvent(new Re)}getUserFlow(){return this.currentRecording?.flow}async#Z(e,r){if(!this.currentRecording)throw new Error("Current recording expected to be defined.");let o={...this.currentRecording,flow:{...this.currentRecording.flow,steps:this.currentRecording.flow.steps.map(i=>i===e?r:i)}};this.#g(await this.#r.upsertRecording(o.flow,o.storageName),{keepBreakpoints:!0,updateSession:!0})}async#Q(e,r){if(!this.currentRecording)throw new Error("Current recording expected to be defined.");let o,i=r;if("steps"in e){let h=this.sections?.indexOf(e);if(h===void 0||h===-1)throw new Error("There is no section to add a step to");if(r==="after")this.sections?.[h].steps.length?(o=this.sections?.[h].steps[0],i="before"):(o=this.sections?.[h].causingStep,i="after");else{if(h<=0)throw new Error("There is no section to add a step to");let a=this.sections?.[h-1];o=a?.steps[a.steps.length-1],i="after"}}else o=e;if(!o)throw new Error("Anchor step is not found when adding a step");let s=this.currentRecording.flow.steps,l=s.indexOf(o)+(i==="before"?0:1);s.splice(l,0,{type:S.Schema.StepType.WaitForElement,selectors:["body"]});let g={...this.currentRecording,flow:{...this.currentRecording.flow,steps:s}};this.#d=new Set([...this.#d.values()].map(h=>l>h?h:h+1)),this.#g(await this.#r.upsertRecording(g.flow,g.storageName),{keepBreakpoints:!0,updateSession:!0})}async#ee(e){if(!this.currentRecording)throw new Error("Current recording expected to be defined.");let r={...this.currentRecording.flow,title:e};this.#g(await this.#r.upsertRecording(r,this.currentRecording.storageName))}async#te(e){if(!this.currentRecording)throw new Error("Current recording expected to be defined.");let r=this.currentRecording.flow.steps,o=r.indexOf(e);r.splice(o,1);let i={...this.currentRecording.flow,steps:r};this.#d=new Set([...this.#d.values()].map(s=>o>s?s:o===s?-1:s-1).filter(s=>s>=0)),this.#g(await this.#r.upsertRecording(i,this.currentRecording.storageName),{keepBreakpoints:!0,updateSession:!0})}async#re(e){if(!this.currentRecording)throw new Error("Current recording expected to be defined.");let r=this.currentRecording.flow.steps.findIndex(i=>i.type==="navigate");if(r===-1)throw new Error("Current recording does not have a navigate step");let o=this.currentRecording.flow.steps.findIndex((i,s)=>s>=r?!1:i.type==="emulateNetworkConditions");if(!e)o!==-1&&this.currentRecording.flow.steps.splice(o,1);else if(o===-1)this.currentRecording.flow.steps.splice(0,0,S.SchemaUtils.createEmulateNetworkConditionsStep({download:e.download,upload:e.upload,latency:e.latency}));else{let i=this.currentRecording.flow.steps[o];i.download=e.download,i.upload=e.upload,i.latency=e.latency}this.#g(await this.#r.upsertRecording(this.currentRecording.flow,this.currentRecording.storageName))}async#oe(e){if(!this.currentRecording)throw new Error("Current recording expected to be defined.");this.currentRecording.flow.timeout=e,this.#g(await this.#r.upsertRecording(this.currentRecording.flow,this.currentRecording.storageName))}async#ie(e){let r;if(typeof e=="string")r=e;else{if(e.stopPropagation(),!this.currentRecording)return;r=this.currentRecording.storageName}await this.#r.deleteRecording(r),this.#s.deleteScreenshotsForRecording(r),this.requestUpdate(),$.ARIAUtils.LiveAnnouncer.alert(y(v.recordingDeleted)),(await this.#r.getRecordings()).length?this.#h("AllRecordingsPage"):this.#h("StartPage"),this.#g(void 0),this.#w()}#z(e){e?.stopPropagation(),this.#h("CreateRecordingPage"),this.#w()}async#K(e){await this.#q(),this.isToggling=!0,this.#w(),k.userMetrics.recordingToggled(k.UserMetrics.RecordingToggled.RECORDING_STARTED),this.currentRecordingSession=new S.RecordingSession.RecordingSession(this.#N(),{title:e.name,selectorAttribute:e.selectorAttribute,selectorTypesToRecord:e.selectorTypesToRecord.length?e.selectorTypesToRecord:Object.values(S.Schema.SelectorType)}),this.#g(await this.#r.upsertRecording(this.currentRecordingSession.cloneUserFlow()));let r=-1,o,i=async s=>{if(!this.sections)throw new Error("Could not find sections.");let n=this.sections.length-1,l=this.sections[n];if(o||r===n)return;o=S.ScreenshotUtils.takeScreenshot();let g=await o;o=void 0,l.screenshot=g,S.ScreenshotStorage.ScreenshotStorage.instance().storeScreenshotForSection(s.storageName,n,g),r=n,this.#F()};this.currentRecordingSession.addEventListener("recordingupdated",async({data:s})=>{if(!this.currentRecording)throw new Error("No current recording found");this.#g(await this.#r.upsertRecording(s,this.currentRecording.storageName)),this.#b?.scrollToBottom(),await i(this.currentRecording)}),this.currentRecordingSession.addEventListener("recordingstopped",async({data:s})=>{if(!this.currentRecording)throw new Error("No current recording found");k.userMetrics.keyboardShortcutFired("chrome-recorder.start-recording"),this.#g(await this.#r.upsertRecording(s,this.currentRecording.storageName)),await this.#B()}),await this.currentRecordingSession.start(),this.isToggling=!1,this.isRecording=!0,this.#h("RecordingPage"),this.element.dispatchEvent(new ge(this.currentRecording.flow))}async#B(){if(!this.currentRecording||!this.currentRecordingSession)throw new Error("Recording was never started");this.isToggling=!0,this.#w(),k.userMetrics.recordingToggled(k.UserMetrics.RecordingToggled.RECORDING_FINISHED),await this.currentRecordingSession.stop(),this.currentRecordingSession=void 0,this.isToggling=!1,this.isRecording=!1,this.element.dispatchEvent(new ge(this.currentRecording.flow))}async onRecordingCancelled(){this.previousPage&&this.#h(this.previousPage)}async#H(e){let r;typeof e=="string"?r=e:r=e.target?.value,this.#g(await this.#r.getRecording(r)),this.currentRecording?this.#h("RecordingPage"):r==="StartPage"?this.#h("StartPage"):r==="AllRecordingsPage"&&this.#h("AllRecordingsPage")}async#se(e){if(typeof e.itemValue!="string")throw new Error("Invalid export option value");if(e.itemValue===Cr){k.InspectorFrontendHost.InspectorFrontendHostInstance.openInNewTab(xo);return}if(!this.currentRecording)throw new Error("No recording selected");let r=e.itemValue,o=l=>l.getId()===r,i=this.#$.some(o),s=this.#$.find(o)||this.extensionConverters.find(o);if(!s)throw new Error("No recording selected");let[n]=await s.stringify(this.currentRecording.flow);if(await this.#ne(s.getFilename(this.currentRecording.flow),n),i)$.ARIAUtils.LiveAnnouncer.alert(y(v.recordingExported));else if(s.getId().startsWith(q.ExtensionConverter.EXTENSION_PREFIX))$.ARIAUtils.LiveAnnouncer.alert(y(v.recordingExported));else throw new Error("Could not find a metric for the export option with id = "+r)}async#ne(e,r){try{let i=await(await window.showSaveFilePicker({suggestedName:e})).createWritable();await i.write(r),await i.close()}catch(o){if(o.name==="AbortError")return;throw o}}async#ae(){if(!this.currentRecordingSession||!this.currentRecording)return;let e=this.currentRecordingSession.cloneUserFlow();e.steps.push({type:"waitForElement",selectors:[[".cls"]]}),this.#g(await this.#r.upsertRecording(e,this.currentRecording.storageName),{keepBreakpoints:!0,updateSession:!0}),await this.updateComplete,await this.#b?.updateComplete,this.#b?.contentElement?.querySelector(".section:last-child .step-view-widget:last-of-type")?.shadowRoot?.querySelector(".action")?.click()}async#le(){if(this.#U.get()||Ct.Runtime.Runtime.queryParam("isChromeForTesting")||Ct.Runtime.Runtime.queryParam("disableSelfXssWarnings")||this.#D.get())return!0;let e=await kr.TypeToAllowDialog.TypeToAllowDialog.show({jslogContext:{input:"confirm-import-recording-input",dialog:"confirm-import-recording-dialog"},message:y(v.doNotImport,{PH1:y(v.allowImporting)}),header:y(v.doYouTrustThisCode),typePhrase:y(v.allowImporting),inputPlaceholder:y(v.typeAllowImporting,{PH1:y(v.allowImporting)})});return e&&this.#U.set(!0),e}async#de(e){e.stopPropagation(),this.#w(),await this.#le()&&(this.#S=$.UIUtils.createFileSelectorElement(this.#_.bind(this)),this.#S.click())}async#ce(e){await this.#H(e),await this.#V({targetPanel:"chrome-recorder",speed:this.#v.speed})}#pe=e=>{this.#d=structuredClone(this.#d),this.#d.add(e),this.recordingPlayer?.updateBreakpointIndexes(this.#d),this.requestUpdate()};#ge=e=>{this.#d=structuredClone(this.#d),this.#d.delete(e),this.recordingPlayer?.updateBreakpointIndexes(this.#d),this.requestUpdate()};#ue(){this.viewDescriptor=void 0}handleActions(e){if(this.isActionPossible(e))switch(e){case"chrome-recorder.create-recording":this.#z();return;case"chrome-recorder.start-recording":this.currentPage!=="CreateRecordingPage"&&!this.isRecording?this.#A.handleShortcut(this.#K.bind(this,{name:this.#v.defaultTitle,selectorTypesToRecord:this.#v.defaultSelectors,selectorAttribute:this.#v.selectorAttribute?this.#v.selectorAttribute:void 0})):this.currentPage==="CreateRecordingPage"?this.#C&&this.#A.handleShortcut(()=>{this.#C?.startRecording()}):this.isRecording&&this.#B();return;case"chrome-recorder.replay-recording":this.#V({targetPanel:"chrome-recorder",speed:this.#v.speed});return;case"chrome-recorder.toggle-code-view":{this.#b?.showCodeToggle();return}}}isActionPossible(e){switch(e){case"chrome-recorder.create-recording":return!this.isRecording&&!this.#a.isPlaying;case"chrome-recorder.start-recording":return!this.#a.isPlaying;case"chrome-recorder.replay-recording":return this.currentPage==="RecordingPage"&&!this.#a.isPlaying;case"chrome-recorder.toggle-code-view":return this.currentPage==="RecordingPage";case"chrome-recorder.copy-recording-or-step":return!1}}#he(){let e=r=>$.ShortcutRegistry.ShortcutRegistry.instance().shortcutsForAction(r).map(s=>s.title().split(/[\s+]+/).map(n=>({key:n.trim()})));return[{title:y(v.startStopRecording),rows:e("chrome-recorder.start-recording")},{title:y(v.replayRecording),rows:e("chrome-recorder.replay-recording")},{title:y(v.copyShortcut),rows:k.Platform.isMac()?[[{key:"\u2318"},{key:"C"}]]:[[{key:"Ctrl"},{key:"C"}]]},{title:y(v.toggleCode),rows:e("chrome-recorder.toggle-code-view")}]}#me=()=>{if(!this.#k)throw new Error("#exportMenuButton not found");return this.#k};#fe(e){e.stopPropagation(),this.#w(),this.exportMenuExpanded=!this.exportMenuExpanded}#ve(){this.exportMenuExpanded=!1}performUpdate(){let e=this.#r.getRecordings(),r=this,o={set exportMenuButton(i){r.#k=i},set recordingView(i){r.#b=i},set createRecordingView(i){r.#C=i}};this.#L({recordings:e,currentRecording:this.currentRecording,currentPage:this.currentPage,isRecording:this.isRecording,isToggling:this.isToggling,importError:this.importError,recordingError:this.recordingError,sections:this.sections??[],settings:this.settings,recorderSettings:this.#v,lastReplayResult:this.lastReplayResult,replayAllowed:this.#c,breakpointIndexes:this.#d,builtInConverters:this.#$,extensionConverters:this.extensionConverters,replayExtensions:this.replayExtensions,extensionDescriptor:this.viewDescriptor,exportMenuExpanded:this.exportMenuExpanded,replayState:this.#a,shortcutsInfo:this.#he(),currentStep:this.currentStep,onCreateNewRecording:this.#z.bind(this),onImportRecording:this.#de.bind(this),onExportRecording:this.#fe.bind(this),onDeleteRecording:this.#ie.bind(this),onRecordingSelected:this.#H.bind(this),onPlayRecordingByName:this.#ce.bind(this),onPlayRecording:this.#V.bind(this),onAbortReplay:this.#X.bind(this),onNetworkConditionsChanged:this.#re.bind(this),onTimeoutChanged:this.#oe.bind(this),handleRecordingTitleChanged:this.#ee.bind(this),handleRecordingChanged:this.#Z.bind(this),handleStepAdded:this.#Q.bind(this),handleStepRemoved:this.#te.bind(this),onAddBreakpoint:this.#pe.bind(this),onRemoveBreakpoint:this.#ge.bind(this),onExtensionViewClosed:this.#ue.bind(this),onExportMenuClosed:this.#ve.bind(this),onExportOptionSelected:this.#se.bind(this),onRecordingFinished:this.#B.bind(this),handleAddAssertionEvent:this.#ae.bind(this),onSetRecording:this.#J.bind(this),onContinueReplay:()=>this.recordingPlayer?.continue(),onStepOverReplay:()=>this.recordingPlayer?.stepOver(),getExportMenuButton:this.#me.bind(this),onRecordingStarted:this.#K.bind(this),onRecordingCancelled:this.onRecordingCancelled.bind(this)},o,this.contentElement)}},Et=class{handleAction(e,r){return(async()=>{await $.ViewManager.ViewManager.instance().showView(Le.panelName);let o=$.ViewManager.ViewManager.instance().view(Le.panelName);o&&(await o.widget()).handleActions(r)})(),!0}};export{Ut as ControlButton,Dt as CreateRecordingView,tt as RecorderEvents,Tr as RecorderPanel,zt as RecordingListView,yr as RecordingView,Qt as ReplaySection,sr as SelectorPicker,lr as StepEditor,mr as StepView,ur as TimelineSection};
//# sourceMappingURL=recorder.js.map
