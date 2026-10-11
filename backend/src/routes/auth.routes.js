const express = require('express');
const router = express.Router();
const {
  registerAdmin,
  verifyAdminOtp,
  registerTeacher,
  registerParent,
  loginUser,
  getCurrentUser,
} = require('../controllers/auth.controller');
const { verifyJWT } = require('../middlewares/auth.middleware');

router.post('/register/admin', registerAdmin);
router.post('/verify-otp', verifyAdminOtp);
router.post('/register/teacher', registerTeacher);
router.post('/register/parent', registerParent);
router.post('/login', loginUser);
router.get('/me', verifyJWT, getCurrentUser);

module.exports = router;
