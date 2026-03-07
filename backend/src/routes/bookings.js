const express = require("express");

const Booking = require("../models/Booking");
const Classroom = require("../models/Classroom");
const TimetableEntry = require("../models/TimetableEntry");
const AdminClassroomTimetable = require("../models/AdminClassroomTimetable");
const AdminClassroomSettings = require("../models/AdminClassroomSettings");
const { intervalsOverlap, toDateOnly, toMinutes } = require("../utils/time");

const router = express.Router();

// Automatically mark past bookings (whose end time has already passed)
// as "completed" so that they no longer block future availability and
// appear clearly as completed entries in booking history.
const autoCompletePastBookings = async () => {
  const now = new Date();

  const today = new Date(now);
  today.setHours(0, 0, 0, 0);

  // 1) Any booking with date strictly before today is definitely completed.
  await Booking.updateMany(
    {
      status: { $in: ["pending", "approved"] },
      date: { $lt: today },
    },
    { status: "completed" }
  );

  // 2) For today's bookings, mark those whose end time has passed.
  const nowMinutes = now.getHours() * 60 + now.getMinutes();

  const todayBookings = await Booking.find({
    status: { $in: ["pending", "approved"] },
    date: today,
  });

  const toCompleteIds = todayBookings
    .filter((b) => {
      try {
        return toMinutes(b.endTime) <= nowMinutes;
      } catch (e) {
        // If endTime is invalid, do not auto-complete.
        return false;
      }
    })
    .map((b) => b._id);

  if (toCompleteIds.length > 0) {
    await Booking.updateMany(
      { _id: { $in: toCompleteIds } },
      { status: "completed" }
    );
  }
};

// Treat weekly grid break markers (R/T/RMH) as bookable slots so ground-floor
// rooms stay available during those periods. We strip non-letters so variants
// like "R & T", "R/T" or "RT" are all treated the same.
const isBreakSlot = (subject) => {
  const normalized = String(subject || "")
    .toUpperCase()
    .replace(/[^A-Z]/g, "");

  if (!normalized) return false;
  if (normalized.includes("RMH")) return true;

  return normalized === "R" || normalized === "T" || normalized === "RT" || normalized === "TR";
};
// Weekday index in admin grid: 0 = Monday, 4 = Friday.
const getGridWeekdayIndex = (date) => {
  const jsDay = date.getDay(); // 0 = Sunday, 1 = Monday ... 6 = Saturday
  if (jsDay === 0 || jsDay === 6) {
    return null; // No weekly grid configured for Sunday/Saturday
  }
  return jsDay - 1; // Monday -> 0
};

// Period timings as used in the admin weekly timetable grid (Mon–Thu).
const MON_THU_PERIODS = [
  { start: "09:30", end: "10:30" },
  { start: "10:30", end: "11:30" },
  { start: "11:30", end: "12:30" },
  { start: "13:30", end: "14:30" },
  { start: "14:30", end: "15:30" },
  { start: "15:30", end: "16:30" },
];

// Friday has a different pattern.
const FRIDAY_PERIODS = [
  { start: "09:30", end: "10:20" },
  { start: "10:20", end: "11:10" },
  { start: "11:10", end: "12:00" },
  { start: "14:00", end: "14:50" },
  { start: "14:50", end: "15:40" },
  { start: "15:40", end: "16:30" },
];

const LUNCH_COLUMN_INDEX = 3; // Matches classroom_timetable_page.dart

// Given a weekday index (0–4) and a time range, find the corresponding
// period index used in the weekly grid keys (day_period).
const getGridPeriodIndex = (weekdayIndex, startTime, endTime) => {
  const periods = weekdayIndex === 4 ? FRIDAY_PERIODS : MON_THU_PERIODS;
  const idx = periods.findIndex(
    (p) => p.start === startTime && p.end === endTime
  );
  if (idx === -1) return null;

  // Grid has a separate LUNCH column at index 3; periods after lunch are
  // shifted by +1 compared to the timing arrays.
  return idx < LUNCH_COLUMN_INDEX ? idx : idx + 1;
};

