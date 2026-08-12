import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import jwt from 'jsonwebtoken';
import { sendNotification } from '@/lib/firebase';

export async function POST(req) {
  try {
    const authHeader = req.headers.get('authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'error_unauthorized' }, { status: 401 });
    }

    const token = authHeader.split(' ')[1];
    const jwtSecret = process.env.JWT_SECRET || 'fallback-secret-for-dev';
    
    let decoded;
    try {
      decoded = jwt.verify(token, jwtSecret);
    } catch (e) {
      return NextResponse.json({ error: 'error_unauthorized' }, { status: 401 });
    }

    if (decoded.role !== 'ADMIN') {
      return NextResponse.json({ error: 'error_forbidden' }, { status: 403 });
    }

    const body = await req.json();
    const { userId, action } = body; // action: 'APPROVE' or 'REJECT'

    if (!userId || !['APPROVE', 'REJECT'].includes(action)) {
      return NextResponse.json({ error: 'invalid_request' }, { status: 400 });
    }

    const user = await db.user.findUnique({ where: { id: userId } });
    
    if (!user) {
      return NextResponse.json({ error: 'user_not_found' }, { status: 404 });
    }

    const newStatus = action === 'APPROVE' ? 'APPROVED' : 'REJECTED';

    await db.user.update({
      where: { id: userId },
      data: { status: newStatus },
    });

    // Send push notification to user
    if (user.fcmToken) {
      if (newStatus === 'APPROVED') {
        await sendNotification(
          user.fcmToken,
          'ખાતું મંજૂર થયું!', // Account Approved!
          'તમારું એકાઉન્ટ મંજૂર કરવામાં આવ્યું છે. તમે હવે લૉગિન કરી શકો છો.' // Your account has been approved. You can now login.
        );
      } else {
        await sendNotification(
          user.fcmToken,
          'ખાતું નામંજૂર થયું', // Account Rejected
          'તમારી એકાઉન્ટ રજીસ્ટ્રેશન વિનંતી નકારી કાઢવામાં આવી છે.' // Your account registration request has been rejected.
        );
      }
    }

    return NextResponse.json({ message: 'success', status: newStatus });
  } catch (error) {
    console.error('Approve user error:', error);
    return NextResponse.json({ error: 'error_internal_server' }, { status: 500 });
  }
}
