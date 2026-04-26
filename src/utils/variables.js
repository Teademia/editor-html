export const CORE_VARIABLES = ['经济', '科技', '文化', '政治'];

export function fixedVariables() {
  return CORE_VARIABLES.map((name) => ({ name, initial: 0, min: 0, max: 10 }));
}

export function isCoreVariable(name) {
  return CORE_VARIABLES.includes(String(name || '').trim());
}

export function coreVariableSets() {
  return CORE_VARIABLES.map((name) => `set {${name}} = 0`).join('\n');
}
