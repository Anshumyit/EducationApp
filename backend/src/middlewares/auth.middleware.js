const { verifyToken } = require('../config/jwt');
const User = require('../models/user.model');
const ApiError = require('../utils/apiError');
const asyncHandler = require('../utils/asyncHandler');
const { USER_STATUS } = require('../constants/status');

const verifyJWT = asyncHandler(async (req, res, next) => {
  const authHeader = req.headers.authorization;
  const token = authHeader && authHeader.startsWith('Bearer ') ? authHeader.split(' ')[1] : null;

  if (!token) {
    throw new ApiError(401, 'Authentication token missing or invalid');
  }

  try {
    const decoded = verifyToken(token);
    const user = await User.findById(decoded.id).populate('assignedClass');

    if (!user) {
      throw new ApiError(401, 'User account no longer exists');
    }

    if (user.status === USER_STATUS.REJECTED) {
      throw new ApiError(403, 'Your account has been rejected by the administrator');
    }

    req.user = user;
    next();
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw new ApiError(401, 'Invalid or expired token', [error.message]);
  }
});

module.exports = {
  verifyJWT,
};
