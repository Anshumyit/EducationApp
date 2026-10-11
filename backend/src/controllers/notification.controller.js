const Notification = require('../models/notification.model');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/**
 * Get all notifications relevant to the current user
 */
const getMyNotifications = asyncHandler(async (req, res) => {
  const user = req.user;

  const rolePlural = user.role === 'TEACHER' ? 'TEACHERS' : user.role === 'PARENT' ? 'PARENTS' : 'ALL';

  const filter = {
    $or: [
      { recipientId: user._id },
      { targetRole: 'ALL' },
      { targetRole: rolePlural },
    ],
  };

  if (user.assignedClass) {
    filter.$or.push({ classId: user.assignedClass });
  }

  const notifications = await Notification.find(filter)
    .populate('senderId', 'name role avatar')
    .sort({ createdAt: -1 })
    .limit(50);

  const list = notifications.map((n) => {
    const isRead = n.isReadBy.includes(user._id);
    return {
      ...n.toObject(),
      isRead,
    };
  });

  return res.status(200).json(
    new ApiResponse(200, list, 'Notifications retrieved successfully')
  );
});

/**
 * Mark notification as read
 */
const markNotificationRead = asyncHandler(async (req, res) => {
  const { notificationId } = req.params;
  const user = req.user;

  await Notification.findByIdAndUpdate(notificationId, {
    $addToSet: { isReadBy: user._id },
  });

  return res.status(200).json(
    new ApiResponse(200, { notificationId }, 'Notification marked as read')
  );
});

module.exports = {
  getMyNotifications,
  markNotificationRead,
};
