const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Gmail SMTP 설정 (실제 환경에서는 환경변수 사용)
const transporter = nodemailer.createTransporter({
  service: 'gmail',
  auth: {
    user: functions.config().gmail.email, // Firebase 환경변수
    pass: functions.config().gmail.password // Gmail 앱 비밀번호
  }
});

// 이메일 인증번호 발송 함수
exports.sendVerificationEmail = functions.https.onCall(async (data, context) => {
  const { email, code } = data;
  
  if (!email || !code) {
    throw new functions.https.HttpsError('invalid-argument', '이메일과 인증번호가 필요합니다.');
  }

  const mailOptions = {
    from: '"라운더스" <noreply@rounders.com>',
    to: email,
    subject: '[라운더스] 이메일 인증번호',
    html: `
      <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: 'Pretendard', sans-serif;">
        <div style="text-align: center; margin-bottom: 30px;">
          <h1 style="color: #F44336; margin: 0;">라운더스</h1>
        </div>
        
        <div style="background-color: #f8f9fa; padding: 30px; border-radius: 8px; text-align: center;">
          <h2 style="color: #333; margin-bottom: 20px;">이메일 인증번호</h2>
          <p style="color: #666; margin-bottom: 30px;">회원가입을 완료하기 위해 아래 인증번호를 입력해주세요.</p>
          
          <div style="background-color: #fff; padding: 20px; border-radius: 4px; border: 2px solid #F44336; display: inline-block;">
            <span style="font-size: 32px; font-weight: bold; color: #F44336; letter-spacing: 8px;">${code}</span>
          </div>
          
          <p style="color: #999; margin-top: 30px; font-size: 14px;">
            이 인증번호는 5분 후에 만료됩니다.<br>
            본인이 요청하지 않았다면 이 이메일을 무시해주세요.
          </p>
        </div>
        
        <div style="text-align: center; margin-top: 30px; color: #999; font-size: 12px;">
          <p>© 2024 라운더스. All rights reserved.</p>
        </div>
      </div>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`인증 이메일 발송 완료: ${email}`);
    return { success: true };
  } catch (error) {
    console.error('이메일 발송 실패:', error);
    throw new functions.https.HttpsError('internal', '이메일 발송에 실패했습니다.');
  }
}); 