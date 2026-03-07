const express = require("express");
const AdminClassroomSettings = require("../models/AdminClassroomSettings");
const Classroom = require("../models/Classroom");
const UserAccount = require("../models/UserAccount");
const { hashPassword } = require("../utils/auth");

const router = express.Router();

// Get settings for a classroom (by classroomName used in admin UI)
router.get("/:classroomName", async (req, res) => {
  try {
    const { classroomName } = req.params;

    const settings = await AdminClassroomSettings.findOne({ classroomName });

    if (!settings) {
      return res.json({
        classroomName,
        capacity: null,
        hasProjector: false,
        batch: "",
        generalCrName: "",
        generalCrAdmission: "",
        ladyCrName: "",
        ladyCrAdmission: "",
      });
    }

    res.json({
      classroomName: settings.classroomName,
      capacity: settings.capacity,
      hasProjector: settings.hasProjector,
      batch: settings.batch || "",
      generalCrName: settings.generalCrName || "",
      generalCrAdmission: settings.generalCrAdmission || "",
      ladyCrName: settings.ladyCrName || "",
      ladyCrAdmission: settings.ladyCrAdmission || "",
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Create or update settings for a classroom
router.put("/:classroomName", async (req, res) => {
  try {
    const { classroomName } = req.params;
    const {
      capacity,
      hasProjector,
      batch,
      generalCrName,
      generalCrAdmission,
      ladyCrName,
      ladyCrAdmission,
    } = req.body || {};

    const numericCapacity = Number(capacity);
    if (!numericCapacity || Number.isNaN(numericCapacity) || numericCapacity <= 0) {
      return res
        .status(400)
        .json({ message: "capacity must be a positive number" });
    }

    const update = {
      classroomName,
      capacity: numericCapacity,
      hasProjector: Boolean(hasProjector),
      batch: batch || "",
      generalCrName: generalCrName || "",
      generalCrAdmission: generalCrAdmission || "",
      ladyCrName: ladyCrName || "",
      ladyCrAdmission: ladyCrAdmission || "",
    };

    const settings = await AdminClassroomSettings.findOneAndUpdate(
      { classroomName },
      update,
      { new: true, upsert: true }
    );

    // Ensure there is a corresponding Classroom document so that
    // booking availability and creation work for all rooms defined
    // in the admin UI (CS001, CS003, CS007, CS008, CS010, etc.).
    const upperName = classroomName.toUpperCase();
    const isSeminarOrLab =
      upperName.includes("SEMINAR HALL") || upperName.includes("WAD LAB");

    await Classroom.findOneAndUpdate(
      { roomNumber: classroomName },
      {
        roomNumber: classroomName,
        name: classroomName,
        type: isSeminarOrLab ? "seminar_hall" : "classroom",
        capacity: numericCapacity,
        hasProjector: Boolean(hasProjector),
      },
      { new: true, upsert: true }
    );

    // Ensure representative login accounts exist for the configured
    // classroom representatives (general CR and lady CR). These use
    // admission number as loginId and the default password "LBSCEK".
    const representativesToEnsure = [];

    const trimmedGeneralAdmission = (generalCrAdmission || "").trim();
    if (trimmedGeneralAdmission) {
      representativesToEnsure.push({
        loginId: trimmedGeneralAdmission,
        name: (generalCrName || "").trim() || trimmedGeneralAdmission,
      });
    }

    const trimmedLadyAdmission = (ladyCrAdmission || "").trim();
    if (trimmedLadyAdmission) {
      representativesToEnsure.push({
        loginId: trimmedLadyAdmission,
        name: (ladyCrName || "").trim() || trimmedLadyAdmission,
      });
    }

    if (representativesToEnsure.length > 0) {
      const defaultPasswordHash = await hashPassword("LBSCEK");

      for (const rep of representativesToEnsure) {
        const existing = await UserAccount.findOne({
          role: "representative",
          loginId: rep.loginId,
        }).exec();

        if (!existing) {
          await UserAccount.create({
            role: "representative",
            loginId: rep.loginId,
            name: rep.name,
            passwordHash: defaultPasswordHash,
          });
        }
      }
    }

    res.json({
      classroomName: settings.classroomName,
      capacity: settings.capacity,
      hasProjector: settings.hasProjector,
      batch: settings.batch || "",
      generalCrName: settings.generalCrName || "",
      generalCrAdmission: settings.generalCrAdmission || "",
      ladyCrName: settings.ladyCrName || "",
      ladyCrAdmission: settings.ladyCrAdmission || "",
    });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

module.exports = router;
