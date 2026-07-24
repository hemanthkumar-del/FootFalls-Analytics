import mongoose, { Document, Schema } from 'mongoose';

export interface ICamera extends Document {
  camera_name: string;
  rtsp_url: string;
  camera_location: string;
  status: 'Active' | 'Inactive' | 'Maintenance';
  assigned_store: mongoose.Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

const cameraSchema = new Schema<ICamera>(
  {
    camera_name: { type: String, required: true },
    rtsp_url: { type: String, required: true },
    camera_location: { type: String, required: true },
    status: { type: String, enum: ['Active', 'Inactive', 'Maintenance'], default: 'Active' },
    assigned_store: { type: Schema.Types.ObjectId, ref: 'Store', required: true },
  },
  { timestamps: true }
);

export const Camera = mongoose.model<ICamera>('Camera', cameraSchema);
