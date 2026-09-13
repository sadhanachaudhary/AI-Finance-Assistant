import { Router } from 'express';
import { analyzeBill } from '../controllers/bill.controller';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

// Protect bill routes
router.use(authMiddleware);

router.post('/analyze', analyzeBill);

export default router;
