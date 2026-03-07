// Faculty profile endpoint derived from admin timetable and settings.
const express = require("express");
const AdminClassroomTimetable = require("../models/AdminClassroomTimetable");
const AdminClassroomSettings = require("../models/AdminClassroomSettings");

const router = express.Router();

const DAY_NAMES = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];

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

// Map a grid period index (which includes a lunch column) to a concrete
// time range for a given weekday index.
const getTimeRangeForCell = (weekdayIndex, periodIndex) => {
  if (periodIndex === LUNCH_COLUMN_INDEX) {
    return null; // Lunch break has no teaching slot
  }

  const periods = weekdayIndex === 4 ? FRIDAY_PERIODS : MON_THU_PERIODS;
  const logicalIndex =
    periodIndex < LUNCH_COLUMN_INDEX ? periodIndex : periodIndex - 1;

  return periods[logicalIndex] || null;
};

// GET /api/faculty/:facultyId/profile
// Returns the subjects, timings, classrooms and batch information
// associated with the given faculty ID, based on the admin classroom
// timetable grids and classroom settings.
router.get("/:facultyId/profile", async (req, res) => {
  try {
    const { facultyId } = req.params;
    if (!facultyId) {
      return res.status(400).json({ message: "facultyId is required" });
    }

    // Find all classroom timetables that reference this faculty ID
    const layouts = await AdminClassroomTimetable.find({
      "slotDetails.facultyId": facultyId,
    }).lean();

    if (!layouts || layouts.length === 0) {
      return res.json({
        facultyId,
        facultyName: "",
        entries: [],
      });
    }

    const entries = [];
    let facultyName = "";

    for (const layout of layouts) {
      const classroomName = layout.classroomName;
      const grid = layout.grid || {};
      const slotDetails = Array.isArray(layout.slotDetails)
        ? layout.slotDetails
        : [];

      // Build a lookup of slot code -> slot detail for this faculty
      const slotLookup = new Map();
      for (const detail of slotDetails) {
        if (detail.facultyId !== facultyId) continue;
        const slotCode = (detail.slot || "").toString().trim();
        if (!slotCode) continue;
        if (!slotLookup.has(slotCode)) {
          slotLookup.set(slotCode, detail);
        }
        if (!facultyName && detail.facultyName) {
          facultyName = detail.facultyName;
        }
      }

      if (slotLookup.size === 0) continue;

      // Ensure we can iterate over the grid regardless of whether it is
      // stored as a plain object or a Mongoose Map.
      const gridEntries =
        typeof grid.forEach === "function"
          ? Array.from(grid.entries())
          : Object.entries(grid);

      for (const [key, value] of gridEntries) {
        const slotCode = (value || "").toString().trim();
        if (!slotCode || !slotLookup.has(slotCode)) continue;

        const parts = String(key).split("_");
        if (parts.length !== 2) continue;
        const weekdayIndex = Number(parts[0]);
        const periodIndex = Number(parts[1]);
        if (
          Number.isNaN(weekdayIndex) ||
          Number.isNaN(periodIndex) ||
          weekdayIndex < 0 ||
          weekdayIndex >= DAY_NAMES.length
        ) {
          continue;
        }

        const timeRange = getTimeRangeForCell(weekdayIndex, periodIndex);
        if (!timeRange) continue; // Skip lunch or invalid cells

        const detail = slotLookup.get(slotCode);
        const dayName = DAY_NAMES[weekdayIndex];

        entries.push({
          courseName: detail.courseName || "",
          dayOfWeek: weekdayIndex,
          dayName,
          startTime: timeRange.start,
          endTime: timeRange.end,
          classroomName,
        });
      }
    }

    if (entries.length === 0) {
      return res.json({
        facultyId,
        facultyName,
        entries: [],
      });
    }

    // Attach batch information from classroom settings
    const classroomNames = Array.from(
      new Set(entries.map((e) => e.classroomName))
    );

    const settingsList = await AdminClassroomSettings.find({
      classroomName: { $in: classroomNames },
    })
      .lean()
      .exec();

    const batchByClassroom = new Map();
    for (const settings of settingsList) {
      batchByClassroom.set(
        settings.classroomName,
        settings.batch || ""
      );
    }

    const enrichedEntries = entries.map((entry) => ({
      ...entry,
      batch: batchByClassroom.get(entry.classroomName) || "",
    }));

    // Sort by day (Mon..Fri) then by start time
    enrichedEntries.sort((a, b) => {
      if (a.dayOfWeek !== b.dayOfWeek) {
        return a.dayOfWeek - b.dayOfWeek;
      }
      return a.startTime.localeCompare(b.startTime);
    });

    res.json({
      facultyId,
      facultyName,
      entries: enrichedEntries,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
