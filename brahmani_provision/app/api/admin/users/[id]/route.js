import { NextResponse } from 'next/server';
import { db } from '@/lib/db';
import { headers } from 'next/headers';
import jwt from 'jsonwebtoken';

async function verifyAdmin() {
  const headersList = await headers();
  const authorization = headersList.get('authorization');

  if (!authorization || !authorization.startsWith('Bearer ')) {
    return null;
  }

  try {
    const token = authorization.split(' ')[1];
    const jwtSecret = process.env.JWT_SECRET || 'fallback-secret-for-dev';
    const decoded = jwt.verify(token, jwtSecret);

    if (decoded.role !== 'ADMIN') {
      return null;
    }

    return decoded;
  } catch (e) {
    return null;
  }
}

export async function PUT(req, { params }) {
  const adminUser = await verifyAdmin();
  if (!adminUser) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const { id } = await params;
    const body = await req.json();

    const updatedUser = await db.user.update({
      where: { id: id },
      data: {
        firstName: body.firstName,
        lastName: body.lastName,
        email: body.email,
        phone: body.phone,
        role: body.role,
        status: body.status,
      },
    });

    return NextResponse.json({ message: 'User updated', user: updatedUser });
  } catch (error) {
    console.error('Error updating user:', error);
    return NextResponse.json({ error: 'Failed to update user' }, { status: 500 });
  }
}

export async function DELETE(req, { params }) {
  const adminUser = await verifyAdmin();
  if (!adminUser) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const { id } = await params;

    await db.user.delete({
      where: { id: id },
    });

    return NextResponse.json({ message: 'User deleted successfully' });
  } catch (error) {
    console.error('Error deleting user:', error);
    return NextResponse.json({ error: 'Failed to delete user' }, { status: 500 });
  }
}
