// Admin-defined weekly timetable grid per classroom.
const mongoose = require("mongoose");

const slotDetailSchema = new mongoose.Schema(
  {
    slot: {
      type: String,
      required: true,
      trim: true,
    },
    courseName: {
      type: String,
      required: false,
      trim: true,
    },
    facultyId: {
      type: String,
      required: false,
      trim: true,
    },
    facultyName: {
      type: String,
      required: false,
      trim: true,
    },
  },
  { _id: false }
);

const adminClassroomTimetableSchema = new mongoose.Schema(
  {
    classroomName: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    // Map of key "day_period" (e.g. "0_0" for Monday Period 1) to slot value like "A", "B" etc.
    grid: {
      type: Map,
      of: String,
      default: {},
    },
    slotDetails: {
      type: [slotDetailSchema],
      default: [],
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model(
  "AdminClassroomTimetable",
  adminClassroomTimetableSchema
);
