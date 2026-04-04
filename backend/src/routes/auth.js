// Authentication endpoints for login and listing supported roles.
const express = require("express");
const crypto = require("crypto");

const UserAccount = require("../models/UserAccount");
const CommonFacilitiesRequest = require("../models/CommonFacilitiesRequest");
const AdminClassroomSettings = require("../models/AdminClassroomSettings");
const { sendMail } = require("../utils/mailer");
const { comparePassword, signToken, hashPassword } = require("../utils/auth");

const router = express.Router();
const OTP_TTL_MS = 10 * 60 * 1000;
const resetRequests = new Map();

function makeOtp() {
  return String(crypto.randomInt(100000, 1000000));
}

function makeResetToken() {
  return crypto.randomBytes(24).toString("hex");
}

function getResetRequest(email) {
  const request = resetRequests.get(email);
  if (!request) {
    return null;
  }

  if (request.expiresAt < Date.now()) {
    resetRequests.delete(email);
    return null;
  }

  return request;
}

router.get("/roles", (req, res) => {
  res.json(["faculty", "representative", "admin", "commonFacilities"]);
});

router.post("/login", async (req, res) => {
  try {
    const { role, loginId, password } = req.body;

    if (!role || !loginId || !password) {
      return res
        .status(400)
        .json({ message: "role, loginId and password are required" });
    }

    if (
      !["faculty", "representative", "admin", "commonFacilities"].includes(
        role
      )
    ) {
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

router.post("/common-facilities/request", async (req, res) => {
  try {
    const { name, category, email, password } = req.body;

    if (!name || !category || !email || !password) {
      return res
        .status(400)
        .json({ message: "name, category, email and password are required" });
    }

    const trimmedName = String(name).trim();
    const trimmedEmail = String(email).trim().toLowerCase();
    const trimmedCategory = String(category).trim().toLowerCase();

    if (!/^[A-Za-z ]+$/.test(trimmedName)) {
      return res
        .status(400)
        .json({ message: "Name must contain alphabets and spaces only" });
    }

    if (!/^\S+@\S+\.\S+$/.test(trimmedEmail)) {
      return res.status(400).json({ message: "Invalid email format" });
    }

    if (!["student", "representative", "hod", "faculty"].includes(trimmedCategory)) {
      return res.status(400).json({ message: "Invalid category" });
    }

    const existingAccount = await UserAccount.findOne({ loginId: trimmedEmail });
    if (existingAccount) {
      return res.status(409).json({ message: "An account already exists for this email" });
    }

    const existingRequest = await CommonFacilitiesRequest.findOne({
      email: trimmedEmail,
    });
    if (existingRequest) {
      return res.status(409).json({ message: "A request already exists for this email" });
    }

    const passwordHash = await hashPassword(password);
    const request = await CommonFacilitiesRequest.create({
      email: trimmedEmail,
      name: trimmedName,
      category: trimmedCategory,
      passwordHash,
    });

    res.status(201).json({
      message: "Account request submitted for admin verification",
      account: {
        email: request.email,
        name: request.name,
        category: request.category,
        status: "pending",
      },
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.post("/common-facilities/forgot-password/send-otp", async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: "email is required" });
    }

    const trimmedEmail = String(email).trim().toLowerCase();
    const account = await UserAccount.findOne({
      role: "commonFacilities",
      loginId: trimmedEmail,
      isActive: true,
    });

    if (!account) {
      return res
        .status(404)
        .json({ message: "Approved account not found for this email" });
    }

    const otp = makeOtp();
    const resetToken = makeResetToken();
    resetRequests.set(trimmedEmail, {
      email: trimmedEmail,
      otp,
      resetToken,
      expiresAt: Date.now() + OTP_TTL_MS,
    });

    await sendMail({
      to: trimmedEmail,
      subject: "Common Facilities password reset OTP",
      text: `Your 6-digit OTP is ${otp}. It will expire in 10 minutes.`,
    });

    res.status(200).json({
      message: "OTP sent to your email",
      email: trimmedEmail,
      expiresInMinutes: 10,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.post("/common-facilities/forgot-password/verify-otp", async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({ message: "email and otp are required" });
    }

    const trimmedEmail = String(email).trim().toLowerCase();
    const trimmedOtp = String(otp).trim();

    if (!/^\d{6}$/.test(trimmedOtp)) {
      return res.status(400).json({ message: "OTP must be 6 digits" });
    }

    const request = getResetRequest(trimmedEmail);
    if (!request) {
      return res.status(400).json({ message: "OTP expired or not requested" });
    }

    if (request.otp !== trimmedOtp) {
      return res.status(400).json({ message: "Invalid OTP" });
    }

    res.status(200).json({
      message: "OTP verified",
      resetToken: request.resetToken,
      email: trimmedEmail,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

router.post(
  "/common-facilities/forgot-password/reset-password",
  async (req, res) => {
    try {
      const { resetToken, newPassword } = req.body;

      if (!resetToken || !newPassword) {
        return res
          .status(400)
          .json({ message: "resetToken and newPassword are required" });
      }

      const requestEntry = Array.from(resetRequests.values()).find(
        (entry) => entry.resetToken === resetToken
      );

      if (!requestEntry) {
        return res.status(400).json({ message: "Invalid or expired reset token" });
      }

      if (requestEntry.expiresAt < Date.now()) {
        resetRequests.delete(requestEntry.email);
        return res.status(400).json({ message: "Reset token expired" });
      }

      const account = await UserAccount.findOne({
        role: "commonFacilities",
        loginId: requestEntry.email,
        isActive: true,
      });

      if (!account) {
        return res.status(404).json({ message: "Account not found" });
      }

      account.passwordHash = await hashPassword(newPassword);
      await account.save();
      resetRequests.delete(requestEntry.email);

      res.status(200).json({ message: "Password updated successfully" });
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  }
);

module.exports = router;
