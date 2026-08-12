import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis;

export const db = globalForPrisma.prisma || new PrismaClient();

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = db;

// Eagerly test the database connection and log the result
async function checkConnection() {
  try {
    await db.$connect();
    console.log('✅ Successfully connected to MongoDB database!');
  } catch (error) {
    console.error('❌ Failed to connect to MongoDB:', error.message);
    console.error('Please ensure your DATABASE_URL is correct and the database is running.');
  }
}

checkConnection();
