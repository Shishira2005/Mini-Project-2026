// DELETE /api/swap/history
// Clear all swap history (admin only)
router.delete('/history', async (req, res) => {
  try {
    await SwapRequest.deleteMany({});
    res.json({ message: 'All swap history cleared.' });
  } catch (err) {
    console.error('Error in DELETE /api/swap/history', err);
    res.status(500).json({ message: 'Server error' });
  }
});
// Swap room feature: options, requests, history, notifications.
const express = require("express");
const router = express.Router();

const AdminClassroomTimetable = require("../models/AdminClassroomTimetable");
const AdminClassroomSettings = require("../models/AdminClassroomSettings");
const SwapRequest = require("../models/SwapRequest");

// These constants mirror the timing helpers in routes/faculty.js
const MON_THU_PERIODS = [
  { start: "09:30", end: "10:30" },
  { start: "10:30", end: "11:30" },
  { start: "11:30", end: "12:30" },
  { start: "13:30", end: "14:30" },
  { start: "14:30", end: "15:30" },
  { start: "15:30", end: "16:30" },
];

const FRIDAY_PERIODS = [
  { start: "09:30", end: "10:20" },
  { start: "10:20", end: "11:10" },
  { start: "11:10", end: "12:00" },
  { start: "14:00", end: "14:50" },
  { start: "14:50", end: "15:40" },
  { start: "15:40", end: "16:30" },
];

const LUNCH_COLUMN_INDEX = 3; // Same as in routes/faculty.js

// Map timetable weekday index (0-4) and grid period index (including lunch)
// to a concrete time range.
function getTimeRangeForCell(weekdayIndex, periodIndex) {
  if (periodIndex === LUNCH_COLUMN_INDEX) {
    return null;
  }

  const periods = weekdayIndex === 4 ? FRIDAY_PERIODS : MON_THU_PERIODS;
  const logicalIndex =
    periodIndex < LUNCH_COLUMN_INDEX ? periodIndex : periodIndex - 1;

  return periods[logicalIndex] || null;
}

// Convert a calendar date string into the timetable weekday index (0=Mon..4=Fri)
function getTimetableWeekdayIndex(date) {
  const d = new Date(date);
  if (Number.isNaN(d.getTime())) return null;
  const jsDay = d.getDay(); // 0=Sun..6=Sat
  if (jsDay < 1 || jsDay > 5) {
    return null; // Only Mon–Fri are valid timetable days
  }
  return jsDay - 1; // 1->0 (Mon), 5->4 (Fri)
}

// Given a weekday index and start/end time, find the grid period index
function findPeriodIndexForTime(weekdayIndex, startTime, endTime) {
  // There are 7 grid columns including lunch (0..6)
  for (let periodIndex = 0; periodIndex <= 6; periodIndex += 1) {
    const range = getTimeRangeForCell(weekdayIndex, periodIndex);
    if (!range) continue;
    if (range.start === startTime && range.end === endTime) {
      return periodIndex;
    }
  }
  return null;
}