// Map backend Classroom roomNumber/name to the admin timetable classroomName
// used in AdminClassroomTimetable/AdminClassroomSettings.
const toAdminClassroomName = (room) => {
  const base = String(room.roomNumber || room.name || "").toUpperCase();

  switch (base) {
    case "C-101":
      return "CS001";
    case "C-102":
      return "CS003";
    case "C-201":
      return "WAD LAB";
    case "SH-1":
      return "SEMINAR HALL";
    default:
      return base;
  }
};

// Look up the weekly timetable grid marker (e.g. "R" / "T") for a given
// room and time slot. Returns null if there is no grid cell.
const getGridMarkerForRoomSlot = async ({ room, date, startTime, endTime }) => {
  const weekdayIndex = getGridWeekdayIndex(date);
  if (weekdayIndex === null) return null;

  const periodIndex = getGridPeriodIndex(weekdayIndex, startTime, endTime);
  if (periodIndex === null) return null;

  const classroomName = toAdminClassroomName(room);
  if (!classroomName) return null;

  const layout = await AdminClassroomTimetable.findOne({ classroomName });
  if (!layout || !layout.grid) return null;

  const key = `${weekdayIndex}_${periodIndex}`;

  // Mongoose Map supports .get; fall back to index access if needed.
  const value =
    (typeof layout.grid.get === "function" && layout.grid.get(key)) ||
    layout.grid[key];

  return value || null;
};

const roomHasConflict = async ({ room, roomId, date, startTime, endTime }) => {
  const classroom =
    room || (await Classroom.findById(roomId).exec());

  if (!classroom) {
    return {
      hasConflict: true,
      reason: "Room not found",
    };
  }

  const dayOfWeek = date.getDay();

  // First, consult the weekly timetable grid.
  // - If the cell contains an R/T-style marker, treat this period as a
  //   break and skip fixed timetable conflicts (but still respect
  //   existing bookings).
  // - If the cell has any other non-empty value (e.g. regular slot like
  //   "A", "C", etc.), treat it as *busy* even if there is no
  //   TimetableEntry row.
  let skipTimetableConflict = false;
  try {
    const gridMarker = await getGridMarkerForRoomSlot({
      room: classroom,
      date,
      startTime,
      endTime,
    });
    if (isBreakSlot(gridMarker)) {
      skipTimetableConflict = true;
    } else if (typeof gridMarker === "string" && gridMarker.trim() !== "") {
      return {
        hasConflict: true,
        reason: "Time slot occupied in weekly timetable grid",
      };
    }
  } catch (e) {
    // Fail open: if grid lookup fails, fall back to timetable entries.
  }

  if (!skipTimetableConflict) {
    const timetableEntries = await TimetableEntry.find({
      classroom: classroom._id,
      dayOfWeek,
    });

    // Ignore RMH/R/T periods when checking timetable conflicts so that
    // rooms remain bookable during those markers.
    const effectiveTimetableEntries = timetableEntries.filter(
      (entry) => !isBreakSlot(entry.subject)
    );

    const timetableConflict = effectiveTimetableEntries.some((entry) =>
      intervalsOverlap(startTime, endTime, entry.startTime, entry.endTime)
    );

    if (timetableConflict) {
      return {
        hasConflict: true,
        reason: "Time slot conflicts with fixed class timetable",
      };
    }
  }

  const existingBookings = await Booking.find({
    room: classroom._id,
    date,
    status: { $in: ["pending", "approved"] },
  });

  const bookingConflict = existingBookings.some((entry) =>
    intervalsOverlap(startTime, endTime, entry.startTime, entry.endTime)
  );

  if (bookingConflict) {
    return {
      hasConflict: true,
      reason: "Time slot conflicts with an existing booking",
    };
  }

  return { hasConflict: false };
};

