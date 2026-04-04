// Admin endpoints to list representative and faculty accounts.
const express = require("express");

const UserAccount = require("../models/UserAccount");
const CommonFacilitiesRequest = require("../models/CommonFacilitiesRequest");
const CommonFacilitiesVerificationHistory = require("../models/CommonFacilitiesVerificationHistory");
const { sendMail } = require("../utils/mailer");
const { buildVerificationEmail } = require("../utils/verificationEmails");

const router = express.Router();

async function sendVerificationNotice(history, request) {
  const emailTemplate = buildVerificationEmail({
    email: request.email,
    name: request.name,
    category: request.category,
    status: history.status,
  });

  await CommonFacilitiesVerificationHistory.findByIdAndUpdate(history._id, {
    $set: {
      notificationStatus: "pending",
      notificationError: "",
      notificationLastAttemptAt: new Date(),
      notificationAttempts: (history.notificationAttempts || 0) + 1,
    },
  });

  try {
    await sendMail({
      to: request.email,
      ...emailTemplate,
    });

    await CommonFacilitiesVerificationHistory.findByIdAndUpdate(history._id, {
      $set: {
        notificationStatus: "sent",
        notificationError: "",
        notificationSentAt: new Date(),
        notificationLastAttemptAt: new Date(),
      },
    });

    return { notificationStatus: "sent" };
  } catch (mailError) {
    const message = mailError?.message || "Failed to send notification";

    await CommonFacilitiesVerificationHistory.findByIdAndUpdate(history._id, {
      $set: {
        notificationStatus: "failed",
        notificationError: message,
        notificationLastAttemptAt: new Date(),
      },
    });

    return { notificationStatus: "failed", notificationError: message };
  }
}

// GET /api/admin/accounts/representatives
// Returns a simple list of representative accounts (admission no + name).
router.get("/representatives", async (req, res) => {
  try {
    const reps = await UserAccount.find({ role: "representative", isActive: true })
      .sort({ loginId: 1 })
      .lean();

    res.json(
      reps.map((u) => ({
        role: u.role,
        loginId: u.loginId,
        name: u.name,
      }))
    );
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /api/admin/accounts/faculty
// Returns a simple list of faculty accounts (ID + name).
router.get("/faculty", async (req, res) => {
  try {
    const faculty = await UserAccount.find({ role: "faculty", isActive: true })
      .sort({ loginId: 1 })
      .lean();

    res.json(
      faculty.map((u) => ({
        role: u.role,
        loginId: u.loginId,
        name: u.name,
      }))
    );
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /api/admin/accounts/verification
// Returns pending Common Facilities account requests that are waiting for approval.
router.get("/verification", async (req, res) => {
  try {
    const accounts = await CommonFacilitiesRequest.find({})
      .sort({ createdAt: -1 })
      .lean();

    res.json(
      accounts.map((u) => ({
        email: u.email,
        name: u.name,
        category: u.category,
        createdAt: u.createdAt,
      }))
    );
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// PATCH /api/admin/accounts/verification/:email
// Creates the real Common Facilities account after approval.
router.patch("/verification/:email", async (req, res) => {
  try {
    const email = String(req.params.email).trim().toLowerCase();
    const request = await CommonFacilitiesRequest.findOne({ email });

    if (!request) {
      return res.status(404).json({ message: "Request not found" });
    }

    const existingAccount = await UserAccount.findOne({ loginId: email });
    if (existingAccount) {
      await CommonFacilitiesRequest.deleteOne({ email });
      return res.status(409).json({ message: "Account already exists" });
    }

    await UserAccount.create({
      role: "commonFacilities",
      loginId: email,
      name: request.name,
      commonFacilitiesCategory: request.category,
      passwordHash: request.passwordHash,
      isActive: true,
    });

    const history = await CommonFacilitiesVerificationHistory.create({
      email,
      name: request.name,
      category: request.category,
      status: "approved",
    });

    const notificationResult = await sendVerificationNotice(history, {
      email,
      name: request.name,
      category: request.category,
    });

    await CommonFacilitiesRequest.deleteOne({ email });

    res.json({
      email,
      name: request.name,
      category: request.category,
      status: "approved",
      notificationStatus: notificationResult.notificationStatus,
      notificationError: notificationResult.notificationError || "",
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// PATCH /api/admin/accounts/verification/:email/decline
// Removes the pending request and stores a declined history record.
router.patch("/verification/:email/decline", async (req, res) => {
  try {
    const email = String(req.params.email).trim().toLowerCase();
    const request = await CommonFacilitiesRequest.findOne({ email });

    if (!request) {
      return res.status(404).json({ message: "Request not found" });
    }

    const history = await CommonFacilitiesVerificationHistory.create({
      email,
      name: request.name,
      category: request.category,
      status: "declined",
    });

    const notificationResult = await sendVerificationNotice(history, {
      email,
      name: request.name,
      category: request.category,
    });

    await CommonFacilitiesRequest.deleteOne({ email });

    res.json({
      email,
      name: request.name,
      category: request.category,
      status: "declined",
      notificationStatus: notificationResult.notificationStatus,
      notificationError: notificationResult.notificationError || "",
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /api/admin/accounts/verification-history
// Returns the approval/decline history.
router.get("/verification-history", async (req, res) => {
  try {
    const history = await CommonFacilitiesVerificationHistory.find({})
      .sort({ decidedAt: -1, createdAt: -1 })
      .lean();

    res.json(
      history.map((entry) => ({
        id: entry._id,
        email: entry.email,
        name: entry.name,
        category: entry.category,
        status: entry.status,
        notificationStatus: entry.notificationStatus || "pending",
        notificationError: entry.notificationError || "",
        notificationAttempts: entry.notificationAttempts || 0,
        notificationSentAt: entry.notificationSentAt,
        notificationLastAttemptAt: entry.notificationLastAttemptAt,
        decidedAt: entry.decidedAt,
      }))
    );
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// PATCH /api/admin/accounts/verification-history/:id/retry-notification
// Re-sends the verification email for a failed approval/decline.
router.patch("/verification-history/:id/retry-notification", async (req, res) => {
  try {
    const history = await CommonFacilitiesVerificationHistory.findById(req.params.id);

    if (!history) {
      return res.status(404).json({ message: "History record not found" });
    }

    const request = {
      email: history.email,
      name: history.name,
      category: history.category,
      status: history.status,
    };

    const result = await sendVerificationNotice(history, request);

    res.json({
      id: history._id,
      email: history.email,
      status: history.status,
      notificationStatus: result.notificationStatus,
      notificationError: result.notificationError || "",
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
