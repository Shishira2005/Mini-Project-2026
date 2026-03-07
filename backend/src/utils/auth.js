// Authentication-related helpers for hashing passwords and signing JWTs.

const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

// Create a salted bcrypt hash of a plain-text password.
const hashPassword = async (password) => {
  const salt = await bcrypt.genSalt(10);
  return bcrypt.hash(password, salt);
};

// Compare a plain-text password with a stored bcrypt hash.
const comparePassword = async (password, hash) => {
  return bcrypt.compare(password, hash);
};

// Sign a short-lived JWT that encodes basic user information.
const signToken = (payload) => {
  const secret = process.env.JWT_SECRET || "dev-secret-key";
  return jwt.sign(payload, secret, { expiresIn: "1d" });
};

module.exports = {
  hashPassword,
  comparePassword,
  signToken,
};
