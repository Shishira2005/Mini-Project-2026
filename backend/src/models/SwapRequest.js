// Swap request between two classrooms for a specific period.
const mongoose = require("mongoose");

const swapRequestSchema = new mongoose.Schema(
  {
    date: {
      type: Date,
      required: true,
    },
    weekdayIndex: {
      type: Number,
      required: true,
      min: 0,
      max: 6,
    },
    startTime: {
      type: String,
      required: true,
      trim: true,
    },
    endTime: {
      type: String,
      required: true,
      trim: true,
    },
    projectorRequired: {
      type: Boolean,
      default: false,
    },
    requesterFacultyId: {
      type: String,
      required: true,
      trim: true,
    },
    requesterFacultyName: {
      type: String,
      required: true,
      trim: true,
    },
    requesterClassroomName: {
      type: String,
      required: true,
      trim: true,
    },
    targetClassroomName: {
      type: String,
      required: true,
      trim: true,
    },
    targetFacultyId: {
      type: String,
      required: true,
      trim: true,
    },
    targetFacultyName: {
      type: String,
      required: true,
      trim: true,
    },
    reason: {
      type: String,
      required: true,
      trim: true,
    },
    status: {
      type: String,
      enum: ["pending", "accepted", "rejected", "cancelled"],
      default: "pending",
    },
    respondedAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("SwapRequest", swapRequestSchema);
