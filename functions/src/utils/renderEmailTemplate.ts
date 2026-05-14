export function renderTemplate(
  content: string,
  variables: Record<string, string | number | boolean>,
): string {
  return content.replace(/\{\{\s*(\w+)\s*\}\}/g, (_, key) =>
    String(variables[key] ?? `{{ ${key} }}`),
  );
}
