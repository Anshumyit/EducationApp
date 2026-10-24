const mongoose = require('mongoose');

const busRouteSchema = new mongoose.Schema(
  {
    routeName: { type: String, required: true },
    busNumber: { type: String, required: true },
    driverName: { type: String, required: true },
    driverPhone: { type: String, required: true },
    capacity: { type: Number, default: 35 },
    studentCount: { type: Number, default: 0 },
    stops: [{ type: String }],
  },
  { _id: true }
);

const bookSchema = new mongoose.Schema(
  {
    title: { type: String, required: true },
    author: { type: String, required: true },
    isbn: { type: String, default: '' },
    category: { type: String, default: 'General' },
    totalCopies: { type: Number, default: 5 },
    availableCopies: { type: Number, default: 5 },
  },
  { _id: true }
);

const schoolSettingSchema = new mongoose.Schema(
  {
    schoolName: {
      type: String,
      default: 'St. Xavier International Academy',
    },
    affiliationCode: {
      type: String,
      default: 'CBSE-DEL-2026-9812',
    },
    logo: {
      type: String,
      default: 'https://images.unsplash.com/photo-1546410531-bb4caa6b424d?auto=format&fit=crop&w=200&q=80',
    },
    address: {
      type: String,
      default: 'Plot 14, Institutional Area, Sector 62, New Delhi',
    },
    phone: {
      type: String,
      default: '+91 98765 43210',
    },
    email: {
      type: String,
      default: 'admin@school.com',
    },
    currentSession: {
      type: String,
      default: '2026-2027',
    },
    workingDays: {
      type: [String],
      default: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'],
    },
    busRoutes: [busRouteSchema],
    libraryBooks: [bookSchema],
  },
  {
    timestamps: true,
  }
);

const SchoolSetting = mongoose.model('SchoolSetting', schoolSettingSchema);
module.exports = SchoolSetting;
