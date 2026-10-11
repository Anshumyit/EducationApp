const FeeRecord = require('../models/feeRecord.model');
const Student = require('../models/student.model');
const NotificationService = require('../services/notification.service');
const ApiError = require('../utils/apiError');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/**
 * Get fee status and history for a student
 */
const getStudentFees = asyncHandler(async (req, res) => {
  const { studentId } = req.params;

  const records = await FeeRecord.find({ studentId }).sort({ dueDate: 1 });

  const totalFee = records.reduce((sum, r) => sum + r.totalAmount, 0);
  const totalPaid = records.reduce((sum, r) => sum + r.paidAmount, 0);
  const totalPending = Math.max(0, totalFee - totalPaid);

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        totalFee,
        totalPaid,
        totalPending,
        records,
      },
      'Student fee details retrieved'
    )
  );
});

/**
 * Make/Record a fee payment
 */
const payFee = asyncHandler(async (req, res) => {
  const { feeRecordId } = req.params;
  const { amount, method = 'UPI' } = req.body;

  if (!amount || Number(amount) <= 0) {
    throw new ApiError(400, 'Valid payment amount is required');
  }

  const feeRecord = await FeeRecord.findById(feeRecordId).populate('studentId').populate('parentId');
  if (!feeRecord) throw new ApiError(404, 'Fee record not found');

  const payAmount = Number(amount);
  feeRecord.paidAmount += payAmount;
  feeRecord.payments.push({
    amount: payAmount,
    paymentDate: new Date(),
    method,
  });

  await feeRecord.save();

  // Send receipt notification
  if (feeRecord.parentId) {
    await NotificationService.sendNotification({
      title: 'Fee Payment Received 💳',
      message: `Payment of ₹${payAmount.toLocaleString()} received for ${feeRecord.studentId.name} (${feeRecord.title}). Remaining due: ₹${feeRecord.dueAmount.toLocaleString()}.`,
      type: 'FEE',
      targetRole: 'SPECIFIC',
      recipientId: feeRecord.parentId._id,
      senderId: req.user._id,
    });
  }

  return res.status(200).json(
    new ApiResponse(200, feeRecord, 'Fee payment recorded successfully')
  );
});

/**
 * Admin creates fee record for a student
 */
const createFeeRecord = asyncHandler(async (req, res) => {
  const { studentId, title, totalAmount, dueDate, academicYear } = req.body;

  if (!studentId || !title || !totalAmount || !dueDate) {
    throw new ApiError(400, 'studentId, title, totalAmount, and dueDate are required');
  }

  const student = await Student.findById(studentId);
  if (!student) throw new ApiError(404, 'Student not found');

  const record = await FeeRecord.create({
    studentId,
    parentId: student.parentId,
    title,
    totalAmount,
    dueDate: new Date(dueDate),
    academicYear: academicYear || '2026-2027',
  });

  return res.status(201).json(
    new ApiResponse(201, record, 'Fee bill generated successfully')
  );
});

module.exports = {
  getStudentFees,
  payFee,
  createFeeRecord,
};
