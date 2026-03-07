const mongoose = require("mongoose");

const timetableEntrySchema = new mongoose.Schema(
  {
    classroom: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Classroom",
      required: true,
    },
    dayOfWeek: {
      type: Number,
      required: true,
      min: 0,
      max: 6,
    },
    startTime: {
      type: String,
      required: true,
    },
    endTime: {
      type: String,
      required: true,
    },
    subject: {
      type: String,
      required: true,
      trim: true,
    },
    faculty: {
      name: {
        type: String,
        required: true,
        trim: true,
      },
      facultyId: {
        type: String,
        required: true,
        trim: true,
      },
    },
    batch: {
      type: String,
      required: true,
      trim: true,
    },
    classRepresentative: {
      name: {
        type: String,
        trim: true,
      },
      admissionNumber: {
        type: String,
        trim: true,
      },
    },
    batchesPresent: [
      {
        type: String,
        trim: true,
      },
    ],
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("TimetableEntry", timetableEntrySchema);
