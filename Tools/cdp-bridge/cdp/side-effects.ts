// Chrome evaluates what the user is typing — for the preview under the
// prompt and for autocompletion — only when V8 can promise it changes
// nothing. WebKit cannot promise that, so the bridge allows only expressions
// that cannot change anything by their shape: names, literals, property
// reads and operators. No calls, no assignments, no `new`, no `delete`.
// A property getter could still have an effect; V8 runs those too.

const FORBIDDEN_WORDS = new Set([
  "new", "delete", "await", "yield", "function", "class", "import", "async", "var", "let", "const",
  "for", "while", "do", "if", "else", "switch", "try", "catch", "throw", "return", "with", "debugger", "super", "eval",
]);

// Words after which `(` groups rather than calls.
const OPERATOR_WORDS = new Set(["typeof", "void", "in", "instanceof", "of", "case"]);

/** Whether `expression` is safe to run while the user is still typing it. */
export function isSideEffectFree(expression: string): boolean {
  const tokens = tokenize(expression);
  if (!tokens) return false;
  let previous = "";
  for (const token of tokens) {
    if (FORBIDDEN_WORDS.has(token)) return false;
    if (token === "=" || token === "++" || token === "--" || token === "=>") return false;
    if (/^[-+*/%&|^]=$|^(\*\*|<<|>>|>>>|&&|\|\||\?\?)=$/.test(token)) return false;
    if (token === "(" && isCallee(previous)) return false;
    if (token === "`") return false;
    previous = token;
  }
  return true;
}

function isCallee(previous: string): boolean {
  if (!previous) return false;
  if (previous === ")" || previous === "]" || previous === "}" || previous === "\"" || previous === "?.") return true;
  return /^[\w$]+$/.test(previous) && !OPERATOR_WORDS.has(previous);
}

/** Identifiers, numbers, punctuation; string literals collapse to `"`. Null
 *  for anything too odd to judge, such as a template or a regex. */
function tokenize(source: string): string[] | null {
  const tokens: string[] = [];
  let i = 0;
  while (i < source.length) {
    const c = source[i];
    if (/\s/.test(c)) { i++; continue; }
    if (c === "/" && (source[i + 1] === "/" || source[i + 1] === "*")) return null;
    if (c === "'" || c === "\"") {
      const end = closingQuote(source, i);
      if (end < 0) return null;
      tokens.push("\"");
      i = end + 1;
      continue;
    }
    if (c === "`") { tokens.push("`"); i++; continue; }
    const word = /^[\w$]+/.exec(source.slice(i));
    if (word) { tokens.push(word[0]); i += word[0].length; continue; }
    const operator = /^(>>>=|\*\*=|<<=|>>=|&&=|\|\|=|\?\?=|===|!==|>>>|\.\.\.|=>|==|!=|<=|>=|&&|\|\||\?\?|\?\.|\+\+|--|\*\*|<<|>>|[-+*/%&|^]=)/.exec(source.slice(i));
    if (operator) { tokens.push(operator[0]); i += operator[0].length; continue; }
    tokens.push(c);
    i++;
  }
  return tokens;
}

function closingQuote(source: string, start: number): number {
  const quote = source[start];
  for (let i = start + 1; i < source.length; i++) {
    if (source[i] === "\\") { i++; continue; }
    if (source[i] === quote) return i;
    if (source[i] === "\n") return -1;
  }
  return -1;
}
