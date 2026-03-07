// Admin endpoints to list representative and faculty accounts.
const express = require("express");

const UserAccount = require("../models/UserAccount");

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

module.exports = router;
