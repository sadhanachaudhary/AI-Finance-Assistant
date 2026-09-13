import { Router } from 'express';
import { handleAiChat } from '../controllers/ai.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

// Protect all AI routes
router.use(authMiddleware);

router.post('/chat', handleAiChat);

export default router;
