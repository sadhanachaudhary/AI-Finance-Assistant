import { Router } from 'express';
import { register, login, registerSchema, loginSchema } from '../controllers/auth.controller';
import { validate } from '../middlewares/validate.middleware';

const router = Router();

router.post('/register', validate(registerSchema), register);
router.post('/login', validate(loginSchema), login);

export default router;
