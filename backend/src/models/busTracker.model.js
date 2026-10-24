const mongoose = require('mongoose');
const { BUS_STATUS } = require('../constants/status');

const busStopSchema = new mongoose.Schema(
  {
    stopName: { type: String, required: true },
    scheduledTime: { type: String, default: '07:30 AM' },
    latitude: { type: Number, default: 28.6139 },
    longitude: { type: Number, default: 77.2090 },
    arrived: { type: Boolean, default: false },
    studentCount: { type: Number, default: 5 },
  },
  { _id: false }
);

const busTrackerSchema = new mongoose.Schema(
  {
    schoolId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'School',
      required: true,
    },
    busNumber: {
      type: String,
      required: true,
      trim: true,
    },
    routeName: {
      type: String,
      required: true,
      trim: true,
    },
    driverName: {
      type: String,
      required: true,
      trim: true,
    },
    driverPhone: {
      type: String,
      required: true,
      trim: true,
    },
    gpsDeviceId: {
      type: String,
      default: '',
      trim: true,
    },
    status: {
      type: String,
      enum: Object.values(BUS_STATUS),
      default: BUS_STATUS.IDLE,
    },
    tripType: {
      type: String,
      enum: ['MORNING_PICKUP', 'AFTERNOON_DROP', 'IDLE'],
      default: 'IDLE',
    },
    currentLocation: {
      latitude: { type: Number, default: 28.6139 },
      longitude: { type: Number, default: 77.2090 },
      speedKmH: { type: Number, default: 0 },
      heading: { type: Number, default: 0 },
      lastPingAt: { type: Date, default: Date.now },
    },
    stops: [busStopSchema],
    assignedStudentsCount: {
      type: Number,
      default: 25,
    },
    capacity: {
      type: Number,
      default: 40,
    },
    // Expiry alerts
    insuranceExpiryDate: {
      type: Date,
      default: () => new Date(Date.now() + 60 * 24 * 60 * 60 * 1000), // 60 days ahead
    },
    fitnessExpiryDate: {
      type: Date,
      default: () => new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
    },
    pollutionExpiryDate: {
      type: Date,
      default: () => new Date(Date.now() + 15 * 24 * 60 * 60 * 1000), // 15 days ahead (triggers upcoming alert)
    },
  },
  {
    timestamps: true,
  }
);

const BusTracker = mongoose.model('BusTracker', busTrackerSchema);
module.exports = BusTracker;
