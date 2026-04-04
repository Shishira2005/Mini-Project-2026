// User login account for all roles (admin, faculty, representative).
const mongoose = require("mongoose");

const userAccountSchema = new mongoose.Schema(
  {
    role: {
      type: String,
      enum: ["faculty", "representative", "admin", "commonFacilities"],
      required: true,
    },
    loginId: {
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
    commonFacilitiesCategory: {
      type: String,
      enum: ["student", "representative", "hod", "faculty"],
      default: null,
    },
    passwordHash: {
      type: String,
      required: true,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("UserAccount", userAccountSchema);
