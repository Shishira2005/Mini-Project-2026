// Helper functions for working with times and dates.
// Used across booking, timetable, and swap logic.

// Convert a HH:mm time string into the number of minutes since midnight.
const toMinutes = (time) => {
  const [hours, minutes] = String(time).split(":").map(Number);
  if (
    Number.isNaN(hours) ||
    Number.isNaN(minutes) ||
    hours < 0 ||
    hours > 23 ||
    minutes < 0 ||
    minutes > 59
  ) {
    throw new Error(`Invalid time format: ${time}. Use HH:mm`);
  }
  return hours * 60 + minutes;
};

// Return true when two [start, end) time intervals overlap.
const intervalsOverlap = (startA, endA, startB, endB) => {
  const aStart = toMinutes(startA);
  const aEnd = toMinutes(endA);
  const bStart = toMinutes(startB);
  const bEnd = toMinutes(endB);

  if (aStart >= aEnd || bStart >= bEnd) {
    throw new Error("Start time must be before end time");
  }

  return aStart < bEnd && bStart < aEnd;
};

// Normalize any input date to a Date object that represents
// midnight (00:00:00) of that same calendar day.
const toDateOnly = (inputDate) => {
  const date = new Date(inputDate);
  if (Number.isNaN(date.getTime())) {
    throw new Error("Invalid date. Use YYYY-MM-DD");
  }
  date.setHours(0, 0, 0, 0);
  return date;
};

module.exports = {
  intervalsOverlap,
  toDateOnly,
  toMinutes,
};
