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
 * Returns a UTC Date for 23:59 NZ time, `daysFromNow` days after the current NZ
 * date. Correctly accounts for NZ daylight saving (NZDT +13 / NZST +12) so the
 * result always lands at end-of-day NZ wall-clock time.
 *
 * e.g. created on 01 Jan with daysFromNow = 7 → 08 Jan 23:59 NZ.
 */
export function endOfDayNZ(daysFromNow: number): Date {
  // Read the target NZ calendar date `daysFromNow` days from now.
  const target = new Date(Date.now() + daysFromNow * 24 * 60 * 60 * 1000);
  const parts = new Intl.DateTimeFormat("en-NZ", {
    timeZone: NZ_TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(target);

  const get = (type: string) =>
    parts.find((p) => p.type === type)?.value ?? "00";
  const year = Number(get("year"));
  const month = Number(get("month"));
  const day = Number(get("day"));

  // Tentative UTC instant treating 23:59 NZ wall-clock as if it were UTC.
  const tentative = Date.UTC(year, month - 1, day, 23, 59, 0, 0);

  // Measure NZ's actual offset at that instant and correct for it.
  const offsetMs = nzOffsetMs(new Date(tentative));
  return new Date(tentative - offsetMs);
}

/**
 * Returns NZ's UTC offset in milliseconds at the given instant (+13h during
 * NZDT, +12h during NZST).
 */
function nzOffsetMs(date: Date): number {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: NZ_TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  }).formatToParts(date);

  const get = (type: string) =>
    Number(parts.find((p) => p.type === type)?.value ?? "0");
  // Hour can render as "24" at midnight in some environments; normalise.
  const hour = get("hour") % 24;
  const asUtc = Date.UTC(
    get("year"),
    get("month") - 1,
    get("day"),
    hour,
    get("minute"),
    get("second"),
  );
  return asUtc - date.getTime();
}

/**
 * Returns the given date formatted as "MM-DD-YYYY HH:mm AM/PM" in NZ time.
 */
export function formatNzTime(date: Date): string {
  if (!date || isNaN(date.getTime())) return "";
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
  if (!date || isNaN(date.getTime())) return "";
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
