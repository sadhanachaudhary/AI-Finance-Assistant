import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import prisma from '../config/prisma';

export const createExpenseSchema = z.object({
  body: z.object({
    amount: z.number().positive('Amount must be positive'),
    currency: z.string().optional(),
    date: z.string().datetime().optional().default(() => new Date().toISOString()),
    merchant: z.string().optional(),
    notes: z.string().optional(),
    categoryId: z.string().uuid().optional(),
  }),
});

export const updateExpenseSchema = z.object({
  body: z.object({
    amount: z.number().positive().optional(),
    currency: z.string().optional(),
    date: z.string().datetime().optional(),
    merchant: z.string().optional(),
    notes: z.string().optional(),
    categoryId: z.string().uuid().optional(),
  }),
});

export const createExpense = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const { amount, currency, date, merchant, notes, categoryId } = req.body;

    const expense = await prisma.expense.create({
      data: {
        userId,
        amount,
        currency,
        date,
        merchant,
        notes,
        categoryId,
      },
      include: {
        category: true,
      },
    });

    res.status(201).json({
      status: 'success',
      data: { expense },
    });
  } catch (error) {
    next(error);
  }
};

export const getExpenses = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;

    const expenses = await prisma.expense.findMany({
      where: { userId },
      orderBy: { date: 'desc' },
      include: {
        category: true,
      },
    });

    res.status(200).json({
      status: 'success',
      results: expenses.length,
      data: { expenses },
    });
  } catch (error) {
    next(error);
  }
};

export const getExpense = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const { id } = req.params;

    const expense = await prisma.expense.findFirst({
      where: { id, userId },
      include: { category: true, bill: true },
    });

    if (!expense) {
      return res.status(404).json({ status: 'fail', message: 'Expense not found' });
    }

    res.status(200).json({
      status: 'success',
      data: { expense },
    });
  } catch (error) {
    next(error);
  }
};

export const updateExpense = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const { id } = req.params;
    const { amount, currency, date, merchant, notes, categoryId } = req.body;

    // Verify ownership
    const existing = await prisma.expense.findFirst({ where: { id, userId } });
    if (!existing) {
      return res.status(404).json({ status: 'fail', message: 'Expense not found' });
    }

    const expense = await prisma.expense.update({
      where: { id },
      data: { amount, currency, date, merchant, notes, categoryId },
      include: { category: true },
    });

    res.status(200).json({
      status: 'success',
      data: { expense },
    });
  } catch (error) {
    next(error);
  }
};

export const deleteExpense = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const { id } = req.params;

    // Verify ownership
    const existing = await prisma.expense.findFirst({ where: { id, userId } });
    if (!existing) {
      return res.status(404).json({ status: 'fail', message: 'Expense not found' });
    }

    await prisma.expense.delete({ where: { id } });

    res.status(204).json({
      status: 'success',
      data: null,
    });
  } catch (error) {
    next(error);
  }
};
