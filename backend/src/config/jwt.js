const jwt = require('jsonwebtoken');

const generateToken = (payload) => {
  return jwt.sign(payload, process.env.JWT_SECRET || 'super_secret_school_management_key_2026_clean_arch', {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
};

const verifyToken = (token) => {
  return jwt.verify(token, process.env.JWT_SECRET || 'super_secret_school_management_key_2026_clean_arch');
};

module.exports = {
  generateToken,
  verifyToken,
};
