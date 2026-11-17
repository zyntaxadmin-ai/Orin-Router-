/**
 * SQLite -> Postgres SQL translation for the Supabase build.
 *
 * The app was written against better-sqlite3. Rather than rewrite ~950 query
 * strings, every statement goes through toPg() right before it is sent to
 * Postgres. Timestamps are stored as UTC text ('YYYY-MM-DD HH:MM:SS') so the
 * string comparisons used all over the code keep working unchanged.
 */

import { TABLE_COLUMNS } from './schema-columns.js';

const TS_FMT = `'YYYY-MM-DD HH24:MI:SS'`;
const NOW_UTC = `(now() at time zone 'utc')`;

/** Tables whose primary key is `id BIGSERIAL` (INSERT gets RETURNING id). */
export const SERIAL_TABLES = new Set([
  'api_keys', 'backups', 'client_profiles', 'decision_requests', 'embedding_models',
  'fallback_config', 'idempotency_claims', 'media_models', 'migrations', 'models',
  'playground_conversations', 'profile_models', 'profiles', 'quirk_targets', 'quirks',
  'rate_limit_usage', 'request_attempts', 'requests', 'search_requests', 'url_tokens', 'users',
]);

/** Apply `fn` only to the parts of `sql` that are outside '...' string literals. */
function outsideStrings(sql: string, fn: (chunk: string) => string): string {
  let out = '';
  let i = 0;
  let buf = '';
  while (i < sql.length) {
    const ch = sql[i];
    if (ch === "'") {
      out += fn(buf);
      buf = '';
      let j = i + 1;
      while (j < sql.length) {
        if (sql[j] === "'" && sql[j + 1] === "'") { j += 2; continue; }
        if (sql[j] === "'") break;
        j++;
      }
      out += sql.slice(i, j + 1);
      i = j + 1;
    } else {
      buf += ch;
      i++;
    }
  }
  return out + fn(buf);
}

/** Find the index of the ')' matching the '(' at `open`, skipping string literals. */
function matchParen(s: string, open: number): number {
  let depth = 0;
  for (let i = open; i < s.length; i++) {
    const c = s[i];
    if (c === "'") {
      i++;
      while (i < s.length && !(s[i] === "'" && s[i + 1] !== "'")) { if (s[i] === "'" ) i++; i++; }
      continue;
    }
    if (c === '(') depth++;
    else if (c === ')') { depth--; if (depth === 0) return i; }
  }
  return -1;
}

/** Split `s` on top-level commas. */
function splitTopLevel(s: string): string[] {
  const parts: string[] = [];
  let depth = 0;
  let cur = '';
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (c === "'") {
      let j = i + 1;
      while (j < s.length && !(s[j] === "'" && s[j + 1] !== "'")) { if (s[j] === "'") j++; j++; }
      cur += s.slice(i, j + 1);
      i = j;
      continue;
    }
    if (c === '(') depth++;
    if (c === ')') depth--;
    if (c === ',' && depth === 0) { parts.push(cur); cur = ''; continue; }
    cur += c;
  }
  parts.push(cur);
  return parts;
}

