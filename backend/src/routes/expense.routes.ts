import { Router } from 'express';
import {
  createExpense,
  getExpenses,
  getExpense,
  updateExpense,
  deleteExpense,
  createExpenseSchema,
  updateExpenseSchema,
} from '../controllers/expense.controller';
import { validate } from '../middlewares/validate.middleware';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

// Protect all expense routes
router.use(authMiddleware);

router
  .route('/')
  .post(validate(createExpenseSchema), createExpense)
  .get(getExpenses);

router
  .route('/:id')
  .get(getExpense)
  .put(validate(updateExpenseSchema), updateExpense)
  .delete(deleteExpense);

export default router;
