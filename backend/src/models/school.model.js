const mongoose = require('mongoose');
const { SCHOOL_STATUS } = require('../constants/status');

const schoolSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'School name is required'],
      trim: true,
    },
    code: {
      type: String,
      required: [true, 'School code is required'],
      unique: true,
      trim: true,
      uppercase: true,
    },
    affiliationCode: {
      type: String,
      default: '',
      trim: true,
    },
    status: {
      type: String,
      enum: Object.values(SCHOOL_STATUS),
      default: SCHOOL_STATUS.ACTIVE,
    },
    contactEmail: {
      type: String,
      required: [true, 'Contact email is required'],
      trim: true,
      lowercase: true,
    },
    contactPhone: {
      type: String,
      required: [true, 'Contact phone is required'],
      trim: true,
    },
    address: {
      type: String,
      required: true,
      trim: true,
    },
    city: {
      type: String,
      default: 'New Delhi',
      trim: true,
    },
    state: {
      type: String,
      default: 'Delhi',
      trim: true,
    },
    principalName: {
      type: String,
      default: '',
      trim: true,
    },
    logo: {
      type: String,
      default: 'https://images.unsplash.com/photo-1546410531-bb4caa6b424d?auto=format&fit=crop&w=200&q=80',
    },
    currentAcademicYear: {
      type: String,
      default: '2026-2027',
    },
    geofence: {
      latitude: {
        type: Number,
        default: 28.6139,
      },
      longitude: {
        type: Number,
        default: 77.2090,
      },
      radiusMeters: {
        type: Number,
        default: 300,
      },
    },
    limits: {
      maxStudents: {
        type: Number,
        default: 1000,
      },
      maxTeachers: {
        type: Number,
        default: 100,
      },
      maxStaff: {
        type: Number,
        default: 50,
      },
      storageLimitMB: {
        type: Number,
        default: 10240, // 10 GB
      },
      usedStorageMB: {
        type: Number,
        default: 120,
      },
    },
    modules: {
      busTracking: {
        type: Boolean,
        default: true,
      },
      biometricAttendance: {
        type: Boolean,
        default: true,
      },
      feeManagement: {
        type: Boolean,
        default: true,
      },
      examResults: {
        type: Boolean,
        default: true,
      },
      studentAdmission: {
        type: Boolean,
        default: true,
      },
      leaveManagement: {
        type: Boolean,
        default: true,
      },
      libraryModule: {
        type: Boolean,
        default: true,
      },
      dailySyllabus: {
        type: Boolean,
        default: true,
      },
    },
  },
  {
    timestamps: true,
  }
);

const School = mongoose.model('School', schoolSchema);
module.exports = School;
