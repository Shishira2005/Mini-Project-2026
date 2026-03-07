const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const hashPassword = async (password) => {
  const salt = await bcrypt.genSalt(10);
  return bcrypt.hash(password, salt);
};

const comparePassword = async (password, hash) => {
  return bcrypt.compare(password, hash);
};

const signToken = (payload) => {
  const secret = process.env.JWT_SECRET || "dev-secret-key";
  return jwt.sign(payload, secret, { expiresIn: "1d" });
};

module.exports = {
  hashPassword,
  comparePassword,
  signToken,
};
