const ApiError = require('../utils/apiError');

const errorHandler = (err, req, res, next) => {
  let error = err;

  // Handle MongoDB Duplicate Key Error (code 11000)
  if (err.code === 11000) {
    const key = Object.keys(err.keyPattern || err.keyValue || {})[0];
    const val = err.keyValue ? err.keyValue[key] : '';
    let message = 'Duplicate field value entered in database.';
    if (key === 'email') {
      message = `Email '${val}' is already registered in the database. Please use a different email or log in.`;
    } else if (key === 'phone') {
      message = `Phone number '${val}' is already registered in the database. Please use a different phone number or log in.`;
    } else if (key) {
      message = `${key.charAt(0).toUpperCase() + key.slice(1)} '${val}' already exists in the database.`;
    }
    error = new ApiError(409, message, error?.errors || [], err.stack);
  } else if (!(error instanceof ApiError)) {
    const statusCode = error.statusCode || 500;
    const message = error.message || 'Internal Server Error';
    error = new ApiError(statusCode, message, error?.errors || [], err.stack);
  }

  const response = {
    success: false,
    statusCode: error.statusCode,
    message: error.message,
    errors: error.errors,
    ...(process.env.NODE_ENV === 'development' && { stack: error.stack }),
  };

  return res.status(error.statusCode).json(response);
};

module.exports = errorHandler;
