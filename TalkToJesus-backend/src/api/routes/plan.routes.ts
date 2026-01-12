import { Router } from 'express';
import { getPlansHandler } from '../controllers/plan.controller';

const router = Router();

router.get('/', getPlansHandler);

export default router;
