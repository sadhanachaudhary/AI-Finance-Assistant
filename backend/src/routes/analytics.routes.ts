import { Router } from 'express';
import { getAnalyticsSummary } from '../controllers/analytics.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

router.use(authMiddleware);

router.get('/summary', getAnalyticsSummary);

export default router;
