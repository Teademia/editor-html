import { CORE_VARIABLES, isCoreVariable } from './variables.js';

function measureIndent(raw) {
  let count = 0;
  for (const ch of raw) {
    if (ch === '\t') count += 4;
    else if (ch === ' ') count += 1;
    else break;
  }
  return Math.floor(count / 4);
}

function parseLine(stripped, indent) {
  if (!stripped || stripped.startsWith('#')) return null;

  // Strip [block_N] markers (used as block-type comments, not valid DTL)
  if (/^\[block_\w+\]$/.test(stripped)) return null;
  if (/^\{[^}]+(?:=|\+=|-=|\*=|\/=)[^}]*\}$/.test(stripped)) return null;
  const bracketNameSetMatch = stripped.match(/^\[([^\]]+)\]\s*(=|\+=|-=|\*=|\/=)\s*(.+)$/);
  if (bracketNameSetMatch) {
    if (!isCoreVariable(bracketNameSetMatch[1])) return null;
    return {
      type: 'set',
      varname: bracketNameSetMatch[1],
      op: bracketNameSetMatch[2],
      value: numericSetValue(bracketNameSetMatch[3]),
      indent,
    };
  }

  const backgroundMatch = stripped.match(/^\[background\s+(.+)\]$/);
  if (backgroundMatch) {
    const params = {};
    for (const match of backgroundMatch[1].matchAll(/([A-Za-z_]\w*)="([^"]*)"/g)) {
      params[match[1]] = match[2];
    }
    return {
      type: 'background',
      arg: params.arg || '',
      scene: params.scene || '',
      fade: params.fade || '0',
      transition: params.transition || '',
      indent,
    };
  }

  if (/^\[[^\]]+(?:=|\+=|-=|\*=|\/=)[^\]]*\]$/.test(stripped) && !stripped.startsWith('[set ')) return null;

  if (stripped.startsWith('label ')) {
    return { type: 'label', name: stripped.slice(6).trim().split(/\s/)[0], indent };
  }

  if (stripped.startsWith('jump ')) {
    const target = stripped.slice(5).trim();
    const splitIndex = target.indexOf('/');
    return splitIndex >= 0
      ? { type: 'jump', timeline: target.slice(0, splitIndex), label: target.slice(splitIndex + 1), indent }
      : { type: 'jump', timeline: '', label: target, indent };
  }

  // Handle [set varname op value] bracketed format → normalize to set event
  const bracketSetMatch = stripped.match(/^\[set\s+\{?([^}=+\-*\/\s\]]+)\}?\s*(=|\+=|-=|\*=|\/=)\s*([^\]]+)\]$/);
  if (bracketSetMatch) {
    if (!isCoreVariable(bracketSetMatch[1])) return null;
    return {
      type: 'set',
      varname: bracketSetMatch[1],
      op: bracketSetMatch[2],
      value: bracketSetMatch[3].trim(),
      indent,
    };
  }

  const setMatch = stripped.match(/^set\s+\{?([^}=+\-*\/\s]+)\}?\s*(=|\+=|-=|\*=|\/=)\s*(.+)$/);
  if (setMatch) {
    if (!isCoreVariable(setMatch[1])) return null;
    return {
      type: 'set',
      varname: setMatch[1],
      op: setMatch[2],
      value: setMatch[3].trim(),
      indent,
    };
  }

  const ifMatch = stripped.match(/^if\s+(.+):$/);
  if (ifMatch) return hasInvalidConditionVariable(ifMatch[1]) ? null : { type: 'if', condition: ifMatch[1], indent };

  const elifMatch = stripped.match(/^elif\s+(.+):$/);
  if (elifMatch) return hasInvalidConditionVariable(elifMatch[1]) ? null : { type: 'elif', condition: elifMatch[1], indent };

  if (stripped === 'else:') return { type: 'else', indent };
  if (stripped === 'end') return { type: 'end', indent };

  if (stripped.startsWith('- ')) {
    const choiceMatch = stripped.match(/^-\s+(.+?)(?:\s*\|\s*\[if\s+(.+?)\])?$/);
    const condition = (choiceMatch && choiceMatch[2] ? choiceMatch[2] : '').trim();
    return {
      type: 'choice',
      text: (choiceMatch ? choiceMatch[1] : stripped.slice(2)).trim(),
      condition: hasInvalidConditionVariable(condition) ? '' : condition,
      indent,
    };
  }

  const base = stripped.startsWith('\\') ? stripped.slice(1) : stripped;
  if (!stripped.startsWith('\\')) {
    const dialogMatch = base.match(/^("?[^":：\n]{1,30}"?)\s*[:：]\s*(.+)$/);
    if (dialogMatch) {
      return {
        type: 'text',
        speaker: dialogMatch[1].trim().replace(/^"|"$/g, ''),
        body: dialogMatch[2].trim(),
        indent,
      };
    }
  }

  return {
    type: 'text',
    speaker: '',
    body: base.replace(/\\:/g, ':'),
    indent,
  };
}

