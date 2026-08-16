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

    const updatedProduct = await db.product.update({
      where: { id: id },
      data: {
        name: body.name,
        englishName: body.englishName,
        price: parseFloat(body.price),
        isAvailable: body.isAvailable,
      },
    });

    return NextResponse.json({ message: 'Product updated', product: updatedProduct });
  } catch (error) {
    console.error('Error updating product:', error);
    return NextResponse.json({ error: 'Failed to update product' }, { status: 500 });
  }
}

export async function DELETE(req, { params }) {
  const adminUser = await verifyAdmin();
  if (!adminUser) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const { id } = await params;

    await db.product.delete({
      where: { id: id },
    });

    return NextResponse.json({ message: 'Product deleted successfully' });
  } catch (error) {
    console.error('Error deleting product:', error);
    return NextResponse.json({ error: 'Failed to delete product' }, { status: 500 });
  }
}
