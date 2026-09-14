import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import prisma from '../config/prisma';

export const createGoalSchema = z.object({
  body: z.object({
    name: z.string().min(1, 'Goal name is required'),
    targetAmount: z.number().positive('Target amount must be positive'),
    currentAmount: z.number().nonnegative().optional().default(0),
    currency: z.string().optional().default('INR'),
    deadline: z.string().optional(),
    category: z.string().optional(),
    color: z.string().optional(),
    icon: z.string().optional(),
  }),
});

export const updateGoalSchema = z.object({
  body: z.object({
    name: z.string().min(1).optional(),
    targetAmount: z.number().positive().optional(),
    currentAmount: z.number().nonnegative().optional(),
    currency: z.string().optional(),
    deadline: z.string().optional().nullable(),
    category: z.string().optional().nullable(),
    color: z.string().optional().nullable(),
    icon: z.string().optional().nullable(),
  }),
});

export const depositGoalSchema = z.object({
  body: z.object({
    amount: z.number().positive('Deposit amount must be positive'),
  }),
});

// GET /api/goals
export const getGoals = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const goals = await (prisma as any).goal.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    res.json({
      success: true,
      data: goals,
    });
  } catch (error) {
    next(error);
  }
};

// GET /api/goals/:id
export const getGoalById = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const id = req.params.id as string;

    const goal = await (prisma as any).goal.findFirst({
      where: { id, userId },
    });

    if (!goal) {
      return res.status(404).json({ success: false, message: 'Goal not found' });
    }

    res.json({ success: true, data: goal });
  } catch (error) {
    next(error);
  }
};

// POST /api/goals
export const createGoal = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const { name, targetAmount, currentAmount, currency, deadline, category, color, icon } = req.body;

    const goal = await (prisma as any).goal.create({
      data: {
        userId,
        name,
        targetAmount,
        currentAmount: currentAmount || 0,
        currency: currency || 'INR',
        deadline: deadline ? new Date(deadline) : null,
        category,
        color,
        icon,
      },
    });

    res.status(201).json({
      success: true,
      data: goal,
      message: 'Savings goal created successfully',
    });
  } catch (error) {
    next(error);
  }
};

// PUT /api/goals/:id
export const updateGoal = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const id = req.params.id as string;
    const { name, targetAmount, currentAmount, currency, deadline, category, color, icon } = req.body;

    const existingGoal = await (prisma as any).goal.findFirst({
      where: { id, userId },
    });

    if (!existingGoal) {
      return res.status(404).json({ success: false, message: 'Goal not found' });
    }

    const updatedGoal = await (prisma as any).goal.update({
      where: { id },
      data: {
        ...(name !== undefined && { name }),
        ...(targetAmount !== undefined && { targetAmount }),
        ...(currentAmount !== undefined && { currentAmount }),
        ...(currency !== undefined && { currency }),
        ...(deadline !== undefined && { deadline: deadline ? new Date(deadline) : null }),
        ...(category !== undefined && { category }),
        ...(color !== undefined && { color }),
        ...(icon !== undefined && { icon }),
      },
    });

    res.json({
      success: true,
      data: updatedGoal,
      message: 'Savings goal updated successfully',
    });
  } catch (error) {
    next(error);
  }
};

// POST /api/goals/:id/deposit
export const depositToGoal = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const id = req.params.id as string;
    const { amount } = req.body;

    const existingGoal = await (prisma as any).goal.findFirst({
      where: { id, userId },
    });

    if (!existingGoal) {
      return res.status(404).json({ success: false, message: 'Goal not found' });
    }

    const updatedGoal = await (prisma as any).goal.update({
      where: { id },
      data: {
        currentAmount: existingGoal.currentAmount + amount,
      },
    });

    res.json({
      success: true,
      data: updatedGoal,
      message: `Successfully contributed ${existingGoal.currency} ${amount} to "${existingGoal.name}"!`,
    });
  } catch (error) {
    next(error);
  }
};

// DELETE /api/goals/:id
export const deleteGoal = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const id = req.params.id as string;

    const existingGoal = await (prisma as any).goal.findFirst({
      where: { id, userId },
    });

    if (!existingGoal) {
      return res.status(404).json({ success: false, message: 'Goal not found' });
    }

    await (prisma as any).goal.delete({
      where: { id },
    });

    res.json({
      success: true,
      message: 'Goal deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};
