const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
    },
    message: {
      type: String,
      required: true,
      trim: true,
    },
    schoolId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'School',
      default: null, // null = Platform-wide central announcement
    },
    isEmergency: {
      type: Boolean,
      default: false,
    },
    isScheduled: {
      type: Boolean,
      default: false,
    },
    scheduledFor: {
      type: Date,
      default: null,
    },
    deliveryStatus: {
      type: String,
      enum: ['SENT', 'SCHEDULED', 'FAILED', 'RETRYING'],
      default: 'SENT',
    },
    retryCount: {
      type: Number,
      default: 0,
    },
    type: {
      type: String,
      enum: ['ATTENDANCE', 'HOMEWORK', 'RESULT', 'LEAVE', 'FEE', 'BROADCAST', 'EMERGENCY', 'SYSTEM', 'GENERAL'],
      default: 'GENERAL',
    },
    // Target audience or specific recipient:
    targetRole: {
      type: String,
      enum: ['ALL', 'ADMIN', 'TEACHERS', 'PARENTS', 'STAFF', 'SPECIFIC'],
      default: 'SPECIFIC',
    },

    recipientId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null, // null if targetRole is ALL, TEACHERS, or PARENTS
    },
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    classId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'ClassRoom',
      default: null,
    },
    metaData: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    isReadBy: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
  },
  {
    timestamps: true,
  }
);

const Notification = mongoose.model('Notification', notificationSchema);
module.exports = Notification;
