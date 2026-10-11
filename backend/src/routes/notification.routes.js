const express = require('express');
const router = express.Router();
const {
  getMyNotifications,
  markNotificationRead,
} = require('../controllers/notification.controller');
const { verifyJWT } = require('../middlewares/auth.middleware');

router.use(verifyJWT);

router.get('/my', getMyNotifications);
router.patch('/:notificationId/read', markNotificationRead);

module.exports = router;
