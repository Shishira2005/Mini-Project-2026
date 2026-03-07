const mongoose = require("mongoose");

const adminClassroomSettingsSchema = new mongoose.Schema(
  {
    classroomName: {
      type: String,
      required: true,
      unique: true,
      trim: true,
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
    batch: {
      type: String,
      trim: true,
      default: "",
    },
    generalCrName: {
      type: String,
      trim: true,
      default: "",
    },
    generalCrAdmission: {
      type: String,
      trim: true,
      default: "",
    },
    ladyCrName: {
      type: String,
      trim: true,
      default: "",
    },
    ladyCrAdmission: {
      type: String,
      trim: true,
      default: "",
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model(
  "AdminClassroomSettings",
  adminClassroomSettingsSchema
);
