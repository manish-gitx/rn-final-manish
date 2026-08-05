import { Router } from 'express';
import { authMiddleware } from '../middlewares/auth.middleware';
import { adminMiddleware } from '../middlewares/admin.middleware';
import {
    adminLoginHandler,
    meHandler,
    overviewHandler,
    timeseriesHandler,
    languagesHandler,
    latencyHandler,
    listUsersHandler,
    updateUserHandler,
    listSongsHandler,
    createSongHandler,
    updateSongHandler,
    deleteSongHandler,
    listConversationsHandler,
    listWebhooksHandler,
    healthHandler,
    listFlagsHandler,
    updateFlagHandler,
    auditLogHandler,
} from '../controllers/admin.controller';

const router = Router();

// Public: exchanges ADMIN_EMAIL/ADMIN_PASSWORD for a normal user JWT.
router.post('/login', adminLoginHandler);

// Everything below requires a valid JWT AND users.is_admin = true.
router.use(authMiddleware, adminMiddleware);

router.get('/me', meHandler);

// Analytics
router.get('/stats/overview', overviewHandler);
router.get('/stats/timeseries', timeseriesHandler);
router.get('/stats/languages', languagesHandler);
router.get('/stats/latency', latencyHandler);

// Users
router.get('/users', listUsersHandler);
router.patch('/users/:id', updateUserHandler);

// Songs (full CRUD)
router.get('/songs', listSongsHandler);
router.post('/songs', createSongHandler);
router.patch('/songs/:id', updateSongHandler);
router.delete('/songs/:id', deleteSongHandler);

// Operations
router.get('/conversations', listConversationsHandler);
router.get('/webhooks', listWebhooksHandler);
router.get('/health', healthHandler);
router.get('/flags', listFlagsHandler);
router.patch('/flags', updateFlagHandler);
router.get('/audit', auditLogHandler);

export default router;