/** SQLite scalar MAX(a,b,..)/MIN(a,b,..) -> GREATEST/LEAST (single-arg stays aggregate). */
function rewriteScalarMinMax(sql: string): string {
  return outsideStrings(sql, (chunk) => {
    let out = chunk;
    const re = /\b(MAX|MIN)\s*\(/gi;
    let m: RegExpExecArray | null;
    let guard = 0;
    while ((m = re.exec(out)) && guard++ < 200) {
      const open = m.index + m[0].length - 1;
      const close = matchParen(out, open);
      if (close < 0) break;
      const inner = out.slice(open + 1, close);
      if (splitTopLevel(inner).length > 1) {
        const fn = m[1].toUpperCase() === 'MAX' ? 'GREATEST' : 'LEAST';
        out = out.slice(0, m.index) + fn + out.slice(open);
        re.lastIndex = m.index + fn.length;
      }
    }
    return out;
  });
}


/** Rewrite every `name(ARGS)` call using fn(ARGS) (paren-aware, outside string literals). */
function rewriteCall(sql: string, name: string, fn: (args: string) => string): string {
  const re = new RegExp(`\\b${name}\\s*\\(`, 'gi');
  let out = sql;
  let m: RegExpExecArray | null;
  let guard = 0;
  while ((m = re.exec(out)) && guard++ < 200) {
    const open = m.index + m[0].length - 1;
    const close = matchParen(out, open);
    if (close < 0) break;
    const replaced = fn(out.slice(open + 1, close));
    out = out.slice(0, m.index) + replaced + out.slice(close + 1);
    re.lastIndex = m.index + replaced.length;
  }
  return out;
}

/** Replace the contents of '...' literals with filler so indices stay aligned but keywords inside strings are invisible. */
function maskStrings(sql: string): string {
  return outsideStringsKeep(sql);
}
function outsideStringsKeep(sql: string): string {
  let out = '';
  let i = 0;
  while (i < sql.length) {
    if (sql[i] === "'") {
      let j = i + 1;
      while (j < sql.length) {
        if (sql[j] === "'" && sql[j + 1] === "'") { j += 2; continue; }
        if (sql[j] === "'") break;
        j++;
      }
      out += "'" + ' '.repeat(Math.max(0, j - i - 1)) + "'";
      i = j + 1;
    } else { out += sql[i]; i++; }
  }
  return out;
}

/**
 * SQLite sorts NULL as the smallest value (first for ASC, last for DESC); Postgres does the
 * opposite. Make every ORDER BY item explicit so ordering matches what the app was written for.
 */
function addNullsOrdering(sql: string): string {
  const masked = maskStrings(sql);
  const edits: { pos: number; text: string }[] = [];
  const re = /\bORDER\s+BY\b/gi;
  let m: RegExpExecArray | null;
  while ((m = re.exec(masked))) {
    const start = m.index + m[0].length;
    let depth = 0;
    let i = start;
    for (; i < masked.length; i++) {
      const c = masked[i];
      if (c === '(') depth++;
      else if (c === ')') { if (depth === 0) break; depth--; }
      else if (depth === 0 && /\s/.test(masked[i - 1] ?? ' ') && /^(LIMIT|OFFSET|FOR\s+UPDATE|UNION|EXCEPT|INTERSECT|RETURNING)\b/i.test(masked.slice(i))) break;
    }
    const clause = masked.slice(start, i);
    // split on top-level commas, remembering absolute offsets
    let d = 0, segStart = 0;
    const segs: [number, number][] = [];
    for (let k = 0; k < clause.length; k++) {
      const c = clause[k];
      if (c === '(') d++;
      else if (c === ')') d--;
      else if (c === ',' && d === 0) { segs.push([segStart, k]); segStart = k + 1; }
    }
    segs.push([segStart, clause.length]);
    for (const [a, b] of segs) {
      const raw = clause.slice(a, b);
      const trimmedEnd = raw.replace(/\s+$/, '').length;
      const item = raw.slice(0, trimmedEnd);
      if (!item.trim()) continue;
      if (/\bNULLS\s+(FIRST|LAST)$/i.test(item)) continue;
      if (/^\s*random\(\)\s*$/i.test(item)) continue;
      const desc = /\bDESC$/i.test(item);
      edits.push({ pos: start + a + trimmedEnd, text: desc ? ' NULLS LAST' : ' NULLS FIRST' });
    }
  }
  edits.sort((x, y) => y.pos - x.pos);
  let out = sql;
  for (const e of edits) out = out.slice(0, e.pos) + e.text + out.slice(e.pos);
  return out;
}

/**
 * Postgres rejects an unqualified column on the right-hand side of ON CONFLICT ... DO UPDATE SET
 * ("column reference is ambiguous": it could be the existing row or `excluded`). SQLite accepts
 * `total = total + 1`. Qualify those references with the target table name.
 */
function qualifyUpsertColumns(sql: string): string {
  const masked = maskStrings(sql);
  const ins = /^\s*INSERT\s+INTO\s+"?(\w+)"?/i.exec(masked);
  if (!ins) return sql;
  const table = ins[1];
  const cols = TABLE_COLUMNS[table];
  if (!cols) return sql;
  const oc = /\bON\s+CONFLICT\b[\s\S]*?\bDO\s+UPDATE\s+SET\b/i.exec(masked);
  if (!oc) return sql;
  const start = oc.index + oc[0].length;

  // find the end (a top-level RETURNING) and a top-level WHERE inside the SET clause
  let end = masked.length;
  let whereAt = -1;
  let depth = 0;
  for (let i = start; i < masked.length; i++) {
    const c = masked[i];
    if (c === '(') depth++;
    else if (c === ')') depth--;
    else if (depth === 0 && /\s/.test(masked[i - 1] ?? ' ')) {
      const rest = masked.slice(i);
      if (/^RETURNING\b/i.test(rest)) { end = i; break; }
      if (whereAt < 0 && /^WHERE\b/i.test(rest)) whereAt = i;
    }
  }
  const setEnd = whereAt >= 0 ? whereAt : end;

  const ranges: [number, number][] = [];
  // each assignment: rhs starts after the first top-level '='
  let segStart = start;
  depth = 0;
  const pushAssignment = (a: number, b: number) => {
    let d = 0;
    for (let i = a; i < b; i++) {
      const c = masked[i];
      if (c === '(') d++;
      else if (c === ')') d--;
      else if (c === '=' && d === 0) { ranges.push([i + 1, b]); return; }
    }
  };
  for (let i = start; i < setEnd; i++) {
    const c = masked[i];
    if (c === '(') depth++;
    else if (c === ')') depth--;
    else if (c === ',' && depth === 0) { pushAssignment(segStart, i); segStart = i + 1; }
  }
  pushAssignment(segStart, setEnd);
  if (whereAt >= 0) ranges.push([whereAt + 5, end]);

  const edits: { pos: number; text: string }[] = [];
  const idRe = /(?<![\w.@:$"])([A-Za-z_][A-Za-z0-9_]*)(?![\w(])(?!\s*\()/g;
  for (const [a, b] of ranges) {
    const chunk = masked.slice(a, b);
    let m: RegExpExecArray | null;
    idRe.lastIndex = 0;
    while ((m = idRe.exec(chunk))) {
      if (cols.has(m[1].toLowerCase())) edits.push({ pos: a + m.index, text: `${table}.` });
    }
  }
  edits.sort((x, y) => y.pos - x.pos);
  let out = sql;
  for (const e of edits) out = out.slice(0, e.pos) + e.text + out.slice(e.pos);
  return out;
}

function rewriteDatesAndFunctions(sql: string): string {
  let s = sql;
  // datetime('now', 'start of month' | 'start of day')
  s = s.replace(/datetime\(\s*'now'\s*,\s*'start of (month|day)'\s*\)/gi,
    (_m, unit) => `to_char(date_trunc('${unit.toLowerCase()}', ${NOW_UTC}), ${TS_FMT})`);
  // datetime('now', '-5 minutes')
  s = s.replace(/datetime\(\s*'now'\s*,\s*'([+-]?\d+)\s*(second|minute|hour|day|month|year)s?'\s*\)/gi,
    (_m, n, unit) => `to_char(${NOW_UTC} + interval '${n} ${unit.toLowerCase()}', ${TS_FMT})`);
  // datetime('now', ?)
  s = s.replace(/datetime\(\s*'now'\s*,\s*\?\s*\)/gi,
    () => `to_char(${NOW_UTC} + (?)::interval, ${TS_FMT})`);
  // datetime('now')
  s = s.replace(/datetime\(\s*'now'\s*\)/gi, () => `to_char(${NOW_UTC}, ${TS_FMT})`);
  // datetime(col)
  s = s.replace(/datetime\(\s*([A-Za-z_][\w.]*)\s*\)/gi, (_m, c) => `to_char((${c})::timestamp, ${TS_FMT})`);
  // date(col) -> 'YYYY-MM-DD' (columns hold 'YYYY-MM-DD HH:MM:SS' text)
  s = s.replace(/\bdate\(\s*([A-Za-z_][\w.]*)\s*\)/gi, (_m, c) => `left(${c}, 10)`);
  // strftime
  s = s.replace(/strftime\(\s*'%Y-%m'\s*,\s*'now'\s*\)/gi, () => `to_char(${NOW_UTC}, 'YYYY-MM')`);
  s = s.replace(/strftime\(\s*'%Y-%m'\s*,\s*([A-Za-z_][\w.]*)\s*\)/gi,
    (_m, c) => `left(${c}, 7)`);
  s = s.replace(/strftime\(\s*'%Y-%m-%dT%H:%M:%SZ'\s*,\s*([A-Za-z_][\w.]*)\s*\)/gi,
    (_m, c) => `to_char((${c})::timestamp, 'YYYY-MM-DD"T"HH24:MI:SS"Z"')`);
  // julianday (used only in differences / comparisons)
  s = s.replace(/julianday\(\s*'now'\s*\)/gi, () => `(extract(epoch from ${NOW_UTC})/86400.0)`);
  s = s.replace(/julianday\(\s*([A-Za-z_][\w.]*)\s*\)/gi,
    (_m, c) => `(extract(epoch from (${c})::timestamp)/86400.0)`);
  // JSON helpers: our JSON columns are TEXT, Postgres wants json for these.
  s = rewriteCall(s, 'json_array_length', (a) => `json_array_length((${a})::json)`);
  s = rewriteCall(s, 'json_group_array', (a) => `(json_agg(${a}))::text`);
  return s;
}

export interface TranslatedSql {
  text: string;
  /** INSERT into a serial table: caller should read `id` from the first row. */
  returnsId: boolean;
  /** Named parameters (@name) in order of appearance; empty for positional SQL. */
  names: string[];
}

const cache = new Map<string, TranslatedSql>();

export function toPg(sqlite: string): TranslatedSql {
  const hit = cache.get(sqlite);
  if (hit) return hit;

  let s = rewriteDatesAndFunctions(sqlite);

  // sqlite_master table existence checks -> information_schema
  s = s.replace(/SELECT\s+name\s+FROM\s+sqlite_master\s+WHERE\s+type\s*=\s*'table'/gi,
    `SELECT table_name AS name FROM information_schema.tables WHERE table_schema = current_schema()`);
  s = s.replace(/(information_schema\.tables WHERE table_schema = current_schema\(\)\s+AND\s+)name\b/gi, '$1table_name');

  let insertIgnore = false;
  s = s.replace(/^\s*INSERT\s+OR\s+IGNORE\s+INTO/i, () => { insertIgnore = true; return 'INSERT INTO'; });

  s = rewriteScalarMinMax(s);
  s = addNullsOrdering(s);

  s = outsideStrings(s, (chunk) => chunk
    .replace(/\bRANDOM\(\)/gi, 'random()')
    .replace(/\browid\b/gi, 'ctid')
    // SQLite's "no limit" idiom; Postgres rejects a negative LIMIT but OFFSET alone is equivalent.
    .replace(/\bLIMIT\s+-1\s+OFFSET\b/gi, 'OFFSET')
    .replace(/(?<![A-Za-z_])LIKE\b/g, 'ILIKE')
    // Postgres folds unquoted aliases to lower case; keep camelCase aliases intact.
    .replace(/\bAS\s+((?=[A-Za-z0-9_]*[a-z])(?=[A-Za-z0-9_]*[A-Z])[A-Za-z_][A-Za-z0-9_]*)\b/g, 'AS "$1"'));

  s = s.trim().replace(/;\s*$/, '');
  if (insertIgnore && !/ON\s+CONFLICT/i.test(s)) s += ' ON CONFLICT DO NOTHING';

  let returnsId = false;
  const ins = /^\s*INSERT\s+INTO\s+"?(\w+)"?/i.exec(s);
  if (ins && SERIAL_TABLES.has(ins[1]) && !/\bRETURNING\b/i.test(s)) {
    s += ' RETURNING id';
    returnsId = true;
  }

  s = qualifyUpsertColumns(s);

  // @name -> ? (remember the order so an object argument can be mapped)
  const names: string[] = [];
  s = outsideStrings(s, (chunk) => chunk.replace(/@([A-Za-z_]\w*)/g, (_m, nm) => { names.push(nm); return '?'; }));

  // ? -> $1, $2 ...
  let n = 0;
  s = outsideStrings(s, (chunk) => chunk.replace(/\?/g, () => `$${++n}`));

  const out = { text: s, returnsId, names };
  cache.set(sqlite, out);
  return out;
}
