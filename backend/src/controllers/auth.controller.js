const User = require('../models/user.model');
const { ROLES } = require('../constants/roles');
const { USER_STATUS } = require('../constants/status');
const { generateToken } = require('../config/jwt');
const OtpService = require('../services/otp.service');
const ApiError = require('../utils/apiError');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

/**
 * Register Admin -> generates OTP
 */
const registerAdmin = asyncHandler(async (req, res) => {
  const { name, email, phone, password } = req.body;

  if (!name || (!email && !phone) || !password) {
    throw new ApiError(400, 'Name, password, and email or phone are required');
  }

  const existing = await User.findOne({
    $or: [{ email: email ? email.toLowerCase() : null }, { phone: phone || null }].filter(Boolean),
  });

  if (existing) {
    throw new ApiError(409, 'An account with this email or phone already exists');
  }

  const otp = OtpService.generateOtp();
  const expiresAt = OtpService.getExpiryDate(10);

  const admin = await User.create({
    name,
    email: email ? email.toLowerCase() : undefined,
    phone,
    password,
    role: ROLES.ADMIN,
    status: USER_STATUS.PENDING,
    isOtpVerified: false,
    otp: {
      code: otp,
      expiresAt,
    },
  });

  return res.status(201).json(
    new ApiResponse(
      201,
      {
        userId: admin._id,
        email: admin.email,
        phone: admin.phone,
        otpCode: otp, // Returned for effortless demo / instant verification
      },
      'Admin registered successfully. Please verify OTP to activate.'
    )
  );
});

/**
 * Verify OTP for Admin (activates admin account)
 */
const verifyAdminOtp = asyncHandler(async (req, res) => {
  const { userId, email, phone, otp } = req.body;

  let user;
  if (userId) {
    user = await User.findById(userId).select('+otp +password');
  } else if (email) {
    user = await User.findOne({ email: email.toLowerCase() }).select('+otp +password');
  } else if (phone) {
    user = await User.findOne({ phone }).select('+otp +password');
  }

  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  if (!user.otp || user.otp.code !== otp) {
    throw new ApiError(400, 'Invalid OTP code');
  }

  if (OtpService.isExpired(user.otp.expiresAt)) {
    throw new ApiError(400, 'OTP code has expired. Please request a new one.');
  }

  user.isOtpVerified = true;
  user.status = USER_STATUS.APPROVED; // Admin is auto-approved upon OTP verification
  user.otp = undefined;
  await user.save();

  const token = generateToken({ id: user._id, role: user.role });

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        token,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          role: user.role,
          status: user.status,
          avatar: user.avatar,
        },
      },
      'OTP verified successfully. Admin account activated.'
    )
  );
});

/**
 * Register Teacher -> Pending Admin Approval
 */
const registerTeacher = asyncHandler(async (req, res) => {
  const { name, email, phone, password, subjects, qualification } = req.body;

  if (!name || (!email && !phone) || !password) {
    throw new ApiError(400, 'Name, password, and email or phone are required');
  }

  const existing = await User.findOne({
    $or: [{ email: email ? email.toLowerCase() : null }, { phone: phone || null }].filter(Boolean),
  });

  if (existing) {
    throw new ApiError(409, 'An account with this email or phone already exists');
  }

  const teacher = await User.create({
    name,
    email: email ? email.toLowerCase() : undefined,
    phone,
    password,
    role: ROLES.TEACHER,
    status: USER_STATUS.PENDING, // Strictly pending admin approval
    subjects: subjects || [],
    qualification: qualification || '',
    isOtpVerified: true,
  });

  return res.status(201).json(
    new ApiResponse(
      201,
      {
        userId: teacher._id,
        name: teacher.name,
        role: teacher.role,
        status: teacher.status,
      },
      'Teacher registration submitted successfully. Please wait for Admin approval to login.'
    )
  );
});

/**
 * Register Parent -> Pending Admin Approval
 */
const registerParent = asyncHandler(async (req, res) => {
  const { name, email, phone, password, address } = req.body;

  if (!name || (!email && !phone) || !password) {
    throw new ApiError(400, 'Name, password, and email or phone are required');
  }

  const existing = await User.findOne({
    $or: [{ email: email ? email.toLowerCase() : null }, { phone: phone || null }].filter(Boolean),
  });

  if (existing) {
    throw new ApiError(409, 'An account with this email or phone already exists');
  }

  const parent = await User.create({
    name,
    email: email ? email.toLowerCase() : undefined,
    phone,
    password,
    role: ROLES.PARENT,
    status: USER_STATUS.PENDING, // Strictly pending admin approval
    address: address || '',
    isOtpVerified: true,
  });

  return res.status(201).json(
    new ApiResponse(
      201,
      {
        userId: parent._id,
        name: parent.name,
        role: parent.role,
        status: parent.status,
      },
      'Parent registration submitted successfully. Please wait for Admin approval to login.'
    )
  );
});

/**
 * Universal Login for Admin, Teacher, Parent
 */
const loginUser = asyncHandler(async (req, res) => {
  const { identifier, password } = req.body; // identifier can be email or phone

  if (!identifier || !password) {
    throw new ApiError(400, 'Email/phone and password are required');
  }

  const query = identifier.includes('@')
    ? { email: identifier.toLowerCase() }
    : { phone: identifier.trim() };

  const user = await User.findOne(query).select('+password').populate('assignedClass');

  if (!user) {
    throw new ApiError(401, 'No account found with this email or phone number');
  }

  const isPasswordValid = await user.isPasswordCorrect(password);
  if (!isPasswordValid) {
    throw new ApiError(401, 'Incorrect password');
  }

  // Admin must verify OTP first
  if (user.role === ROLES.ADMIN && !user.isOtpVerified) {
    throw new ApiError(403, 'Admin OTP verification is pending. Please verify OTP first.', {
      userId: user._id,
      requireOtp: true,
    });
  }

  // CRITICAL REQUIREMENT: Teachers & Parents must be approved by Admin
  if (user.role === ROLES.TEACHER || user.role === ROLES.PARENT) {
    if (user.status === USER_STATUS.PENDING) {
      throw new ApiError(
        403,
        'Your registration is currently PENDING approval by the School Admin. You can login once approved.',
        { status: USER_STATUS.PENDING }
      );
    }
    if (user.status === USER_STATUS.REJECTED) {
      throw new ApiError(
        403,
        'Your account registration request has been REJECTED by the Administrator.',
        { status: USER_STATUS.REJECTED }
      );
    }
  }

  const token = generateToken({ id: user._id, role: user.role });

  return res.status(200).json(
    new ApiResponse(
      200,
      {
        token,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          role: user.role,
          status: user.status,
          avatar: user.avatar,
          subjects: user.subjects,
          isClassTeacher: user.isClassTeacher,
          assignedClass: user.assignedClass,
          address: user.address,
        },
      },
      `Welcome back, ${user.name}!`
    )
  );
});

/**
 * Get current authenticated user details
 */
const getCurrentUser = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user._id).populate('assignedClass');
  return res.status(200).json(new ApiResponse(200, user, 'User details retrieved'));
});

module.exports = {
  registerAdmin,
  verifyAdminOtp,
  registerTeacher,
  registerParent,
  loginUser,
  getCurrentUser,
};
