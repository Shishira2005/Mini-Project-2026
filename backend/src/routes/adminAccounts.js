// Admin endpoints to list representative and faculty accounts.
const express = require("express");

const UserAccount = require("../models/UserAccount");
const CommonFacilitiesRequest = require("../models/CommonFacilitiesRequest");
const { hashPassword } = require("../utils/auth");

const router = express.Router();

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

    await CommonFacilitiesRequest.deleteOne({ email });

    res.json({
      email,
      name: request.name,
      category: request.category,
      status: "approved",
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
