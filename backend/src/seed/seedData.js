// One-time script to populate sample classrooms, timetable entries
// and matching user accounts (faculty, representatives, admin).
require("dotenv").config();

const connectDB = require("../config/db");
const Classroom = require("../models/Classroom");
const TimetableEntry = require("../models/TimetableEntry");
const UserAccount = require("../models/UserAccount");
const { hashPassword } = require("../utils/auth");

const classroomsData = [
  {
    roomNumber: "C-101",
    name: "CS Classroom 1",
    type: "classroom",
    capacity: 60,
    hasProjector: true,
  },
  {
    roomNumber: "C-102",
    name: "CS Classroom 2",
    type: "classroom",
    capacity: 50,
    hasProjector: false,
  },
  {
    roomNumber: "C-201",
    name: "CS Smart Room",
    type: "classroom",
    capacity: 70,
    hasProjector: true,
  },
  {
    roomNumber: "SH-1",
    name: "CS Seminar Hall",
    type: "seminar_hall",
    capacity: 180,
    hasProjector: true,
  },
];

const createTimetableData = (roomsByNumber) => [
  {
    classroom: roomsByNumber["C-101"],
    dayOfWeek: 1,
    startTime: "09:00",
    endTime: "10:00",
    subject: "Data Structures",
    faculty: {
      name: "Dr. Rao",
      facultyId: "FAC-CS-101",
    },
    batch: "CS-2A",
    classRepresentative: {
      name: "Arjun Menon",
      admissionNumber: "CS22A001",
    },
    batchesPresent: ["CS-2A"],
  },
  {
    classroom: roomsByNumber["C-101"],
    dayOfWeek: 1,
    startTime: "10:00",
    endTime: "11:00",
    subject: "DBMS",
    faculty: {
      name: "Prof. Singh",
      facultyId: "FAC-CS-205",
    },
    batch: "CS-3A",
    classRepresentative: {
      name: "Neha Joseph",
      admissionNumber: "CS21A017",
    },
    batchesPresent: ["CS-3A"],
  },
  {
    classroom: roomsByNumber["C-102"],
    dayOfWeek: 2,
    startTime: "09:00",
    endTime: "10:00",
    subject: "Operating Systems",
    faculty: {
      name: "Dr. Nair",
      facultyId: "FAC-CS-118",
    },
    batch: "CS-3B",
    classRepresentative: {
      name: "Fathima Ali",
      admissionNumber: "CS21B022",
    },
    batchesPresent: ["CS-3B"],
  },
  {
    classroom: roomsByNumber["C-201"],
    dayOfWeek: 3,
    startTime: "11:00",
    endTime: "12:00",
    subject: "Computer Networks",
    faculty: {
      name: "Prof. Sharma",
      facultyId: "FAC-CS-142",
    },
    batch: "CS-3A",
    classRepresentative: {
      name: "Neha Joseph",
      admissionNumber: "CS21A017",
    },
    batchesPresent: ["CS-3A"],
  },
  {
    classroom: roomsByNumber["SH-1"],
    dayOfWeek: 4,
    startTime: "14:00",
    endTime: "16:00",
    subject: "Seminar Session",
    faculty: {
      name: "Department",
      facultyId: "FAC-CS-HOD",
    },
    batch: "CS-All",
    classRepresentative: {
      name: "Joint CR Panel",
      admissionNumber: "N/A",
    },
    batchesPresent: ["CS-2A", "CS-2B", "CS-3A", "CS-3B", "CS-4A", "CS-4B"],
  },
];

const seed = async () => {
  try {
    await connectDB(process.env.MONGO_URI);

    await Classroom.deleteMany({});
    await TimetableEntry.deleteMany({});
    await UserAccount.deleteMany({});

    const createdRooms = await Classroom.insertMany(classroomsData);
    const roomsByNumber = createdRooms.reduce((acc, room) => {
      acc[room.roomNumber] = room._id;
      return acc;
    }, {});

    const timetableRecords = createTimetableData(roomsByNumber);
    await TimetableEntry.insertMany(timetableRecords);

    const defaultPasswordHash = await hashPassword("LBSCEK");
    const accountMap = new Map();

    timetableRecords.forEach((record) => {
      if (record.faculty?.facultyId) {
        const facultyKey = `faculty-${record.faculty.facultyId}`;
        accountMap.set(facultyKey, {
          role: "faculty",
          loginId: record.faculty.facultyId,
          name: record.faculty.name || record.faculty.facultyId,
          passwordHash: defaultPasswordHash,
        });
      }

      if (
        record.classRepresentative?.admissionNumber &&
        record.classRepresentative.admissionNumber !== "N/A"
      ) {
        const representativeKey = `representative-${record.classRepresentative.admissionNumber}`;
        accountMap.set(representativeKey, {
          role: "representative",
          loginId: record.classRepresentative.admissionNumber,
          name:
            record.classRepresentative.name ||
            record.classRepresentative.admissionNumber,
          passwordHash: defaultPasswordHash,
        });
      }
    });

    accountMap.set("admin-221005", {
      role: "admin",
      loginId: "221005",
      name: "Department Admin",
      passwordHash: defaultPasswordHash,
    });

    await UserAccount.insertMany(Array.from(accountMap.values()));
    console.log("Seed data inserted successfully");
    process.exit(0);
  } catch (error) {
    console.error("Seed failed", error.message);
    process.exit(1);
  }
};

seed();
