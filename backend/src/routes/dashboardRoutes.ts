import { Router } from 'express';
import { getOverview, getLiveStats, getEvents } from '../controllers/dashboardController';
import { authenticate } from '../middleware/auth';

const router = Router();

router.use(authenticate);

router.get('/overview', getOverview);
router.get('/live', getLiveStats);
router.get('/events', getEvents);

export default router;
