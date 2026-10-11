const mongoose = require('mongoose');
const { FEE_STATUS } = require('../constants/status');

const paymentHistorySchema = new mongoose.Schema(
  {
    amount: {
      type: Number,
      required: true,
    },
    paymentDate: {
      type: Date,
      default: Date.now,
    },
    transactionId: {
      type: String,
      default: () => `TXN-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
    },
    method: {
      type: String,
      enum: ['ONLINE', 'CASH', 'CHEQUE', 'UPI', 'BANK_TRANSFER'],
      default: 'UPI',
    },
    receiptNumber: {
      type: String,
      default: () => `REC-${Date.now().toString().slice(-6)}`,
    },
  },
  { _id: false }
);

const feeRecordSchema = new mongoose.Schema(
  {
    studentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Student',
      required: true,
    },
    parentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    title: {
      type: String,
      required: true,
      trim: true, // e.g. "Term 1 Tuition Fee", "Annual Activity Fee"
    },
    academicYear: {
      type: String,
      default: '2026-2027',
    },
    totalAmount: {
      type: Number,
      required: true,
    },
    paidAmount: {
      type: Number,
      default: 0,
    },
    dueDate: {
      type: Date,
      required: true,
    },
    status: {
      type: String,
      enum: Object.values(FEE_STATUS),
      default: FEE_STATUS.PENDING,
    },
    payments: [paymentHistorySchema],
  },
  {
    timestamps: true,
  }
);

feeRecordSchema.virtual('dueAmount').get(function () {
  return Math.max(0, this.totalAmount - this.paidAmount);
});

feeRecordSchema.pre('save', function () {
  if (this.paidAmount >= this.totalAmount) {
    this.status = FEE_STATUS.PAID;
  } else if (this.paidAmount > 0) {
    this.status = FEE_STATUS.PARTIAL;
  } else {
    this.status = new Date() > this.dueDate ? FEE_STATUS.OVERDUE : FEE_STATUS.PENDING;
  }
});

const FeeRecord = mongoose.model('FeeRecord', feeRecordSchema);
module.exports = FeeRecord;
