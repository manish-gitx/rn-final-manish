import { Router } from 'express';
import multer from 'multer';
import { sendMessageHandler } from '../controllers/conversation.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import logger from '../../utils/logger';

const router = Router();

const upload = multer({
    storage: multer.memoryStorage(),
    limits: {
        fileSize: 10 * 1024 * 1024, // 10MB
    },
    fileFilter: (req, file, cb) => {
        const allowedTypes = [
            'audio/mpeg',
            'audio/wav',
            'audio/mp3',
            'audio/webm',
            'audio/m4a',
            'audio/x-m4a',
            'audio/mp4', // M4A files often come with this MIME type
            'audio/ogg',
            'audio/ogg; codecs=opus',
            'application/octet-stream', // Some clients send this for audio files
        ];
        
        const mimetype = file.mimetype.toLowerCase();
        const isValidType = allowedTypes.includes(mimetype) || mimetype.startsWith('audio/');
        
        if (isValidType) {
            logger.info('Audio file accepted', { 
                mimetype: file.mimetype, 
                originalname: file.originalname 
            });
            cb(null, true);
        } else {
            logger.warn('Invalid file type rejected', { 
                mimetype: file.mimetype, 
                originalname: file.originalname 
            });
            cb(new Error(`Invalid file type: ${file.mimetype}. Only audio files are allowed.`));
        }
    },
});

// Multer error handler middleware
const handleMulterError = (err: any, req: any, res: any, next: any) => {
    if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({ 
                error: 'File too large',
                message: 'Audio file must be less than 10MB'
            });
        }
        return res.status(400).json({ 
            error: 'File upload error',
            message: err.message
        });
    }
    if (err) {
        // File type validation error
        return res.status(400).json({ 
            error: 'Invalid file type',
            message: err.message
        });
    }
    next();
};

router.post('/send-message', authMiddleware, (req, res, next) => {
    upload.single('audio')(req, res, (err) => {
        if (err) {
            return handleMulterError(err, req, res, next);
        }
        next();
    });
}, sendMessageHandler);

export default router;
