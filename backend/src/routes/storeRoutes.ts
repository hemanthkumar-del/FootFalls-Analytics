import { Router } from 'express';
import { createStore, getStores, updateStore, deleteStore } from '../controllers/storeController';
import { authenticate, authorize } from '../middleware/auth';
import { validate } from '../middleware/validate';
import { storeSchema } from '../validators';

const router = Router();

router.use(authenticate);

router.get('/', getStores);
router.post('/', authorize(['Admin', 'Manager']), validate(storeSchema), createStore);
router.put('/:id', authorize(['Admin', 'Manager']), validate(storeSchema), updateStore);
router.delete('/:id', authorize(['Admin']), deleteStore);

export default router;
