class OtpService {
  static generateOtp() {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  static getExpiryDate(minutes = 10) {
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + minutes);
    return expiresAt;
  }

  static isExpired(expiryDate) {
    if (!expiryDate) return true;
    return new Date() > new Date(expiryDate);
  }
}

module.exports = OtpService;
