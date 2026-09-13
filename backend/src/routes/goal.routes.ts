import { Router } from 'express';
import {
  getGoals,
  getGoalById,
  createGoal,
  updateGoal,
  depositToGoal,
  deleteGoal,
  createGoalSchema,
  updateGoalSchema,
  depositGoalSchema,
} from '../controllers/goal.controller';
import { authMiddleware } from '../middlewares/auth.middleware';
import { validate } from '../middlewares/validate.middleware';

const router = Router();

router.use(authMiddleware);

router.get('/', getGoals);
router.get('/:id', getGoalById);
router.post('/', validate(createGoalSchema), createGoal);
router.put('/:id', validate(updateGoalSchema), updateGoal);
router.post('/:id/deposit', validate(depositGoalSchema), depositToGoal);
router.delete('/:id', deleteGoal);

export default router;
