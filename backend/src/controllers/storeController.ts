import { Request, Response } from 'express';
import { Store } from '../models/Store';

export const createStore = async (req: Request, res: Response): Promise<void> => {
  try {
    const store = await Store.create(req.body);
    res.status(201).json({ success: true, data: store });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to create store', errorCode: 'CREATE_STORE_ERROR' });
  }
};

export const getStores = async (req: Request, res: Response): Promise<void> => {
  try {
    const stores = await Store.find();
    res.status(200).json({ success: true, data: stores });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to get stores', errorCode: 'GET_STORES_ERROR' });
  }
};

export const updateStore = async (req: Request, res: Response): Promise<void> => {
  try {
    const store = await Store.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!store) {
      res.status(404).json({ success: false, message: 'Store not found', errorCode: 'NOT_FOUND' });
      return;
    }
    res.status(200).json({ success: true, data: store });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to update store', errorCode: 'UPDATE_STORE_ERROR' });
  }
};

export const deleteStore = async (req: Request, res: Response): Promise<void> => {
  try {
    const store = await Store.findByIdAndDelete(req.params.id);
    if (!store) {
      res.status(404).json({ success: false, message: 'Store not found', errorCode: 'NOT_FOUND' });
      return;
    }
    res.status(200).json({ success: true, message: 'Store deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to delete store', errorCode: 'DELETE_STORE_ERROR' });
  }
};
