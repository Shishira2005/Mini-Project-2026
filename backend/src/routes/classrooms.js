const express = require("express");
const Classroom = require("../models/Classroom");

const router = express.Router();

router.get("/", async (req, res) => {
  try {
    const classrooms = await Classroom.find().sort({ roomNumber: 1 });
    res.json(classrooms);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.post("/", async (req, res) => {
  try {
    const classroom = await Classroom.create(req.body);
    res.status(201).json(classroom);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

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
