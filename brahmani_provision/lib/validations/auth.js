import { z } from 'zod';

// Zod schemas with custom error codes mapped for Flutter/Gujarati translation
export const registerSchema = z.object({
  firstName: z.string().min(1, { message: 'error_first_name_required' }),
  lastName: z.string().min(1, { message: 'error_last_name_required' }),
  email: z.string().email({ message: 'error_invalid_email' }),
  phone: z.string().min(10, { message: 'error_invalid_phone' }),
  password: z
    .string()
    .min(8, { message: 'error_password_too_short' })
    .regex(/[A-Z]/, { message: 'error_password_no_uppercase' })
    .regex(/[a-z]/, { message: 'error_password_no_lowercase' })
    .regex(/[0-9]/, { message: 'error_password_no_number' })
    .regex(/[^A-Za-z0-9]/, { message: 'error_password_no_special' }),
  // The avatar URL will be verified separately, but we can expect the file in FormData
});

export const loginSchema = z.object({
  emailOrUsername: z.string().min(1, { message: 'error_email_username_required' }),
  password: z.string().min(1, { message: 'error_password_required' }),
});
