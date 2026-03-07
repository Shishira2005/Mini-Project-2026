// CRUD and bulk upload endpoints for Classroom documents.
const express = require("express");
const Classroom = require("../models/Classroom");

const router = express.Router();

// List all classrooms ordered by room number.
router.get("/", async (req, res) => {
  try {
    const classrooms = await Classroom.find().sort({ roomNumber: 1 });
    res.json(classrooms);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Create a single classroom from the request body.
router.post("/", async (req, res) => {
  try {
    const classroom = await Classroom.create(req.body);
    res.status(201).json(classroom);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// Upsert many classrooms in one request, used for admin uploads.
router.post("/bulk", async (req, res) => {
  try {
    const { classrooms } = req.body;

    if (!Array.isArray(classrooms) || classrooms.length === 0) {
      return res
        .status(400)
        .json({ message: "classrooms must be a non-empty array" });
    }

    const operations = classrooms.map((room) => ({
      updateOne: {
        filter: { roomNumber: room.roomNumber },
        update: { $set: room },
        upsert: true,
      },
    }));

    const result = await Classroom.bulkWrite(operations, { ordered: false });
    res.status(200).json({
      message: "Classrooms uploaded successfully",
      matched: result.matchedCount,
      modified: result.modifiedCount,
      upserted: result.upsertedCount,
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

module.exports = router;
