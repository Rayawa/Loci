/** Binary storage units, with a compact display for settings rows. */
export function formatBytes(bytes: number | undefined): string {
  if (bytes === undefined || !Number.isFinite(bytes) || bytes < 0) { return '-'; }
  const units: string[] = ['B', 'KB', 'MB', 'GB', 'TB'];
  let value = bytes; let unit = 0;
  while (value >= 1024 && unit < units.length - 1) { value /= 1024; unit++; }
  // Promote a value that would otherwise round to 1024 of the smaller unit.
  if (unit > 0 && Math.round(value * 10) >= 10240 && unit < units.length - 1) { value /= 1024; unit++; }
  return `${unit === 0 ? Math.floor(value) : Number(value.toFixed(1))} ${units[unit]}`;
}
