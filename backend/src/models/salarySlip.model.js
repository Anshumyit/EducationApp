const mongoose = require('mongoose');

const salarySlipSchema = new mongoose.Schema(
  {
    teacherId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    month: {
      type: String,
      required: true, // e.g. "October"
    },
    year: {
      type: Number,
      required: true, // e.g. 2026
    },
    slipNumber: {
      type: String,
      unique: true,
      default: () => `PAY-${Date.now().toString().slice(-8)}`,
    },
    basicSalary: {
      type: Number,
      required: true,
    },
    hra: {
      type: Number,
      default: 0,
    },
    da: {
      type: Number,
      default: 0,
    },
    specialAllowance: {
      type: Number,
      default: 0,
    },
    pfDeduction: {
      type: Number,
      default: 0,
    },
    taxDeduction: {
      type: Number,
      default: 0,
    },
    netSalary: {
      type: Number,
      required: true,
    },
    paymentDate: {
      type: Date,
      default: Date.now,
    },
    paymentStatus: {
      type: String,
      enum: ['PAID', 'PENDING', 'PROCESSING'],
      default: 'PAID',
    },
  },
  {
    timestamps: true,
  }
);

const SalarySlip = mongoose.model('SalarySlip', salarySlipSchema);
module.exports = SalarySlip;
