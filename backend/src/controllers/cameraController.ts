import { Request, Response } from 'express';
import { Camera } from '../models/Camera';

export const createCamera = async (req: Request, res: Response): Promise<void> => {
  try {
    const camera = await Camera.create(req.body);
    res.status(201).json({ success: true, data: camera });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to create camera', errorCode: 'CREATE_CAMERA_ERROR' });
  }
};

export const getCameras = async (req: Request, res: Response): Promise<void> => {
  try {
    const cameras = await Camera.find().populate('assigned_store');
    res.status(200).json({ success: true, data: cameras });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to get cameras', errorCode: 'GET_CAMERAS_ERROR' });
  }
};

export const updateCamera = async (req: Request, res: Response): Promise<void> => {
  try {
    const camera = await Camera.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!camera) {
      res.status(404).json({ success: false, message: 'Camera not found', errorCode: 'NOT_FOUND' });
      return;
    }
    res.status(200).json({ success: true, data: camera });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to update camera', errorCode: 'UPDATE_CAMERA_ERROR' });
  }
};

export const deleteCamera = async (req: Request, res: Response): Promise<void> => {
  try {
    const camera = await Camera.findByIdAndDelete(req.params.id);
    if (!camera) {
      res.status(404).json({ success: false, message: 'Camera not found', errorCode: 'NOT_FOUND' });
      return;
    }
    res.status(200).json({ success: true, message: 'Camera deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to delete camera', errorCode: 'DELETE_CAMERA_ERROR' });
  }
};
