// Pending Common Facilities account requests awaiting admin approval.
const mongoose = require("mongoose");

const commonFacilitiesRequestSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      lowercase: true,
    },
    category: {
      type: String,
      enum: ["student", "representative", "hod", "faculty"],
      required: true,
    },
    passwordHash: {
      type: String,
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model(
  "CommonFacilitiesRequest",
  commonFacilitiesRequestSchema
);