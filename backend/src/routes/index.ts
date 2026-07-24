import { Router } from 'express';
import authRoutes from './authRoutes';
import storeRoutes from './storeRoutes';
import cameraRoutes from './cameraRoutes';
import dashboardRoutes from './dashboardRoutes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/stores', storeRoutes);
router.use('/cameras', cameraRoutes);
router.use('/dashboard', dashboardRoutes);

export default router;
