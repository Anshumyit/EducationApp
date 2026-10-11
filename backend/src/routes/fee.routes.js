const express = require('express');
const router = express.Router();
const {
  getStudentFees,
  payFee,
  createFeeRecord,
} = require('../controllers/fee.controller');
const { verifyJWT } = require('../middlewares/auth.middleware');
const { authorizeRoles } = require('../middlewares/role.middleware');
const { ROLES } = require('../constants/roles');

router.use(verifyJWT);

router.get('/student/:studentId', getStudentFees);
router.post('/pay/:feeRecordId', payFee);
router.post('/record', authorizeRoles(ROLES.ADMIN), createFeeRecord);

module.exports = router;
