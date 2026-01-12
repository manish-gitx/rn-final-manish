import { Router } from 'express';
import { getSongsHandler } from '../controllers/song.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

router.get('/', authMiddleware, getSongsHandler);

export default router;