// Ensure Classroom documents exist for all admin-configured classrooms so that
// availability checks and bookings work even if settings were saved before
// the sync logic was introduced.
const syncClassroomsFromAdminSettings = async () => {
  const settingsList = await AdminClassroomSettings.find({});

  const ops = settingsList.map((settings) => {
    const classroomName = settings.classroomName;
    const upperName = classroomName.toUpperCase();
    const isSeminarOrLab =
      upperName.includes("SEMINAR HALL") || upperName.includes("WAD LAB");

    return Classroom.findOneAndUpdate(
      { roomNumber: classroomName },
      {
        roomNumber: classroomName,
        name: classroomName,
        type: isSeminarOrLab ? "seminar_hall" : "classroom",
        capacity: settings.capacity,
        hasProjector: settings.hasProjector,
      },
      { new: true, upsert: true }
    ).exec();
  });

  await Promise.all(ops);
};

router.get("/availability", async (req, res) => {
  try {
    // Ensure any past bookings are marked as completed so they no longer
    // block availability checks.
    await autoCompletePastBookings();
    const { date, startTime, endTime, minCapacity, projector, type } = req.query;

    if (!date || !startTime || !endTime) {
      return res
        .status(400)
        .json({ message: "date, startTime and endTime are required" });
    }

    if (toMinutes(startTime) >= toMinutes(endTime)) {
      return res.status(400).json({ message: "startTime must be before endTime" });
    }

    const bookingDate = toDateOnly(date);
    const roomFilters = {};

    if (minCapacity !== undefined) {
      roomFilters.capacity = { $gte: Number(minCapacity) };
    }
    if (projector !== undefined) {
      roomFilters.hasProjector = projector === "true";
    }
    if (type) {
      roomFilters.type = type;
    }

    // Ensure Classroom collection is in sync with admin settings
    // (CS001, CS003, CS007, CS008, CS010, etc.).
    await syncClassroomsFromAdminSettings();

    const rooms = await Classroom.find(roomFilters);

    const availability = [];
    for (const room of rooms) {
      const conflict = await roomHasConflict({
        room,
        roomId: room._id,
        date: bookingDate,
        startTime,
        endTime,
      });

      availability.push({
        room,
        available: !conflict.hasConflict,
        reason: conflict.reason || null,
      });
    }

    res.json(availability);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

router.get("/", async (req, res) => {
  try {
    // Keep booking history up to date before returning it.
    await autoCompletePastBookings();

    const bookings = await Booking.find()
      .populate("room")
      .sort({ date: 1, startTime: 1 });
    res.json(bookings);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.post("/", async (req, res) => {
  try {
    // Update any past bookings first so they don't interfere
    // with conflict detection for new bookings.
    await autoCompletePastBookings();
    const { room, date, startTime, endTime } = req.body;

    if (!room || !date || !startTime || !endTime) {
      return res
        .status(400)
        .json({ message: "room, date, startTime and endTime are required" });
    }

    if (toMinutes(startTime) >= toMinutes(endTime)) {
      return res.status(400).json({ message: "startTime must be before endTime" });
    }

    const classroom = await Classroom.findById(room);
    if (!classroom) {
      return res.status(404).json({ message: "Room not found" });
    }

    const bookingDate = toDateOnly(date);
    const conflict = await roomHasConflict({
      room: classroom,
      roomId: classroom._id,
      date: bookingDate,
      startTime,
      endTime,
    });

    if (conflict.hasConflict) {
      return res.status(409).json({ message: conflict.reason });
    }

    const booking = await Booking.create({
      ...req.body,
      date: bookingDate,
    });

    res.status(201).json(booking);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

router.patch("/:id/status", async (req, res) => {
  try {
    const { status } = req.body;
    if (!["pending", "approved", "rejected", "cancelled", "completed"].includes(status)) {
      return res.status(400).json({ message: "Invalid status" });
    }

    const booking = await Booking.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true }
    );

    if (!booking) {
      return res.status(404).json({ message: "Booking not found" });
    }

    res.json(booking);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

router.delete("/", async (req, res) => {
  try {
    await Booking.deleteMany({});
    res.json({ message: "All bookings cleared" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
