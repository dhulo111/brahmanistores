import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { sendOtpEmail } from '@/lib/email';

export async function POST(req) {
  try {
    const { email, firstName, lastName } = await req.json();

    if (!email || !firstName) {
      return NextResponse.json({ error: 'error_missing_fields' }, { status: 400 });
    }

    // Check if user already exists
    const existingUser = await db.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      return NextResponse.json(
        { error: 'error_email_in_use' },
        { status: 400 }
      );
    }

    // Generate 4-digit OTP
    const otpCode = Math.floor(1000 + Math.random() * 9000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes from now

    // Upsert OtpRecord
    await db.otpRecord.upsert({
      where: { email },
      update: {
        otpCode,
        expiresAt,
        createdAt: new Date(),
      },
      create: {
        email,
        otpCode,
        expiresAt,
      },
    });

    // Send OTP via Brevo
    const fullName = lastName ? `${firstName} ${lastName}` : firstName;
    await sendOtpEmail(email, fullName, otpCode);

    return NextResponse.json({ message: 'OTP sent successfully' }, { status: 200 });
  } catch (error) {
    console.error('🔥 Send OTP error:', error);
    return NextResponse.json(
      { error: 'error_internal_server', details: error.message || String(error) },
      { status: 500 }
    );
  }
}
