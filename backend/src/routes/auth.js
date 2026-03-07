// Authentication endpoints for login and listing supported roles.
const express = require("express");

const UserAccount = require("../models/UserAccount");
const AdminClassroomSettings = require("../models/AdminClassroomSettings");
const { comparePassword, signToken, hashPassword } = require("../utils/auth");

const router = express.Router();

router.get("/roles", (req, res) => {
  res.json(["faculty", "representative", "admin"]);
});

router.post("/login", async (req, res) => {
  try {
    const { role, loginId, password } = req.body;

    if (!role || !loginId || !password) {
      return res
        .status(400)
        .json({ message: "role, loginId and password are required" });
    }

    if (!["faculty", "representative", "admin"].includes(role)) {
      return res.status(400).json({ message: "Invalid role" });
    }

    const trimmedLoginId = String(loginId).trim();

    const user = await UserAccount.findOne({
      role,
      loginId: trimmedLoginId,
      isActive: true,
    });

    if (!user) {
      return res.status(401).json({ message: "Invalid login credentials" });
    }

    const validPassword = await comparePassword(password, user.passwordHash);
    if (!validPassword) {
      return res.status(401).json({ message: "Invalid login credentials" });
    }

    // For representatives, determine whether they are general or lady
    // representatives based on AdminClassroomSettings so the frontend
    // can show this in the profile page.
    let representativeType = null;
    if (user.role === "representative") {
      const repSettings = await AdminClassroomSettings.findOne({
        $or: [
          { generalCrAdmission: user.loginId },
          { ladyCrAdmission: user.loginId },
        ],
      })
        .lean()
        .exec();

      if (repSettings) {
        if (repSettings.generalCrAdmission === user.loginId) {
          representativeType = "general";
        } else if (repSettings.ladyCrAdmission === user.loginId) {
          representativeType = "lady";
        }
      }
    }

    const token = signToken({
      id: user._id,
      role: user.role,
      loginId: user.loginId,
      representativeType,
    });

    res.status(200).json({
      token,
      user: {
        id: user._id,
        role: user.role,
        loginId: user.loginId,
        name: user.name,
        representativeType,
      },
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
