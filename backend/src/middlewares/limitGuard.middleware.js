const School = require('../models/school.model');
const Student = require('../models/student.model');
const User = require('../models/user.model');
const ApiError = require('../utils/apiError');
const asyncHandler = require('../utils/asyncHandler');
const { ROLES } = require('../constants/roles');

/**
 * Checks if a specific module is enabled for the school.
 * If user is SUPER_ADMIN, always bypasses restriction.
 */
const checkModuleEnabled = (moduleName) => {
  return asyncHandler(async (req, res, next) => {
    if (req.user?.role === ROLES.SUPER_ADMIN) {
      return next();
    }

    const schoolId = req.user?.schoolId || req.body?.schoolId || req.params?.schoolId;
    if (!schoolId) {
      return next(); // Global or non-school specific
    }

    const school = await School.findById(schoolId);
    if (!school) {
      throw new ApiError(404, 'Associated school not found');
    }

    if (school.status === 'SUSPENDED') {
      throw new ApiError(403, `Access Denied: School '${school.name}' is currently suspended by Super Admin.`);
    }

    if (school.modules && school.modules[moduleName] === false) {
      throw new ApiError(
        403,
        `Feature Restricted: The '${moduleName}' module is currently disabled for your school. Please contact Super Admin.`
      );
    }

    req.school = school;
    next();
  });
};

/**
 * Checks if creating new students or teachers exceeds school limits.
 * Exceeding blocks the operation and sends a 403 ApiError alert!
 */
const checkEntityLimit = (entityType) => {
  return asyncHandler(async (req, res, next) => {
    if (req.user?.role === ROLES.SUPER_ADMIN) {
      return next();
    }

    const schoolId = req.user?.schoolId || req.body?.schoolId;
    if (!schoolId) return next();

    const school = await School.findById(schoolId);
    if (!school) return next();

    if (entityType === 'student') {
      const currentCount = await Student.countDocuments({ schoolId });
      const maxAllowed = school.limits?.maxStudents || 1000;
      if (currentCount >= maxAllowed) {
        throw new ApiError(
          403,
          `Quota Limit Exceeded: Your school has reached the maximum student limit of ${maxAllowed}. Upgrade your school quota via Super Admin to enroll more students.`
        );
      }
    } else if (entityType === 'teacher') {
      const currentCount = await User.countDocuments({ schoolId, role: ROLES.TEACHER });
      const maxAllowed = school.limits?.maxTeachers || 100;
      if (currentCount >= maxAllowed) {
        throw new ApiError(
          403,
          `Quota Limit Exceeded: Your school has reached the maximum faculty limit of ${maxAllowed}. Please contact Super Admin to increase staff seats.`
        );
      }
    }

    next();
  });
};

/**
 * Guard that prevents School Admins from modifying their own or other admin permissions!
 * Only SUPER_ADMIN can grant or modify permissions.
 */
const preventSelfPermissionTampering = (req, res, next) => {
  if (req.user?.role !== ROLES.SUPER_ADMIN) {
    if (req.body?.permissions || req.body?.role || req.body?.limits) {
      throw new ApiError(403, 'Permission Denied: Only Super Admin is authorized to modify role permissions or quota limits.');
    }
  }
  next();
};

module.exports = {
  checkModuleEnabled,
  checkEntityLimit,
  preventSelfPermissionTampering,
};
