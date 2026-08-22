/**
 * Parse JSON from LLM text. Models often emit trailing commas, bare keys,
 * or raw newlines inside strings — all of which make JSON.parse throw
 * "Expected double-quoted property name".
 */

function stripFence(raw) {
  const text = String(raw || "").trim().replace(/^\uFEFF/, "");
  const fence = text.indexOf("```");
  if (fence === -1) return text;
  let after = text.slice(fence + 3);
  if (/^json/i.test(after)) after = after.slice(4);
  const end = after.indexOf("```");
  return (end === -1 ? after : after.slice(0, end)).trim();
}

function extractBalancedJson(text) {
  const start = text.search(/[\[{]/);
  if (start < 0) return "";
  const stack = [];
  let inString = false;
  let escape = false;
  for (let i = start; i < text.length; i += 1) {
    const c = text[i];
    if (inString) {
      if (escape) escape = false;
      else if (c === "\\") escape = true;
      else if (c === '"') inString = false;
      continue;
    }
    if (c === '"') {
      inString = true;
      continue;
    }
    if (c === "{" || c === "[") stack.push(c);
    else if (c === "}" || c === "]") {
      const last = stack[stack.length - 1];
      if ((c === "}" && last === "{") || (c === "]" && last === "[")) {
        stack.pop();
        if (stack.length === 0) return text.slice(start, i + 1);
      }
    }
  }
  return text.slice(start);
}

function stripTrailingCommas(s) {
  return s.replace(/,(\s*[}\]])/g, "$1");
}

function quoteBareKeys(s) {
  return s.replace(/([{,]\s*)([A-Za-z_][A-Za-z0-9_]*)(\s*:)/g, '$1"$2"$3');
}

function escapeNewlinesInStrings(s) {
  let out = "";
  let inString = false;
  let escape = false;
  for (const c of s) {
    if (!inString) {
      if (c === '"') inString = true;
      out += c;
      continue;
    }
    if (escape) {
      out += c;
      escape = false;
      continue;
    }
    if (c === "\\") {
      out += c;
      escape = true;
      continue;
    }
    if (c === '"') {
      out += c;
      inString = false;
      continue;
    }
    if (c === "\n") out += "\\n";
    else if (c === "\r") out += "\\r";
    else if (c === "\t") out += "\\t";
    else out += c;
  }
  return out;
}

function parsePosition(message) {
  const m = String(message || "").match(/position (\d+)/i);
  return m ? Number(m[1]) : -1;
}

function parseJsonFromText(text) {
  const payload = stripFence(text);
  const slice = extractBalancedJson(payload);
  if (!slice) throw new Error("No JSON in model output");

  const attempts = [
    slice,
    stripTrailingCommas(slice),
    escapeNewlinesInStrings(slice),
    stripTrailingCommas(escapeNewlinesInStrings(slice)),
    quoteBareKeys(stripTrailingCommas(slice)),
    quoteBareKeys(stripTrailingCommas(escapeNewlinesInStrings(slice))),
  ];

  let lastErr;
  const seen = new Set();
  for (const candidate of attempts) {
    if (seen.has(candidate)) continue;
    seen.add(candidate);
    try {
      return JSON.parse(candidate);
    } catch (e) {
      lastErr = e;
    }
  }

  const msg = lastErr && lastErr.message ? lastErr.message : "Invalid JSON";
  const pos = parsePosition(msg);
  const around =
    pos >= 0
      ? slice.slice(Math.max(0, pos - 80), pos + 80)
      : slice.slice(0, 160);
  console.error("parseJsonFromText failed:", msg, around);
  throw new Error(`${msg} (model JSON)`);
}

module.exports = { parseJsonFromText };
