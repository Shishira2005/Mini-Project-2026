// Audit trail for Common Facilities request approvals and declines.
const mongoose = require("mongoose");

const commonFacilitiesVerificationHistorySchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      trim: true,
      lowercase: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    category: {
      type: String,
      enum: ["student", "representative", "hod", "faculty"],
      required: true,
    },
    status: {
      type: String,
      enum: ["approved", "declined"],
      required: true,
    },
    notificationStatus: {
      type: String,
      enum: ["pending", "sent", "failed"],
      default: "pending",
    },
    notificationError: {
      type: String,
      default: "",
    },
    notificationAttempts: {
      type: Number,
      default: 0,
    },
    notificationSentAt: {
      type: Date,
    },
    notificationLastAttemptAt: {
      type: Date,
    },
    decidedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model(
  "CommonFacilitiesVerificationHistory",
  commonFacilitiesVerificationHistorySchema
);