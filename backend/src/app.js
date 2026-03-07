const express = require("express");
const cors = require("cors");
const morgan = require("morgan");

const classroomRoutes = require("./routes/classrooms");
const timetableRoutes = require("./routes/timetable");
const swapRoutes = require("./routes/swap");
const bookingRoutes = require("./routes/bookings");
const authRoutes = require("./routes/auth");
const adminClassroomSettingsRoutes = require("./routes/adminClassroomSettings");
const adminAccountsRoutes = require("./routes/adminAccounts");
const facultyRoutes = require("./routes/faculty");

const app = express();

app.use(cors());
app.use(express.json());
app.use(morgan("dev"));

app.get("/health", (req, res) => {
  res.status(200).json({ ok: true, message: "API is running" });
});

app.use("/api/classrooms", classroomRoutes);
app.use("/api/timetable", timetableRoutes);
app.use("/api/swap", swapRoutes);
app.use("/api/bookings", bookingRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/admin/classroom-settings", adminClassroomSettingsRoutes);
app.use("/api/admin/accounts", adminAccountsRoutes);
app.use("/api/faculty", facultyRoutes);

app.use((req, res) => {
  res.status(404).json({ message: "Route not found" });
});

module.exports = app;
