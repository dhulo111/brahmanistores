/**
 * Centralized email sending utility using Brevo (Sendinblue) API.
 */
export async function sendOtpEmail(email, name, otpCode) {
  const apiKey = process.env.BREVO_API_KEY;
  if (!apiKey) {
    console.warn('⚠️ No BREVO_API_KEY found, skipping real email send. OTP:', otpCode);
    return;
  }
  
  // Premium Brahmani Theme Email Template
  const htmlContent = `
    <!DOCTYPE html>
    <html lang="gu">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Brahmani Stores OTP</title>
      <style>
        body {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          background-color: #f4f7f6;
          margin: 0;
          padding: 0;
        }
        .container {
          max-width: 600px;
          margin: 40px auto;
          background: #ffffff;
          border-radius: 20px;
          overflow: hidden;
          box-shadow: 0 15px 35px rgba(16, 185, 129, 0.08);
          border: 1px solid #d1fae5;
        }
        .header {
          background: transparent;
          padding: 40px 20px 20px 20px;
          text-align: center;
          position: relative;
        }
        .header::after {
          content: '';
          position: absolute;
          bottom: 0;
          left: 10%;
          right: 10%;
          height: 2px;
          background: linear-gradient(90deg, transparent, #10b981, transparent);
        }
        .logo-container {
          width: 100px;
          height: 100px;
          margin: 0 auto 20px auto;
          background: #ffffff;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          border: 4px solid #10b981;
          box-shadow: 0 4px 15px rgba(16, 185, 129, 0.2);
          overflow: hidden;
        }
        .logo-container img {
          width: 100%;
          height: 100%;
          object-fit: cover;
        }
        .header h1 {
          margin: 0;
          font-size: 32px;
          font-weight: 800;
          letter-spacing: 1px;
          color: #047857;
          text-shadow: none;
        }
        .header p {
          margin: 5px 0 0 0;
          font-size: 16px;
          color: #059669;
          font-weight: 600;
        }
        .content {
          padding: 40px 30px;
          text-align: center;
          color: #334155;
        }
        .content h2 {
          color: #047857;
          font-size: 24px;
          margin-top: 0;
          font-weight: 700;
        }
        .content p.welcome-text {
          font-size: 18px;
          line-height: 1.6;
          margin-bottom: 35px;
          color: #475569;
        }
        .otp-box {
          background: #ecfdf5;
          border: 2px dashed #10b981;
          border-radius: 16px;
          padding: 30px 20px;
          margin: 0 auto;
          max-width: 350px;
          box-shadow: inset 0 2px 10px rgba(16, 185, 129, 0.1);
        }
        .otp-label {
          font-size: 14px;
          color: #059669;
          text-transform: uppercase;
          letter-spacing: 2px;
          margin-bottom: 10px;
          font-weight: bold;
        }
        .otp-code {
          font-size: 56px;
          font-weight: 900;
          color: #047857;
          letter-spacing: 12px;
          margin: 0;
          text-shadow: 1px 1px 2px rgba(4, 120, 87, 0.2);
        }
        .warning {
          display: inline-block;
          margin-top: 30px;
          font-size: 15px;
          color: #b45309;
          background: #fffbeb;
          padding: 10px 20px;
          border-radius: 30px;
          border: 1px solid #fde68a;
          font-weight: 500;
        }
        .footer {
          background: #fafaf9;
          padding: 25px;
          text-align: center;
          font-size: 14px;
          color: #78716c;
          border-top: 1px solid #e7e5e4;
        }
        .footer p {
          margin: 5px 0;
        }
        .footer-logo {
          font-weight: bold;
          color: #059669;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="logo-container">
            <img src="https://mmbjhsqvmgqpqntihiap.supabase.co/storage/v1/object/public/brahmani/assets/brahmani_mata_logo.png" alt="Brahmani Mata Logo" />
          </div>
          <h1>શ્રી બ્રહ્માણી સ્ટોર્સ</h1>
          <p>|| જય બ્રહ્માણી માતા ||</p>
        </div>
        <div class="content">
          <h2>નમસ્તે, ${name}! 🙏</h2>
          <p class="welcome-text">બ્રહ્માણી પ્રોવિઝન સ્ટોર્સમાં જોડાવા બદલ તમારો ખૂબ ખૂબ આભાર. તમારું એકાઉન્ટ ચાલુ કરવા માટે નીચે આપેલ સિક્યોરિટી કોડ (OTP) નો ઉપયોગ કરો:</p>
          
          <div class="otp-box">
            <div class="otp-label">તમારો OTP કોડ</div>
            <p class="otp-code">${otpCode}</p>
          </div>
          
          <div class="warning">
            ⏳ આ કોડ માત્ર 10 મિનિટ માટે જ માન્ય રહેશે.
          </div>
          
          <p style="margin-top: 35px; font-size: 15px; color: #94a3b8;">
            જો તમે આ રિક્વેસ્ટ નથી કરી, તો કૃપા કરીને આ ઈમેલને અવગણો.
          </p>
        </div>
        <div class="footer">
          <p>&copy; ${new Date().getFullYear()} <span class="footer-logo">Brahmani Provision Stores</span>. All rights reserved.</p>
          <p>આ એક ઓટોમેટેડ ઈમેલ છે, કૃપા કરીને આનો રિપ્લાય ન આપશો.</p>
        </div>
      </div>
    </body>
    </html>
  `;

  try {
    const response = await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: {
        'api-key': apiKey,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        sender: { name: 'Brahmani Stores', email: 'vipulpatel4672@gmail.com' },
        to: [{ email, name }],
        subject: 'Brahmani Stores - તમારો વેરિફિકેશન કોડ (OTP)',
        htmlContent: htmlContent
      })
    });
    
    if (!response.ok) {
      const errText = await response.text();
      console.error('Failed to send Brevo email:', errText);
    } else {
      console.log('✅ Custom OTP email sent to', email);
    }
  } catch (err) {
    console.error('Failed to send Brevo email (Network):', err);
  }
}
