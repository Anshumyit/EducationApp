const mongoose = require('mongoose');
const { BIOMETRIC_STATUS } = require('../constants/status');

const syncLogSchema = new mongoose.Schema(
  {
    timestamp: {
      type: Date,
      default: Date.now,
    },
    recordsCount: {
      type: Number,
      default: 0,
    },
    status: {
      type: String,
      enum: ['SUCCESS', 'PARTIAL', 'FAILED'],
      default: 'SUCCESS',
    },
    notes: {
      type: String,
      default: 'Routine terminal synchronization completed',
    },
  },
  { _id: false }
);

const biometricDeviceSchema = new mongoose.Schema(
  {
    schoolId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'School',
      required: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    deviceSerial: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    ipAddress: {
      type: String,
      default: '192.168.1.100',
    },
    location: {
      type: String,
      default: 'Faculty Entrance - Block A',
    },
    status: {
      type: String,
      enum: Object.values(BIOMETRIC_STATUS),
      default: BIOMETRIC_STATUS.ONLINE,
    },
    lastSyncAt: {
      type: Date,
      default: Date.now,
    },
    totalPunchesToday: {
      type: Number,
      default: 0,
    },
    failedSyncAlerts: {
      type: Number,
      default: 0,
    },
    syncLogs: [syncLogSchema],
  },
  {
    timestamps: true,
  }
);

const BiometricDevice = mongoose.model('BiometricDevice', biometricDeviceSchema);
module.exports = BiometricDevice;