// GET /api/swap/options
// Query swappable classrooms for a given faculty/date/time/projector requirement
router.get("/options", async (req, res) => {
  try {
    const { facultyId, date, startTime, endTime, projectorRequired } =
      req.query;

    if (!facultyId || !date || !startTime || !endTime) {
      return res
        .status(400)
        .json({ message: "Missing required query parameters" });
    }

    const weekdayIndex = getTimetableWeekdayIndex(date);
    if (weekdayIndex === null) {
      return res.json({
        available: false,
        message: "NO SWAPPING AVAILABLE",
      });
    }

    const periodIndex = findPeriodIndexForTime(
      weekdayIndex,
      startTime,
      endTime
    );

    if (periodIndex === null) {
      return res.json({
        available: false,
        message: "NO SWAPPING AVAILABLE",
      });
    }

    const timetables = await AdminClassroomTimetable.find({}).lean();
    const settingsList = await AdminClassroomSettings.find({}).lean();
    const settingsByClassroom = new Map();
    settingsList.forEach((s) => {
      settingsByClassroom.set(s.classroomName, s);
    });

    const candidates = [];
    const requesterEntries = [];

    timetables.forEach((layout) => {
      const classroomName = layout.classroomName;
      if (!classroomName) return;

      // Exclude Seminar Hall and WAD LAB
      const lowerName = classroomName.toLowerCase();
      if (lowerName.includes("seminar hall") || lowerName.includes("wad lab")) {
        return;
      }

      const grid = layout.grid || {};
      const key = `${weekdayIndex}_${periodIndex}`;

      let slotCode;
      if (typeof grid.get === "function") {
        slotCode = grid.get(key);
      } else {
        slotCode = grid[key];
      }

      const rawSlot = (slotCode || "").toString().trim();
      if (!rawSlot) {
        return; // No class scheduled in this room at that time
      }

      // Support multi-slot cells like "D/D1" or "X/Y/Z" by splitting
      // on '/'.
      const slotCodes = rawSlot
        .split("/")
        .map((part) => part.trim())
        .filter((part) => part.length > 0);

      if (slotCodes.length === 0) {
        return;
      }

      const slotDetails = Array.isArray(layout.slotDetails)
        ? layout.slotDetails
        : [];

      let detail = null;

      // If a facultyId is provided, prefer the detail matching that
      // faculty and one of the slot codes in this cell.
      if (facultyId) {
        detail = slotDetails.find((d) => {
          const code = (d.slot || "").toString().trim();
          if (!code || !slotCodes.includes(code)) return false;
          const dFaculty = (d.facultyId || "").toString().trim();
          return dFaculty === facultyId;
        });
      }

      // Fallback: any detail whose slot matches one of the codes.
      if (!detail) {
        detail = slotDetails.find((d) => {
          const code = (d.slot || "").toString().trim();
          return code && slotCodes.includes(code);
        });
      }

      if (!detail) {
        return;
      }

      const settings = settingsByClassroom.get(classroomName);
      const hasProjector = settings ? !!settings.hasProjector : false;
      const capacity = settings ? settings.capacity : null;

      const entry = {
        classroomName,
        courseName: detail.courseName || "",
        facultyId: detail.facultyId || "",
        facultyName: detail.facultyName || "",
        hasProjector,
        capacity,
      };

      if (entry.facultyId === facultyId) {
        requesterEntries.push(entry);
      }

      candidates.push(entry);
    });

    // Faculty must have at least one class in some classroom at this time
    if (requesterEntries.length === 0) {
      return res.json({
        available: false,
        message: "NO SWAPPING AVAILABLE",
      });
    }

    const requesterClassroomNames = new Set(
      requesterEntries.map((e) => e.classroomName)
    );

    const options = candidates
      // Do not offer swapping with any of the faculty's own classrooms; the
      // requester will choose which of their classes is the source.
      .filter((entry) => !requesterClassroomNames.has(entry.classroomName))
      .map((entry) => {
        const projectorOk = projectorRequired === "true" ? entry.hasProjector : true;
        return {
          classroomName: entry.classroomName,
          courseName: entry.courseName,
          facultyId: entry.facultyId,
          facultyName: entry.facultyName,
          hasProjector: entry.hasProjector,
          capacity: entry.capacity,
          colorHint: projectorOk ? "green" : "red",
        };
      });

    // For backward compatibility, keep a single requesterEntry (the first
    // one), but also expose all of the faculty's classes at this period via
    // requesterEntries so the client can let the user choose.
    const primaryRequester = requesterEntries[0] || null;

    res.json({
      available: options.length > 0,
      message: options.length > 0 ? "" : "NO SWAPPING AVAILABLE",
      weekdayIndex,
      periodIndex,
      timeRange: { startTime, endTime },
      requesterEntry: primaryRequester
        ? {
            ...primaryRequester,
            colorHint: "grey",
          }
        : null,
      requesterEntries: requesterEntries.map((entry) => ({
        ...entry,
        colorHint: "grey",
      })),
      options,
    });
  } catch (err) {
    console.error("Error in /api/swap/options", err);
    res.status(500).json({ message: "Server error" });
  }
});

