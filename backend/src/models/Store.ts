import mongoose, { Document, Schema } from 'mongoose';

export interface IStore extends Document {
  store_name: string;
  address: string;
  timezone: string;
  opening_hours: string;
  status: 'Active' | 'Inactive';
  createdAt: Date;
  updatedAt: Date;
}

const storeSchema = new Schema<IStore>(
  {
    store_name: { type: String, required: true },
    address: { type: String, required: true },
    timezone: { type: String, required: true },
    opening_hours: { type: String, required: true },
    status: { type: String, enum: ['Active', 'Inactive'], default: 'Active' },
  },
  { timestamps: true }
);

export const Store = mongoose.model<IStore>('Store', storeSchema);
