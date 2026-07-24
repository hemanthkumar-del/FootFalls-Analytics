import { Router } from 'express';
import { createCamera, getCameras, updateCamera, deleteCamera } from '../controllers/cameraController';
import { authenticate, authorize } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { cameraSchema } from '../validators';

const router = Router();

router.use(authenticate);

router.get('/', getCameras);
router.post('/', authorize(['Admin', 'Manager']), validate(cameraSchema), createCamera);
router.put('/:id', authorize(['Admin', 'Manager']), validate(cameraSchema), updateCamera);
router.delete('/:id', authorize(['Admin']), deleteCamera);

export default router;
