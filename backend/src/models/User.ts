import mongoose, { Document, Schema } from 'mongoose';

export interface IUser extends Document {
  username: string;
  email: string;
  password_hash: string;
  role: 'Admin' | 'Manager' | 'Viewer';
  createdAt: Date;
  updatedAt: Date;
}

const userSchema = new Schema<IUser>(
  {
    username: { type: String, required: true, unique: true },
    email: { type: String, required: true, unique: true },
    password_hash: { type: String, required: true },
    role: { type: String, enum: ['Admin', 'Manager', 'Viewer'], default: 'Viewer' },
  },
  { timestamps: true }
);

export const User = mongoose.model<IUser>('User', userSchema);
