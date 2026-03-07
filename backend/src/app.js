// Main Express application for the backend API.
// This file wires together global middleware and all route modules.

const express = require("express");
const cors = require("cors");
const morgan = require("morgan");

// Route modules grouped by feature
const classroomRoutes = require("./routes/classrooms");
const timetableRoutes = require("./routes/timetable");
const swapRoutes = require("./routes/swap");
const bookingRoutes = require("./routes/bookings");
const authRoutes = require("./routes/auth");
const adminClassroomSettingsRoutes = require("./routes/adminClassroomSettings");
const adminAccountsRoutes = require("./routes/adminAccounts");
const facultyRoutes = require("./routes/faculty");

const app = express();

// Allow the Flutter app (and other clients) to call this API from
// different origins.
app.use(cors());

// Parse incoming JSON request bodies.
app.use(express.json());

// Log each HTTP request in the console while developing.
app.use(morgan("dev"));

// Simple health‑check endpoint so you can quickly verify that the
// backend is running (used by you or monitoring tools).
app.get("/health", (req, res) => {
  res.status(200).json({ ok: true, message: "API is running" });
});

// Feature routes under a common /api prefix.
app.use("/api/classrooms", classroomRoutes);
app.use("/api/timetable", timetableRoutes);
app.use("/api/swap", swapRoutes);
app.use("/api/bookings", bookingRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/admin/classroom-settings", adminClassroomSettingsRoutes);
app.use("/api/admin/accounts", adminAccountsRoutes);
app.use("/api/faculty", facultyRoutes);

// Fallback for any unknown route – avoids HTML error pages and keeps
// the API response format consistent.
app.use((req, res) => {
  res.status(404).json({ message: "Route not found" });
});

module.exports = app;
