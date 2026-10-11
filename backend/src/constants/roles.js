const ROLES = Object.freeze({
  ADMIN: 'ADMIN',
  TEACHER: 'TEACHER',
  PARENT: 'PARENT',
});

module.exports = {
  ROLES,
  ALL_ROLES: Object.values(ROLES),
};
