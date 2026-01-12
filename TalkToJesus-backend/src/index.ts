import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import morgan from 'morgan';
import dotenv from 'dotenv';
import apiRouter from './api/routes';
import logger from './utils/logger';

dotenv.config();

const app: Application = express();

app.use(cors());
app.use(morgan('combined', { stream: { write: (message) => logger.info(message.trim()) } }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get('/', (req: Request, res: Response) => {
    res.send({
        message: 'Talk to Jesus API is running!',
        version: '1.0.0',
        status: 'healthy',
        timestamp: new Date().toISOString(),
    });
});

app.use('/api', apiRouter);

const PORT = process.env.PORT || 4040;

app.listen(PORT, () => {
    logger.info(`Server is running on port ${PORT}`, { 
        port: PORT, 
        environment: process.env.NODE_ENV || 'development' 
    });
});
