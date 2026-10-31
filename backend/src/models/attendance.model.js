const mongoose = require('mongoose');
const { ATTENDANCE_STATUS } = require('../constants/status');

const attendanceRecordSchema = new mongoose.Schema(
  {
    studentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Student',
      required: true,
    },
    status: {
      type: String,
      enum: Object.values(ATTENDANCE_STATUS),
      default: ATTENDANCE_STATUS.PRESENT,
    },
    remarks: {
      type: String,
      default: '',
    },
  },
  { _id: false }
);

const attendanceSchema = new mongoose.Schema(
  {
    schoolId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'School',
      default: null,
    },
    attendanceType: {
      type: String,
      enum: ['STUDENT', 'FACULTY'],
      default: 'STUDENT',
    },
    teacherId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    status: {
      type: String,
      enum: Object.values(ATTENDANCE_STATUS),
      default: ATTENDANCE_STATUS.PRESENT,
    },
    date: {
      type: String, // 'YYYY-MM-DD' for simple date queries
      required: true,
    },
    classId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'ClassRoom',
      default: null,
    },
    markedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    gpsPunch: {
      latitude: { type: Number, default: null },
      longitude: { type: Number, default: null },
      distanceMeters: { type: Number, default: 0 },
      isWithinGeofence: { type: Boolean, default: true },
      punchInTime: { type: Date, default: null },
      punchOutTime: { type: Date, default: null },
    },
    biometricPunchId: {
      type: String,
      default: '',
    },
    isManualOverride: {
      type: Boolean,
      default: false,
    },
    overrideReason: {
      type: String,
      default: '',
    },
    overriddenBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    records: [attendanceRecordSchema],
  },
  {
    timestamps: true,
  }
);

attendanceSchema.index({ date: 1, classId: 1 });
attendanceSchema.index({ date: 1, teacherId: 1 });


const Attendance = mongoose.model('Attendance', attendanceSchema);
module.exports = Attendance;
