import { z } from 'zod';

export const registerSchema = z.object({
  username: z.string().min(3).max(30),
  email: z.string().email(),
  password: z.string().min(6),
  role: z.enum(['Admin', 'Manager', 'Viewer']).optional(),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});

export const storeSchema = z.object({
  store_name: z.string().min(1),
  address: z.string().min(1),
  timezone: z.string(),
  opening_hours: z.string(),
  status: z.enum(['Active', 'Inactive']).optional(),
});

export const cameraSchema = z.object({
  camera_name: z.string().min(1),
  rtsp_url: z.string().url(),
  camera_location: z.string(),
  status: z.enum(['Active', 'Inactive', 'Maintenance']).optional(),
  assigned_store: z.string().regex(/^[0-9a-fA-F]{24}$/, 'Invalid ObjectId'),
});
