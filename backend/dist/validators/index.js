"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.cameraSchema = exports.storeSchema = exports.loginSchema = exports.registerSchema = void 0;
const zod_1 = require("zod");
exports.registerSchema = zod_1.z.object({
    username: zod_1.z.string().min(3).max(30),
    email: zod_1.z.string().email(),
    password: zod_1.z.string().min(6),
    role: zod_1.z.enum(['Admin', 'Manager', 'Viewer']).optional(),
});
exports.loginSchema = zod_1.z.object({
    email: zod_1.z.string().email(),
    password: zod_1.z.string().min(6),
});
exports.storeSchema = zod_1.z.object({
    store_name: zod_1.z.string().min(1),
    address: zod_1.z.string().min(1),
    timezone: zod_1.z.string(),
    opening_hours: zod_1.z.string(),
    status: zod_1.z.enum(['Active', 'Inactive']).optional(),
});
exports.cameraSchema = zod_1.z.object({
    camera_name: zod_1.z.string().min(1),
    rtsp_url: zod_1.z.string().url(),
    camera_location: zod_1.z.string(),
    status: zod_1.z.enum(['Active', 'Inactive', 'Maintenance']).optional(),
    assigned_store: zod_1.z.string().regex(/^[0-9a-fA-F]{24}$/, 'Invalid ObjectId'),
});
