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
