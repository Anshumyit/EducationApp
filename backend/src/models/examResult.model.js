const mongoose = require('mongoose');
const { EXAM_TYPES } = require('../constants/status');

const subjectMarkSchema = new mongoose.Schema(
  {
    subjectName: {
      type: String,
      required: true,
      trim: true,
    },
    maxMarks: {
      type: Number,
      required: true,
      default: 100,
    },
    marksObtained: {
      type: Number,
      required: true,
    },
    grade: {
      type: String,
      default: 'A',
    },
    remarks: {
      type: String,
      default: '',
    },
  },
  { _id: false }
);

const examResultSchema = new mongoose.Schema(
  {
    studentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Student',
      required: true,
    },
    classId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'ClassRoom',
      required: true,
    },
    examType: {
      type: String,
      enum: Object.values(EXAM_TYPES),
      required: true,
    },
    examTitle: {
      type: String,
      required: true,
      trim: true,
    },
    examDate: {
      type: Date,
      default: Date.now,
    },
    academicYear: {
      type: String,
      default: '2026-2027',
    },
    subjects: [subjectMarkSchema],
    totalMaxMarks: {
      type: Number,
      default: 0,
    },
    totalMarksObtained: {
      type: Number,
      default: 0,
    },
    percentage: {
      type: Number,
      default: 0,
    },
    overallGrade: {
      type: String,
      default: 'A',
    },
    enteredBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

examResultSchema.pre('save', function () {
  if (this.subjects && this.subjects.length > 0) {
    this.totalMaxMarks = this.subjects.reduce((sum, s) => sum + (s.maxMarks || 0), 0);
    this.totalMarksObtained = this.subjects.reduce((sum, s) => sum + (s.marksObtained || 0), 0);
    this.percentage = this.totalMaxMarks > 0 ? parseFloat(((this.totalMarksObtained / this.totalMaxMarks) * 100).toFixed(2)) : 0;
    
    if (this.percentage >= 90) this.overallGrade = 'A+';
    else if (this.percentage >= 80) this.overallGrade = 'A';
    else if (this.percentage >= 70) this.overallGrade = 'B+';
    else if (this.percentage >= 60) this.overallGrade = 'B';
    else if (this.percentage >= 50) this.overallGrade = 'C';
    else if (this.percentage >= 35) this.overallGrade = 'D';
    else this.overallGrade = 'F';
  }
});

const ExamResult = mongoose.model('ExamResult', examResultSchema);
module.exports = ExamResult;
