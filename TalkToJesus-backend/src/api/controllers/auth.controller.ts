import { Request, Response } from 'express';
import { z } from 'zod';
import { createOrGetUser } from '../services/auth.service';

const createOrGetUserSchema = z.object({
    token: z.string(),
});

export const createOrGetUserHandler = async (req: Request, res: Response) => {
    try {
        const { token } = createOrGetUserSchema.parse(req.body);
        const { user, token: jwt } = await createOrGetUser(token);
        res.status(200).json({ user, token: jwt });
    } catch (error: any) {
        if (error instanceof z.ZodError) {
            return res.status(400).json({ message: 'Invalid request body', error: error.message });
        }
        res.status(500).json({ message: error.message });
    }
};
