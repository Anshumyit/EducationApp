const ApiError = require('../utils/apiError');

/**
 * Role-based access control guard
 * @param  {...string} allowedRoles
 */
const authorizeRoles = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return next(
        new ApiError(
          403,
          `Access forbidden: Role '${req.user ? req.user.role : 'GUEST'}' is not authorized to access this route`
        )
      );
    }
    next();
  };
};

module.exports = {
  authorizeRoles,
};
