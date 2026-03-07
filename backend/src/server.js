// Entry point for the backend server.
// Loads environment variables, connects to MongoDB, and starts Express.

require("dotenv").config();

const app = require("./app");
const connectDB = require("./config/db");

// Use PORT from .env when available, otherwise default to 5000.
const PORT = process.env.PORT || 5000;

// Start the HTTP server only after a successful database connection.
const startServer = async () => {
  try {
    await connectDB(process.env.MONGO_URI);
    app.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error("Failed to start server", error.message);
    process.exit(1);
  }
};

// Immediately invoke startup when this file is executed.
startServer();
