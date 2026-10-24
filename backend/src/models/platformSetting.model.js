const mongoose = require('mongoose');

const platformSettingSchema = new mongoose.Schema(
  {
    platformName: {
      type: String,
      default: 'ScholarCloud Unified Multi-School Platform',
    },
    systemVersion: {
      type: String,
      default: '3.4.0-Enterprise',
    },
    maintenanceMode: {
      type: Boolean,
      default: false,
    },
    defaultAcademicYear: {
      type: String,
      default: '2026-2027',
    },
    backupRetentionDays: {
      type: Number,
      default: 30,
    },
    lastBackupAt: {
      type: Date,
      default: Date.now,
    },
    lastBackupSizeMB: {
      type: Number,
      default: 342.8,
    },
    failedLoginThreshold: {
      type: Number,
      default: 5,
    },
    securityAlertsCount: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  }
);

const PlatformSetting = mongoose.model('PlatformSetting', platformSettingSchema);
module.exports = PlatformSetting;
