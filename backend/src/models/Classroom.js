// Physical classroom / room information used for bookings.
const mongoose = require("mongoose");

const classroomSchema = new mongoose.Schema(
  {
    roomNumber: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    type: {
      type: String,
      enum: ["classroom", "seminar_hall"],
      default: "classroom",
    },
    capacity: {
      type: Number,
      required: true,
      min: 1,
    },
    hasProjector: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("Classroom", classroomSchema);
