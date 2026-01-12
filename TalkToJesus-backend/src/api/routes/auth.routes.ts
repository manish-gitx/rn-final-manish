import { Router } from 'express';
import { createOrGetUserHandler } from '../controllers/auth.controller';

const router = Router();

router.post('/create-or-get-user', createOrGetUserHandler);

export default router;
