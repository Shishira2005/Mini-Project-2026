// Central place for creating a Mongoose connection.

const mongoose = require("mongoose");

// Connect to MongoDB using the provided connection string.
// Throws early if the URI is missing so startup fails fast.
const connectDB = async (mongoUri) => {
  if (!mongoUri) {
    throw new Error("MONGO_URI is required");
  }

  await mongoose.connect(mongoUri);
  return mongoose.connection;
};

module.exports = connectDB;
