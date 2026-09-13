import { Router } from 'express';
import { getAnalyticsSummary, getRecurringExpenses, getSpendingForecast } from '../controllers/analytics.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

// Protect analytics routes
router.use(authMiddleware);

router.get('/summary', getAnalyticsSummary);
router.get('/recurring', getRecurringExpenses);
router.get('/forecast', getSpendingForecast);

export default router;