function hasInvalidConditionVariable(condition) {
  for (const name of String(condition || '').matchAll(/\{([^}]+)\}/g)) {
    if (!isCoreVariable(name[1])) return true;
  }
  const withoutStrings = String(condition || '').replace(/(['"]).*?\1/g, '');
  for (const [token] of withoutStrings.matchAll(/[A-Za-z_\u4e00-\u9fa5][\w\u4e00-\u9fa5]*/g)) {
    if (['true', 'false', 'and', 'or', 'not'].includes(token)) continue;
    if (!CORE_VARIABLES.includes(token)) return true;
  }
  return false;
}

function numericSetValue(raw) {
  const value = String(raw || '').trim();
  return /^-?\d+(\.\d+)?$/.test(value) ? value : '0';
}

export function parseDTL(text) {
  const events = [];
  const labelIndex = {};
  const initSets = [];
  let startLabel = '';
  let preLabel = true;

  for (const raw of text.split('\n')) {
    const stripped = raw.trimStart();
    if (!stripped) continue;
    const indent = measureIndent(raw);
    const event = parseLine(stripped, indent);
    if (!event) continue;
    if (preLabel && event.type === 'set') {
      initSets.push(event);
      continue;
    }
    if (event.type === 'label') {
      preLabel = false;
      labelIndex[event.name] = events.length;
      if (!startLabel) startLabel = event.name;
    }
    event.idx = events.length;
    events.push(event);
  }

  return { events, labelIndex, startLabel, initSets };
}

export function evalCond(expr, state) {
  if (!expr) return true;
  const resolved = expr.replace(/\{([^}]+)\}/g, (_, name) => {
    const value = state[name];
    if (typeof value === 'boolean') return value ? 'true' : 'false';
    if (typeof value === 'string') return JSON.stringify(value);
    return value ?? 0;
  });

  try {
    return !!new Function(`return (${resolved})`)();
  } catch {
    return false;
  }
}

export function applySet(event, state) {
  const raw = event.value;
  const value =
    raw === 'true'
      ? true
      : raw === 'false'
        ? false
        : /^-?\d+(\.\d+)?$/.test(raw)
          ? parseFloat(raw)
          : /^["'].*["']$/.test(raw)
            ? raw.slice(1, -1)
            : /^\{([^}]+)\}$/.test(raw)
              ? (state[raw.slice(1, -1)] ?? 0)
              : raw;

  const current = state[event.varname] ?? 0;
  switch (event.op) {
    case '=':
      state[event.varname] = value;
      break;
    case '+=':
      state[event.varname] = current + value;
      break;
    case '-=':
      state[event.varname] = current - value;
      break;
    case '*=':
      state[event.varname] = current * value;
      break;
    case '/=':
      state[event.varname] = current / value;
      break;
  }
}

export function scenesFromDTL(text) {
  const { events, initSets, startLabel } = parseDTL(text);
  const scenes = [];
  let current = null;

  for (const event of events) {
    if (event.type === 'label' && event.indent === 0) {
      if (current) scenes.push(current);
      current = { name: event.name, lines: [], choices: [], end: false, directJump: null };
      continue;
    }
    if (!current) continue;

    if (event.indent === 0) {
      if (event.type === 'text') {
        current.lines.push(event.speaker ? `${event.speaker}: ${event.body}` : event.body);
      } else if (event.type === 'background') {
        const attrs = [
          event.scene ? `scene="${event.scene}"` : '',
          event.arg ? `arg="${event.arg}"` : '',
          event.fade && event.fade !== '0' ? `fade="${event.fade}"` : '',
          event.transition ? `transition="${event.transition}"` : '',
        ].filter(Boolean).join(' ');
        current.lines.push(`[background${attrs ? ` ${attrs}` : ''}]`);
      } else if (event.type === 'set') {
        current.lines.push(`set {${event.varname}} ${event.op} ${event.value}`);
      } else if (event.type === 'choice') {
        current.choices.push({ text: event.text, condition: event.condition, goto: '', actions: [] });
      } else if (event.type === 'jump') {
        current.directJump = event.label;
      } else if (event.type === 'end') {
        current.end = true;
      }
    } else if (event.type === 'jump' && current.choices.length) {
      current.choices[current.choices.length - 1].goto = event.label;
    } else if (event.type === 'set' && current.choices.length) {
      current.choices[current.choices.length - 1].actions.push(event);
    }
  }

  if (current) scenes.push(current);
  return { scenes, initSets, startLabel };
}

export function dtlFromScenes(initSets, scenes) {
  let output = '';
  const fixedInitSets = CORE_VARIABLES.map((name) => ({ varname: name, op: '=', value: 0 }));
  for (const setEvent of fixedInitSets) {
    output += `set {${setEvent.varname}} ${setEvent.op} ${setEvent.value}\n`;
  }
  output += '\n';

  for (const scene of scenes) {
    output += `label ${scene.name}\n`;
    for (const line of scene.lines) {
      const trimmedLine = String(line).trim();
      if (/^\{[^}]+(?:=|\+=|-=|\*=|\/=)[^}]*\}$/.test(trimmedLine)) continue;
      const bracketNameSet = trimmedLine.match(/^\[([^\]]+)\]\s*(=|\+=|-=|\*=|\/=)\s*(.+)$/);
      if (bracketNameSet) {
        if (!isCoreVariable(bracketNameSet[1])) continue;
        output += `set {${bracketNameSet[1]}} ${bracketNameSet[2]} ${numericSetValue(bracketNameSet[3])}\n`;
        continue;
      }
      if (/^\[[^\]]+(?:=|\+=|-=|\*=|\/=)[^\]]*\]$/.test(trimmedLine) && !trimmedLine.startsWith('[set ')) continue;
      const setMatch = trimmedLine.match(/^set\s+\{?([^}=+\-*\/\s]+)\}?\s*(=|\+=|-=|\*=|\/=)\s*(.+)$/);
      if (setMatch && !isCoreVariable(setMatch[1])) continue;
      output += `${line}\n`;
    }
    for (const choice of scene.choices) {
      const condition = hasInvalidConditionVariable(choice.condition) ? '' : choice.condition;
      output += `- ${choice.text}${condition ? ` | [if ${condition}]` : ''}\n`;
      for (const action of choice.actions || []) {
        if (!isCoreVariable(action.varname)) continue;
        output += `\tset {${action.varname}} ${action.op} ${action.value}\n`;
      }
      if (choice.goto) output += `\tjump ${choice.goto}\n`;
    }
    if (!scene.choices.length && scene.directJump) output += `jump ${scene.directJump}\n`;
    if (scene.end) output += 'end\n';
    output += '\n';
  }

  return output.trim();
}
