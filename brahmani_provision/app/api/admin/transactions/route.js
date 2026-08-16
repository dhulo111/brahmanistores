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
    const { userId, amount, description, type } = body; // type: 'UDHAR' or 'JAMA'

    if (!userId || !amount || !description || !['UDHAR', 'JAMA'].includes(type)) {
      return NextResponse.json({ error: 'invalid_request' }, { status: 400 });
    }

    const parsedAmount = parseFloat(amount);
    if (isNaN(parsedAmount) || parsedAmount <= 0) {
       return NextResponse.json({ error: 'invalid_amount' }, { status: 400 });
    }

    const user = await db.user.findUnique({ where: { id: userId } });
    
    if (!user) {
      return NextResponse.json({ error: 'user_not_found' }, { status: 404 });
    }

    // Balance logic:
    // UDHAR (Debit - taking goods on credit) increases outstanding balance (baaki)
    // JAMA (Credit - paying money back) decreases outstanding balance (baaki)
    const balanceChange = type === 'UDHAR' ? parsedAmount : -parsedAmount;
    
    // Create transaction and update user balance in a transaction
    const [transaction, updatedUser] = await db.$transaction([
      db.transaction.create({
        data: {
          userId,
          amount: parsedAmount,
          description,
          type,
        }
      }),
      db.user.update({
        where: { id: userId },
        data: {
          balance: {
            increment: balanceChange
          }
        }
      })
    ]);

    // Send push notification to user
    if (updatedUser.fcmToken) {
      const title = type === 'UDHAR' ? 'નવી ઉધાર એન્ટ્રી (New Bill)' : 'નવી જમા એન્ટ્રી (Payment Received)';
      
      const shortDesc = description.length > 40 ? description.substring(0, 40) + '...' : description;
      const bodyText = type === 'UDHAR' 
        ? `₹${parsedAmount} નું ઉધાર બિલ ઉમેરાયું છે. (વિગત: ${shortDesc})\nકુલ બાકી: ₹${updatedUser.balance}`
        : `₹${parsedAmount} જમા થયા છે. (વિગત: ${shortDesc})\nકુલ બાકી: ₹${updatedUser.balance}`;
        
      await sendNotification(updatedUser.fcmToken, title, bodyText, {
        type: 'transaction',
        transactionId: transaction.id
      });
    }

    return NextResponse.json({ message: 'success', transaction, balance: updatedUser.balance }, { status: 201 });
  } catch (error) {
    console.error('Create transaction error:', error);
    return NextResponse.json({ error: 'error_internal_server' }, { status: 500 });
  }
}

export async function GET(req) {
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

    const transactions = await db.transaction.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        user: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
            phone: true,
          }
        }
      }
    });

    return NextResponse.json({ transactions }, { status: 200 });
  } catch (error) {
    console.error('Fetch all transactions error:', error);
    return NextResponse.json({ error: 'error_internal_server' }, { status: 500 });
  }
}

