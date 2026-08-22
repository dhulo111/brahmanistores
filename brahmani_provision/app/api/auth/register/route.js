import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { supabase } from '@/lib/supabase';
import { registerSchema } from '@/lib/validations/auth';
import bcrypt from 'bcrypt';
import { sendNotification } from '@/lib/firebase';
import { sendOtpEmail } from '@/lib/email';

export async function POST(req) {
  console.log('📥 Received registration request!');
  try {
    const formData = await req.formData();
    console.log('✅ Parsed FormData');
    const firstName = formData.get('firstName');
    const lastName = formData.get('lastName');
    const email = formData.get('email');
    const phone = formData.get('phone');
    const password = formData.get('password');
    const role = formData.get('role') || 'USER'; // Default to USER
    const avatar = formData.get('avatar'); // File object
    const otpCode = formData.get('otpCode'); // Extract OTP code

    if (!otpCode) {
      return NextResponse.json({ error: 'error_missing_otp', message: 'OTP is required' }, { status: 400 });
    }

    // Validate using Zod
    const validationResult = registerSchema.safeParse({
      firstName,
      lastName,
      email,
      phone,
      password,
    });

    if (!validationResult.success) {
      return NextResponse.json(
        { error: 'validation_error', details: validationResult.error.errors },
        { status: 400 }
      );
    }

    // Check if user exists
    const existingUser = await db.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      return NextResponse.json(
        { error: 'error_email_in_use' },
        { status: 400 }
      );
    }

    // Verify OTP
    const otpRecord = await db.otpRecord.findUnique({
      where: { email },
    });

    if (!otpRecord) {
      return NextResponse.json({ error: 'error_otp_not_found', message: 'Please request a new OTP' }, { status: 400 });
    }

    if (otpRecord.otpCode !== otpCode) {
      return NextResponse.json({ error: 'error_invalid_otp', message: 'અમાન્ય OTP' }, { status: 400 });
    }

    if (new Date() > otpRecord.expiresAt) {
      return NextResponse.json({ error: 'error_otp_expired', message: 'આ OTP સમયસમાપ્ત થઈ ગયો છે' }, { status: 400 });
    }

    let publicUrl = '';
    const avatarUrl = formData.get('avatarUrl'); // String URL from Google

    if (avatarUrl && typeof avatarUrl === 'string' && avatarUrl.startsWith('http')) {
      // User registered with Google and provided a direct URL
      publicUrl = avatarUrl;
    } else {
      // Standard file upload
      if (!avatar || typeof avatar === 'string') {
        return NextResponse.json(
          { error: 'error_avatar_required' },
          { status: 400 }
        );
      }

      // Upload avatar to Supabase
      const avatarBuffer = await avatar.arrayBuffer();
      const avatarExt = avatar.name.split('.').pop();
      const avatarPath = `avatars/${Date.now()}_${Math.random().toString(36).substring(7)}.${avatarExt}`;
      
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('brahmani')
        .upload(avatarPath, avatarBuffer, {
          contentType: avatar.type,
        });

      if (uploadError) {
        console.error('Supabase upload error:', uploadError);
        return NextResponse.json(
          { error: 'error_avatar_upload_failed', details: uploadError.message || String(uploadError) },
          { status: 500 }
        );
      }

      const { data: urlData } = supabase.storage
        .from('brahmani')
        .getPublicUrl(avatarPath);
      
      publicUrl = urlData.publicUrl;
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);


    // Save to DB
    const newUser = await db.user.create({
      data: {
        firstName,
        lastName,
        email,
        phone,
        passwordHash,
        avatarUrl: publicUrl,
        role,
        status: role === 'ADMIN' ? 'APPROVED' : 'PENDING',
      },
    });

    // Delete OTP record after successful registration
    await db.otpRecord.delete({
      where: { email }
    });

    // Notify all Admins if a new regular user registers
    if (role !== 'ADMIN') {
      try {
        // Fetch all admins with FCM tokens
        const admins = await db.user.findMany({
          where: { role: 'ADMIN', fcmToken: { not: null } },
          select: { fcmToken: true }
        });
        
        for (const admin of admins) {
          await sendNotification(
            admin.fcmToken,
            'નવો વપરાશકર્તા!', // New user!
            `${firstName} ${lastName} એ રજીસ્ટ્રેશન કર્યું છે. મંજૂરી આપો.` // Registration completed. Approve it.
          );
        }
      } catch (e) {
        console.error('Failed to notify admins:', e);
      }
    }

    return NextResponse.json({
      message: 'success',
      user: {
        id: newUser.id,
        email: newUser.email,
        firstName: newUser.firstName,
        lastName: newUser.lastName,
      }
    }, { status: 201 });

  } catch (error) {
    console.error('🔥 Register error:', error);
    return NextResponse.json(
      { error: 'error_internal_server', details: error.message || String(error) },
      { status: 500 }
    );
  }
}
