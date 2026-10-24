const ROLES = Object.freeze({
  SUPER_ADMIN: 'SUPER_ADMIN',
  ADMIN: 'ADMIN',
  TEACHER: 'TEACHER',
  PARENT: 'PARENT',
});

module.exports = {
  ROLES,
  ALL_ROLES: Object.values(ROLES),
};

