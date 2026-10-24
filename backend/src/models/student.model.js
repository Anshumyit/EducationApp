const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Student name is required'],
      trim: true,
    },
    rollNumber: {
      type: Number,
      required: true,
    },
    admissionNumber: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    classId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'ClassRoom',
      required: true,
    },
    parentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    dateOfBirth: {
      type: Date,
    },
    gender: {
      type: String,
      enum: ['MALE', 'FEMALE', 'OTHER'],
      default: 'MALE',
    },
    bloodGroup: {
      type: String,
      default: 'O+',
    },
    address: {
      type: String,
      required: true,
      trim: true,
    },
    emergencyContact: {
      type: String,
      required: true,
      trim: true,
    },
    photo: {
      type: String,
      default: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=150&q=80',
    },
    status: {
      type: String,
      enum: ['ACTIVE', 'TRANSFERRED', 'TC_ISSUED', 'PROMOTED', 'INACTIVE'],
      default: 'ACTIVE',
    },
    tcNumber: {
      type: String,
      default: '',
    },
    tcIssueDate: {
      type: Date,
      default: null,
    },
    tcReason: {
      type: String,
      default: '',
    },
    academicSession: {
      type: String,
      default: '2026-2027',
    },
  },
  {
    timestamps: true,
  }
);

const Student = mongoose.model('Student', studentSchema);
module.exports = Student;
