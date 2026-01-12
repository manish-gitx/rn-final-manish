import { Request, Response } from 'express';
import { z } from 'zod';
import { getSongs } from '../services/song.service';

const getSongsSchema = z.object({
    page: z.string().optional().default('1'),
    limit: z.string().optional().default('10'),
    search: z.string().optional(),
});

export const getSongsHandler = async (req: Request, res: Response) => {
    try {
        const { page, limit, search } = getSongsSchema.parse(req.query);
        const songs = await getSongs(Number(page), Number(limit), search);
        res.status(200).json(songs);
    } catch (error: any) {
        if (error instanceof z.ZodError) {
            return res.status(400).json({ message: 'Invalid query parameters', error: error.message });
        }
        res.status(500).json({ message: error.message });
    }
};
