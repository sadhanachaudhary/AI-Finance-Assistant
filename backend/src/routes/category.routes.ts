import { Router } from 'express';
import {
  createCategory,
  getCategories,
  updateCategory,
  deleteCategory,
  createCategorySchema,
  updateCategorySchema,
} from '../controllers/category.controller';
import { validate } from '../middlewares/validate.middleware';
import { authMiddleware } from '../middlewares/auth.middleware';

const router = Router();

// Protect all category routes
router.use(authMiddleware);

router
  .route('/')
  .post(validate(createCategorySchema), createCategory)
  .get(getCategories);

router
  .route('/:id')
  .put(validate(updateCategorySchema), updateCategory)
  .delete(deleteCategory);

export default router;
