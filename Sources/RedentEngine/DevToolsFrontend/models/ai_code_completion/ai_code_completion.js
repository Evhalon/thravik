var g=Object.defineProperty;var h=(a,t)=>{for(var e in t)g(a,e,{get:t[e],enumerable:!0})};function b(){return!!localStorage.getItem("debugAiCodeCompletionEnabled")}function u(...a){b()&&console.log(...a)}function C(a){a?localStorage.setItem("debugAiCodeCompletionEnabled","true"):localStorage.removeItem("debugAiCodeCompletionEnabled")}globalThis.setDebugAiCodeCompletionEnabled=C;var f={};h(f,{AiCodeCompletion:()=>p,consoleAdditionalContextFileContent:()=>v});import*as s from"./../../core/host/host.js";import*as n from"./../../core/root/root.js";var v=`/**
 * This file describes the execution environment of the Chrome DevTools Console.
 * The code is JavaScript, but with special global functions and variables.
 * Top-level await is available.
 * The console has direct access to the inspected page's \`window\` and \`document\`.
 */

/**
 * @description Returns the value of the most recently evaluated expression.
 */
let $_;

/**
 * @description A reference to the most recently selected DOM element.
 * $0, $1, $2, $3, $4 can be used to reference the last five selected DOM elements.
 */
let $0;

/**
 * @description A query selector alias. $$('.my-class') is equivalent to document.querySelectorAll('.my-class').
 */
function $$(selector, startNode) {}

/**
 * @description An XPath selector. $x('//p') returns an array of all <p> elements.
 */
function $x(path, startNode) {}

function clear() {}

function copy(object) {}

/**
 * @description Selects and reveals the specified element in the Elements panel.
 */
function inspect(object) {}

function keys(object) {}

function values(object) {}

/**
 * @description When the specified function is called, the debugger is invoked.
 */
function debug(func) {}

/**
 * @description Stops the debugging of the specified function.
 */
function undebug(func) {}

/**
 * @description Logs a message to the console whenever the specified function is called,
 * along with the arguments passed to it.
 */
function monitor(func) {}

/**
 * @description Stops monitoring the specified function.
 */
function unmonitor(func) {}

/**
 * @description Logs all events dispatched to the specified object to the console.
 */
function monitorEvents(object, events) {}

/**
 * @description Returns an object containing all event listeners registered on the specified object.
 */
function getEventListeners(object) {}

/**
 * The global \`console\` object has several helpful methods
 */
const console = {
  log: (...args) => {},
  warn: (...args) => {},
  error: (...args) => {},
  info: (...args) => {},
  debug: (...args) => {},
  assert: (assertion, ...args) => {},
  dir: (object) => {}, // Displays an interactive property listing of an object.
  dirxml: (object) => {}, // Displays an XML/HTML representation of an object.
  table: (data, columns) => {}, // Displays tabular data as a table.
  group: (label) => {}, // Creates a new inline collapsible group.
  groupEnd: () => {},
  time: (label) => {}, // Starts a timer.
  timeEnd: (label) => {} // Stops a timer and logs the elapsed time.
};`,A=5,_=3,p=class a{#s;#n;#e;#t;#a;#l=crypto.randomUUID();#o;#i;constructor(t,e,o){this.#o=t.aidaClient,this.#i=t.serverSideLoggingEnabled??!1,this.#s=o??[],this.#a=e}#c(t,e,o="JAVASCRIPT",i){let c=s.AidaClient.convertToUserTierEnum(this.#u);function r(l){return typeof l=="number"&&l>=0?l:void 0}t=`
`+t;let d=i;return{client:s.AidaClient.CLIENT_NAME,prefix:t,suffix:e,options:{inference_language:o,temperature:r(this.#r.temperature),model_id:this.#r.modelId||void 0,stop_sequences:this.#s},metadata:{disable_user_content_logging:!(this.#i??!1),string_session_id:this.#l,user_tier:c,client_version:n.Runtime.getChromeVersion()},additional_files:d}}async#d(t){let e=this.#p(t);if(e)return{response:e,fromCache:!0};let o=await this.#o.completeCode(t);return o?(this.#m(t,o),{response:o,fromCache:!1}):{response:null,fromCache:!1}}get#u(){return n.Runtime.hostConfig.devToolsAiCodeCompletion?.userTier}get#r(){let t=n.Runtime.hostConfig.devToolsAiCodeCompletion?.temperature,e=n.Runtime.hostConfig.devToolsAiCodeCompletion?.modelId;return{temperature:t,modelId:e}}#p(t){if(!this.#e||this.#e.request.suffix!==t.suffix||JSON.stringify(this.#e.request.options)!==JSON.stringify(t.options))return null;let e=[];for(let o of this.#e.response.generatedSamples){let i=this.#e.request.prefix+o.generationString;i.startsWith(t.prefix)&&e.push({generationString:i.substring(t.prefix.length),sampleId:o.sampleId,score:o.score,attributionMetadata:o.attributionMetadata})}return e.length===0?null:{generatedSamples:e,metadata:this.#e.response.metadata}}#m(t,e){this.#e={request:t,response:e}}registerUserImpression(t,e,o){let i=Math.floor(e/1e3),c=e%1e3,r=Math.floor(c*1e6);this.#o.registerClientEvent({corresponding_aida_rpc_global_id:t,disable_user_content_logging:!(this.#i??!1),complete_code_client_event:{user_impression:{sample:{sample_id:o},latency:{duration:{seconds:i,nanos:r}}}}}),u("Registered user impression with latency {seconds:",i,", nanos:",r,"}"),s.userMetrics.actionTaken(s.UserMetrics.Action.AiCodeCompletionSuggestionDisplayed)}registerUserAcceptance(t,e){this.#o.registerClientEvent({corresponding_aida_rpc_global_id:t,disable_user_content_logging:!(this.#i??!1),complete_code_client_event:{user_acceptance:{sample:{sample_id:e}}}}),u("Registered user acceptance"),s.userMetrics.actionTaken(s.UserMetrics.Action.AiCodeCompletionSuggestionAccepted)}clearCachedRequest(){this.#e=void 0}async completeCode(t,e,o,i,c){let r=t+e;if(r.length<A)return{response:null,fromCache:!1};if(this.#t&&Math.abs(r.length-this.#t.length)<_)return{response:null,fromCache:!1};let d=this.#c(t,e,i,c),{response:l,fromCache:m}=await this.#d(d);return u("At cursor position",o,{request:d,response:l,fromCache:m}),!l||l.generatedSamples.length===0?(this.#t=r,{response:null,fromCache:!1}):(this.#t=void 0,{response:l,fromCache:m})}remove(){this.#n&&(clearTimeout(this.#n),this.#n=void 0),this.#a?.setAiAutoCompletion(null)}static isAiCodeCompletionAvailable(){return n.Runtime.hostConfig.devToolsAiCodeCompletion?.enabled??!1}static isAiCodeCompletionEnabled(t){if(!t.startsWith("en-"))return!1;let e=n.Runtime.hostConfig.aidaAvailability;return!e||e.blockedByGeo||e.blockedByAge||e.blockedByEnterprisePolicy?!1:!!(e.enabled&&a.isAiCodeCompletionAvailable())}static isAiCodeCompletionStylesAvailable(){return n.Runtime.hostConfig.devToolsAiCodeCompletionStyles?.enabled??!1}static isAiCodeCompletionStylesEnabled(t){if(!t.startsWith("en-"))return!1;let e=n.Runtime.hostConfig.aidaAvailability;return!e||e.blockedByGeo||e.blockedByAge||e.blockedByEnterprisePolicy?!1:!!(e.enabled&&a.isAiCodeCompletionStylesAvailable())}};export{f as AiCodeCompletion,u as debugLog,b as isDebugMode};
//# sourceMappingURL=ai_code_completion.js.map
