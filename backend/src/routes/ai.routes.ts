import { Router } from 'express';
import { handleAiChat } from '../controllers/ai.controller';
import jwt from 'jsonwebtoken';

const router = Router();

// Optional auth: populate req.userId if valid token, otherwise allow controller to use demo user fallback
router.use((req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ') && process.env.JWT_SECRET) {
      const token = authHeader.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET) as { id: string };
      req.userId = decoded.id;
    }
  } catch (_) {
    // Ignore invalid token and let controller fallback
  }
  next();
});

router.post('/chat', handleAiChat);

export default router;