// POST /api/swap/requests
// Create a new swap request
router.post("/requests", async (req, res) => {
  try {
    const {
      date,
      startTime,
      endTime,
      projectorRequired,
      requesterFacultyId,
      requesterFacultyName,
      requesterClassroomName,
      targetClassroomName,
      targetFacultyId,
      targetFacultyName,
      reason,
    } = req.body;

    if (
      !date ||
      !startTime ||
      !endTime ||
      !requesterFacultyId ||
      !requesterFacultyName ||
      !requesterClassroomName ||
      !targetClassroomName ||
      !targetFacultyId ||
      !targetFacultyName ||
      !reason
    ) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    const weekdayIndex = getTimetableWeekdayIndex(date);

    // Disallow creating swap requests for Saturdays and Sundays (or any
    // date that does not map to a valid timetable weekday).
    if (weekdayIndex === null) {
      return res.status(400).json({ message: "NO SWAPPING AVAILABLE" });
    }

    const swap = new SwapRequest({
      date,
      weekdayIndex,
      startTime,
      endTime,
      projectorRequired: !!projectorRequired,
      requesterFacultyId,
      requesterFacultyName,
      requesterClassroomName,
      targetClassroomName,
      targetFacultyId,
      targetFacultyName,
      reason,
    });

    await swap.save();

    res.status(201).json(swap);
  } catch (err) {
    console.error("Error in POST /api/swap/requests", err);
    res.status(500).json({ message: "Server error" });
  }
});

// PATCH /api/swap/requests/:id
// Accept or reject a swap request
router.patch("/requests/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { action } = req.body; // "accept" or "reject" or "cancel"

    const swap = await SwapRequest.findById(id);
    if (!swap) {
      return res.status(404).json({ message: "Swap request not found" });
    }

    if (action === "accept") {
      swap.status = "accepted";
      swap.respondedAt = new Date();

      // When accepted, swap the timetable slots between the two classrooms
      // for the stored weekday and time range so that the classes effectively
      // exchange rooms in the admin timetable.
      const {
        weekdayIndex,
        startTime,
        endTime,
        requesterClassroomName,
        targetClassroomName,
      } = swap;

      const periodIndex = findPeriodIndexForTime(
        weekdayIndex,
        startTime,
        endTime
      );

      if (periodIndex !== null) {
        const key = `${weekdayIndex}_${periodIndex}`;

        const [requesterLayout, targetLayout] = await Promise.all([
          AdminClassroomTimetable.findOne({
            classroomName: requesterClassroomName,
          }),
          AdminClassroomTimetable.findOne({
            classroomName: targetClassroomName,
          }),
        ]);

        if (requesterLayout && targetLayout) {
          const requesterGrid = requesterLayout.grid || {};
          const targetGrid = targetLayout.grid || {};

          let requesterSlot;
          let targetSlot;

          if (typeof requesterGrid.get === "function") {
            requesterSlot = requesterGrid.get(key);
            targetSlot = targetGrid.get(key);
            requesterGrid.set(key, targetSlot);
            targetGrid.set(key, requesterSlot);
          } else {
            requesterSlot = requesterGrid[key];
            targetSlot = targetGrid[key];
            requesterGrid[key] = targetSlot;
            targetGrid[key] = requesterSlot;
          }

          await Promise.all([requesterLayout.save(), targetLayout.save()]);
        }
      }
    } else if (action === "reject") {
      swap.status = "rejected";
      swap.respondedAt = new Date();
    } else if (action === "cancel") {
      swap.status = "cancelled";
      swap.respondedAt = new Date();
    } else {
      return res.status(400).json({ message: "Invalid action" });
    }

    await swap.save();

    res.json(swap);
  } catch (err) {
    console.error("Error in PATCH /api/swap/requests/:id", err);
    res.status(500).json({ message: "Server error" });
  }
});

// GET /api/swap/history
// Swap history for a given faculty (or all for admin)
router.get("/history", async (req, res) => {
  try {
    const { facultyId } = req.query;

    const filter = {};
    if (facultyId) {
      filter.$or = [
        { requesterFacultyId: facultyId },
        { targetFacultyId: facultyId },
      ];
    }

    const history = await SwapRequest.find(filter).sort({ createdAt: -1 });

    res.json({ history });
  } catch (err) {
    console.error("Error in GET /api/swap/history", err);
    res.status(500).json({ message: "Server error" });
  }
});

// GET /api/swap/notifications
// Pending swap requests for a target faculty
router.get("/notifications", async (req, res) => {
  try {
    const { facultyId } = req.query;

    if (!facultyId) {
      return res.status(400).json({ message: "facultyId is required" });
    }

    const notifications = await SwapRequest.find({
      targetFacultyId: facultyId,
      status: "pending",
    }).sort({ createdAt: -1 });

    res.json({ notifications });
  } catch (err) {
    console.error("Error in GET /api/swap/notifications", err);
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;
