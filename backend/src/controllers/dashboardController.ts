import { Request, Response } from 'express';
import * as aiClient from '../ai/aiClient';
import { Store } from '../models/Store';

export const getOverview = async (req: Request, res: Response): Promise<void> => {
  try {
    const storesCount = await Store.countDocuments();
    let aiStatus = null;
    try {
      aiStatus = await aiClient.getStatus();
    } catch (e) {
      console.error('AI Service unavailable');
    }
    
    res.status(200).json({
      success: true,
      data: {
        active_stores: storesCount,
        ai_engine_status: aiStatus ? 'Online' : 'Offline',
        total_entered: aiStatus?.total_entered || 0,
        current_occupancy: aiStatus?.current_occupancy || 0,
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch overview', errorCode: 'DASHBOARD_ERROR' });
  }
};

export const getLiveStats = async (req: Request, res: Response): Promise<void> => {
  try {
    const aiStatus = await aiClient.getStatus();
    res.status(200).json({ success: true, data: aiStatus });
  } catch (error) {
    res.status(503).json({ success: false, message: 'AI Engine unavailable', errorCode: 'AI_OFFLINE' });
  }
};

export const getEvents = async (req: Request, res: Response): Promise<void> => {
  try {
    const events = await aiClient.getEvents();
    res.status(200).json({ success: true, data: events });
  } catch (error) {
    res.status(503).json({ success: false, message: 'AI Engine unavailable', errorCode: 'AI_OFFLINE' });
  }
};
