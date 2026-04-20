const NZ_TZ = "Pacific/Auckland";

/**
 * Returns the current time formatted as a human-readable NZ string.
 * e.g. "18/03/2026, 11:45 AM"
 */
export function nowNZ(): string {
  return new Date().toLocaleString("en-NZ", {
    timeZone: NZ_TZ,
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    hour12: true,
  });
}

/**
 * Returns the current NZ date as YYMMDD string.
 * Used for order number generation so the date key reflects NZ local date.
 */
export function nzDateKey(): string {
  const parts = new Intl.DateTimeFormat("en-NZ", {
    timeZone: NZ_TZ,
    year: "2-digit",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date());

  const get = (type: string) =>
    parts.find((p) => p.type === type)?.value ?? "00";
  return `${get("year")}${get("month")}${get("day")}`;
}

/**
 * Returns a future Date object representing `minutes` minutes from now in UTC.
 */
export function scheduledAtNZ(minutes: number): Date {
  return new Date(Date.now() + minutes * 60_000);
}

/**
 * Returns the given date formatted as "MM-DD-YYYY HH:mm AM/PM" in NZ time.
 */
export function formatNzTime(date: Date): string {
  const parts = new Intl.DateTimeFormat("en-NZ", {
    timeZone: NZ_TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: true,
  }).formatToParts(date);

  const get = (type: string) =>
    parts.find((p) => p.type === type)?.value ?? "00";
  const period = parts.find((p) => p.type === "dayPeriod")?.value ?? "AM";
  return `${get("day")}-${get("month")}-${get("year")} ${get("hour")}:${get("minute")} ${period}`;
}

/**
 * Returns the given date formatted as "MM-DD-YYYY" in NZ time.
 */
export function formatNzDate(date: Date): string {
  const parts = new Intl.DateTimeFormat("en-NZ", {
    timeZone: NZ_TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(date);

  const get = (type: string) =>
    parts.find((p) => p.type === type)?.value ?? "00";
  return `${get("day")}-${get("month")}-${get("year")}`;
}
