// DTL Engine — parsing, evaluation, serialization
// No DOM or storage dependencies. Exposed as window.DTLEngine.

(function (global) {

  function measureIndent(raw) {
    let n = 0;
    for (const ch of raw) {
      if (ch === '\t') n += 4;
      else if (ch === ' ') n += 1;
      else break;
    }
    return Math.floor(n / 4);
  }

  function parseLine(stripped, indent) {
    if (!stripped || stripped.startsWith('#')) return null;

    if (stripped.startsWith('label '))
      return { type: 'label', name: stripped.slice(6).trim().split(/\s/)[0], indent };

    if (stripped.startsWith('jump ')) {
      const t = stripped.slice(5).trim(), s = t.indexOf('/');
      return s >= 0
        ? { type: 'jump', timeline: t.slice(0, s), label: t.slice(s + 1), indent }
        : { type: 'jump', timeline: '', label: t, indent };
    }

    const setM = stripped.match(/^set\s+\{?(\w+)\}?\s*(=|\+=|-=|\*=|\/=)\s*(.+)$/);
    if (setM) return { type: 'set', varname: setM[1], op: setM[2], value: setM[3].trim(), indent };

    const ifM = stripped.match(/^if\s+(.+):$/);
    if (ifM) return { type: 'if', condition: ifM[1], indent };
    const elifM = stripped.match(/^elif\s+(.+):$/);
    if (elifM) return { type: 'elif', condition: elifM[1], indent };
    if (stripped === 'else:') return { type: 'else', indent };
    if (stripped === 'end') return { type: 'end', indent };

    if (stripped.startsWith('- ')) {
      const m = stripped.match(/^-\s+(.+?)(?:\s*\|\s*\[if\s+(.+?)\])?$/);
      return {
        type: 'choice',
        text: (m ? m[1] : stripped.slice(2)).trim(),
        condition: (m && m[2] ? m[2] : '').trim(),
        indent
      };
    }

    const base = stripped.startsWith('\\') ? stripped.slice(1) : stripped;
    if (!stripped.startsWith('\\')) {
      const d = base.match(/^("?[^":：\n]{1,30}"?)\s*[:：]\s*(.+)$/);
      if (d) return { type: 'text', speaker: d[1].trim().replace(/^"|"$/g, ''), body: d[2].trim(), indent };
    }
    return { type: 'text', speaker: '', body: base.replace(/\\:/g, ':'), indent };
  }

  function parseDTL(text) {
    const events = [], labelIndex = {}, initSets = [];
    let startLabel = '', preLabel = true;
    for (const raw of text.split('\n')) {
      const stripped = raw.trimStart();
      if (!stripped) continue;
      const indent = measureIndent(raw);
      const ev = parseLine(stripped, indent);
      if (!ev) continue;
      if (preLabel && ev.type === 'set') { initSets.push(ev); continue; }
      if (ev.type === 'label') { preLabel = false; labelIndex[ev.name] = events.length; if (!startLabel) startLabel = ev.name; }
      ev.idx = events.length;
      events.push(ev);
    }
    return { events, labelIndex, startLabel, initSets };
  }

  function evalCond(expr, state) {
    if (!expr) return true;
    const resolved = expr.replace(/\{(\w+)\}/g, (_, n) => {
      const v = state[n];
      return typeof v === 'boolean' ? (v ? 'true' : 'false') : typeof v === 'string' ? JSON.stringify(v) : (v ?? 0);
    });
    try { return !!new Function('return (' + resolved + ')')(); } catch { return false; }
  }

  function applySet(ev, state) {
    const raw = ev.value;
    let val = raw === 'true' ? true : raw === 'false' ? false
      : /^-?\d+(\.\d+)?$/.test(raw) ? parseFloat(raw)
      : /^["'].*["']$/.test(raw) ? raw.slice(1, -1)
      : /^\{(\w+)\}$/.test(raw) ? (state[raw.slice(1, -1)] ?? 0) : raw;
    const cur = state[ev.varname] ?? 0;
    switch (ev.op) {
      case '=':  state[ev.varname] = val; break;
      case '+=': state[ev.varname] = cur + val; break;
      case '-=': state[ev.varname] = cur - val; break;
      case '*=': state[ev.varname] = cur * val; break;
      case '/=': state[ev.varname] = cur / val; break;
    }
  }

  // Parse DTL text into an array of scene objects for the editor
  function scenesFromDTL(text) {
    const { events, initSets, startLabel } = parseDTL(text);
    const scenes = [];
    let cur = null;
    for (const ev of events) {
      if (ev.type === 'label' && ev.indent === 0) {
        if (cur) scenes.push(cur);
        cur = { name: ev.name, lines: [], choices: [], end: false, directJump: null };
        continue;
      }
      if (!cur) continue;
      if (ev.indent === 0) {
        if (ev.type === 'text')   cur.lines.push(ev.speaker ? `${ev.speaker}: ${ev.body}` : ev.body);
        else if (ev.type === 'set')    cur.lines.push(`set {${ev.varname}} ${ev.op} ${ev.value}`);
        else if (ev.type === 'choice') cur.choices.push({ text: ev.text, condition: ev.condition, goto: '', actions: [] });
        else if (ev.type === 'jump')   cur.directJump = ev.label;
        else if (ev.type === 'end')    cur.end = true;
      } else {
        if (ev.type === 'jump' && cur.choices.length)
          cur.choices[cur.choices.length - 1].goto = ev.label;
        else if (ev.type === 'set' && cur.choices.length)
          cur.choices[cur.choices.length - 1].actions.push(ev);
      }
    }
    if (cur) scenes.push(cur);
    return { scenes, initSets, startLabel };
  }

  // Serialize scene objects back to DTL text
  function dtlFromScenes(initSets, scenes) {
    let out = '';
    for (const s of initSets) out += `set {${s.varname}} ${s.op} ${s.value}\n`;
    if (initSets.length) out += '\n';
    for (const sc of scenes) {
      out += `label ${sc.name}\n`;
      for (const l of sc.lines) out += l + '\n';
      for (const ch of sc.choices) {
        out += `- ${ch.text}${ch.condition ? ` | [if ${ch.condition}]` : ''}\n`;
        for (const act of (ch.actions || [])) out += `\tset {${act.varname}} ${act.op} ${act.value}\n`;
        if (ch.goto) out += `\tjump ${ch.goto}\n`;
      }
      if (!sc.choices.length && sc.directJump) out += `jump ${sc.directJump}\n`;
      if (sc.end) out += 'end\n';
      out += '\n';
    }
    return out.trim();
  }

  global.DTLEngine = { parseDTL, evalCond, applySet, scenesFromDTL, dtlFromScenes };

})(window);
