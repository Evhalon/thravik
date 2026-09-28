var $=Object.defineProperty;var k=(p,t)=>{for(var e in t)$(p,e,{get:t[e],enumerable:!0})};var x={};k(x,{SettingCheckbox:()=>l});import"./../tooltips/tooltips.js";import"./../../kit/kit.js";import*as u from"./../../../core/host/host.js";import*as d from"./../../../core/i18n/i18n.js";import*as n from"./../../lit/lit.js";import*as c from"./../../settings/settings.js";import*as f from"./../../visual_logging/visual_logging.js";import"./../buttons/buttons.js";import*as b from"./../input/input.js";var g=`:host{padding:0;margin:0}input{height:12px;width:12px;min-height:12px;min-width:12px;margin:6px}label{display:inline-flex;align-items:center;overflow:hidden;text-overflow:ellipsis}p{margin:6px 0}.info-icon{cursor:pointer;position:relative;margin-left:var(--sys-size-2);top:var(--sys-size-2);width:var(--sys-size-9);height:var(--sys-size-9)}.link{color:var(--text-link);text-decoration:underline}
/*# sourceURL=${import.meta.resolve("./settingCheckbox.css")} */`;var{html:a}=n,h={learnMore:"Learn more"},L=d.i18n.registerUIStrings("ui/components/settings/SettingCheckbox.ts",h),m=d.i18n.getLocalizedString.bind(void 0,L),l=class extends HTMLElement{#n=this.attachShadow({mode:"open"});#t;#e;#i;#o;set data(t){this.#e&&this.#t&&this.#t.removeChangeListener(this.#e.listener),this.#t=t.setting,this.#i=t.textOverride,this.#o=t.disabled,this.#e=this.#t.addChangeListener(()=>{this.#s()}),this.#s()}icon(){if(!this.#t)return;let e=c.SettingUIRegistration.maybeResolve(this.#t.descriptor())?.learnMore;if(e){let s=`${this.#t.name}-documentation`,i={iconName:"info",variant:"icon",size:"SMALL",jslogContext:s},o=e.url;if(e.tooltip){let r=`${this.#t.name}-information`;return a`
          <devtools-button
            class="info-icon"
            aria-details=${r}
            aria-disabled=true
            accessibleLabel=${e.tooltip()}
            .data=${i}
          ></devtools-button>
          <devtools-tooltip id=${r} variant="rich">
            <span>${e.tooltip()}</span><br />
            ${o?a`<devtools-link
                  href=${o}
                  class="link"
                  .jslogContext=${s}
                  >${m(h.learnMore)}</devtools-link
                >`:n.nothing}
          </devtools-tooltip>
        `}if(o){let r=v=>{u.InspectorFrontendHost.InspectorFrontendHostInstance.openInNewTab(o),v.consume()};return i.iconName="help",i.title=m(h.learnMore),a`<devtools-button
          class="info-icon"
          @click=${r}
          .data=${i}
        ></devtools-button>`}}}get checked(){return this.#t?this.#t.get():!1}#s(){if(!this.#t)throw new Error('No "Setting" object provided for rendering');let t=c.SettingUIRegistration.maybeResolve(this.#t.descriptor()),e=t?.learnMore,s=t?.title??"",i=this.icon(),o=e?.tooltip?.()??"";n.render(a`
      <style>${b.checkboxStyles}</style>
      <style>${g}</style>
      <p>
        <label title=${o}>
          <input
            type="checkbox"
            .checked=${this.checked}
            ?disabled=${this.#o}
            @change=${this.#r}
            jslog=${f.toggle().track({change:!0}).context(this.#t.name)}
            aria-label=${s}
          />
          ${this.#i||s}
        </label>
        ${i}
      </p>`,this.#n,{host:this})}#r(t){this.#t?.set(t.target.checked),this.dispatchEvent(new CustomEvent("change",{bubbles:!0,composed:!1}))}};customElements.define("setting-checkbox",l);export{x as SettingCheckbox};
//# sourceMappingURL=settings.js.map
