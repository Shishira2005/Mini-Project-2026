const express = require("express");
const TimetableEntry = require("../models/TimetableEntry");
const AdminClassroomTimetable = require("../models/AdminClassroomTimetable");
const UserAccount = require("../models/UserAccount");
const { hashPassword } = require("../utils/auth");

const router = express.Router();

// Create faculty user accounts for any faculty IDs present in the
// slotDetails table for a classroom timetable. This is invoked whenever
// an admin saves the timetable layout for a classroom.
const ensureFacultyAccountsFromLayout = async (layout) => {
  if (!layout || !Array.isArray(layout.slotDetails)) return;

  const facultyMap = new Map();

  for (const detail of layout.slotDetails) {
    const rawId = detail && detail.facultyId;
    if (!rawId) continue;

    const facultyId = String(rawId).trim();
    if (!facultyId) continue;

    if (!facultyMap.has(facultyId)) {
      const name = String(detail.facultyName || "").trim() || facultyId;
      facultyMap.set(facultyId, name);
    }
  }

  if (facultyMap.size === 0) return;

  // Use the default password "LBSCEK" for all newly created faculty
  // accounts. We compute the hash once per request.
  const defaultPasswordHash = await hashPassword("LBSCEK");

  const ops = [];
  for (const [facultyId, facultyName] of facultyMap.entries()) {
    ops.push(
      UserAccount.updateOne(
        { loginId: facultyId },
        {
          $setOnInsert: {
            role: "faculty",
            loginId: facultyId,
            name: facultyName,
            passwordHash: defaultPasswordHash,
            isActive: true,
          },
        },
        { upsert: true }
      ).exec()
    );
  }

  await Promise.all(ops);
};

router.get("/", async (req, res) => {
  try {
    const { dayOfWeek, batch, classroom, facultyId } = req.query;
    const filters = {};

    if (dayOfWeek !== undefined) {
      filters.dayOfWeek = Number(dayOfWeek);
    }
    if (batch) {
      filters.batch = batch;
    }
    if (classroom) {
      filters.classroom = classroom;
    }
    if (facultyId) {
      filters["faculty.facultyId"] = facultyId;
    }

    const timetable = await TimetableEntry.find(filters)
      .populate("classroom")
      .sort({ dayOfWeek: 1, startTime: 1 });

    res.json(timetable);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.post("/", async (req, res) => {
  try {
    const entry = await TimetableEntry.create(req.body);
    res.status(201).json(entry);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

router.post("/bulk", async (req, res) => {
  try {
    const { entries } = req.body;

    if (!Array.isArray(entries) || entries.length === 0) {
      return res
        .status(400)
        .json({ message: "entries must be a non-empty array" });
    }

    const createdEntries = await TimetableEntry.insertMany(entries, {
      ordered: false,
    });

    res.status(201).json({
      message: "Timetable uploaded successfully",
      insertedCount: createdEntries.length,
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Admin classroom timetable layout (grid + slot details) by classroom name
router.get("/admin-layout/:classroomName", async (req, res) => {
  try {
    const { classroomName } = req.params;
    const layout = await AdminClassroomTimetable.findOne({ classroomName });

    if (!layout) {
      return res.json({
        classroomName,
        grid: {},
        slotDetails: [],
      });
    }

    res.json({
      classroomName: layout.classroomName,
      grid: Object.fromEntries(layout.grid || []),
      slotDetails: layout.slotDetails || [],
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.put("/admin-layout/:classroomName", async (req, res) => {
  try {
    const { classroomName } = req.params;
    const { grid, slotDetails } = req.body || {};

    if (!grid || typeof grid !== "object") {
      return res.status(400).json({ message: "grid is required" });
    }

    const safeSlotDetails = Array.isArray(slotDetails) ? slotDetails : [];

    const layout = await AdminClassroomTimetable.findOneAndUpdate(
      { classroomName },
      {
        classroomName,
        grid,
        slotDetails: safeSlotDetails,
      },
      { new: true, upsert: true }
    );

    // After saving the layout, ensure that there is a faculty
    // UserAccount for every facultyId listed in the slotDetails
    // table for this classroom.
    await ensureFacultyAccountsFromLayout(layout);

    res.json({
      classroomName: layout.classroomName,
      grid: Object.fromEntries(layout.grid || []),
      slotDetails: layout.slotDetails || [],
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

module.exports = router;
