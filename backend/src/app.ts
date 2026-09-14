import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import { errorMiddleware } from './middlewares/error.middleware';

const app = express();

// Global Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check route with active database ping
import { checkDbHealth } from './config/prisma';

app.get('/health', async (req: Request, res: Response) => {
  const isDbHealthy = await checkDbHealth();
  if (isDbHealthy) {
    res.status(200).json({ status: 'ok', database: 'connected', timestamp: new Date().toISOString() });
  } else {
    res.status(503).json({ status: 'degraded', database: 'disconnected', timestamp: new Date().toISOString() });
  }
});

// API Routes will be mounted here
import authRoutes from './routes/auth.routes';
import categoryRoutes from './routes/category.routes';
import expenseRoutes from './routes/expense.routes';
import analyticsRoutes from './routes/analytics.routes';
import billRoutes from './routes/bill.routes';
import aiRoutes from './routes/ai.routes';
import goalRoutes from './routes/goal.routes';
import notificationRoutes from './routes/notification.routes';

app.use('/api/auth', authRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/bills', billRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/goals', goalRoutes);
app.use('/api/notifications', notificationRoutes);


// Global Error Handler
app.use(errorMiddleware);

export default app;
