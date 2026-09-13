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
    const {
      startDate,
      endDate,
      categoryId,
      minAmount,
      maxAmount,
      search,
      sortBy = 'date',
      order = 'desc',
      page,
      limit,
    } = req.query;

    const whereClause: any = { userId };

    // Date filters
    if (startDate || endDate) {
      whereClause.date = {};
      if (startDate) whereClause.date.gte = new Date(startDate as string);
      if (endDate) whereClause.date.lte = new Date(endDate as string);
    }

    // Category filter
    if (categoryId) {
      whereClause.categoryId = categoryId as string;
    }

    // Amount range filter
    if (minAmount !== undefined || maxAmount !== undefined) {
      whereClause.amount = {};
      if (minAmount !== undefined) whereClause.amount.gte = parseFloat(minAmount as string);
      if (maxAmount !== undefined) whereClause.amount.lte = parseFloat(maxAmount as string);
    }

    // Search query on merchant or notes
    if (search) {
      const queryStr = search as string;
      whereClause.OR = [
        { merchant: { contains: queryStr, mode: 'insensitive' } },
        { notes: { contains: queryStr, mode: 'insensitive' } },
      ];
    }

    // Sorting
    const validSortFields = ['date', 'amount', 'merchant', 'createdAt'];
    const sortField = validSortFields.includes(sortBy as string) ? (sortBy as string) : 'date';
    const sortOrder = (order as string)?.toLowerCase() === 'asc' ? 'asc' : 'desc';

    // Pagination
    const take = limit ? parseInt(limit as string, 10) : undefined;
    const skip = page && limit ? (parseInt(page as string, 10) - 1) * take! : undefined;

    const [totalCount, expenses] = await Promise.all([
      prisma.expense.count({ where: whereClause }),
      prisma.expense.findMany({
        where: whereClause,
        orderBy: { [sortField]: sortOrder },
        take,
        skip,
        include: {
          category: true,
        },
      }),
    ]);

    res.status(200).json({
      status: 'success',
      results: expenses.length,
      total: totalCount,
      page: page ? parseInt(page as string, 10) : 1,
      totalPages: limit ? Math.ceil(totalCount / parseInt(limit as string, 10)) : 1,
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

export const parseTransaction = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { text } = req.body;
    if (!text) {
      return res.status(400).json({ status: 'fail', message: 'Text is required' });
    }

    const { SmartParserService } = await import('../services/smart-parser.service');
    
    // Check if OTP
    if (SmartParserService.isSensitiveOtpMessage(text)) {
      return res.status(422).json({
        status: 'fail',
        message: 'Sensitive message discarded (OTP / security code detected for user privacy)',
        isSensitiveDiscarded: true,
      });
    }

    const parsed = SmartParserService.parseTransactionText(text);
    if (!parsed) {
      return res.status(400).json({
        status: 'fail',
        message: 'Could not extract valid transaction details from the provided text',
      });
    }

    // Match with user's categories in the DB
    const category = await prisma.category.findFirst({
      where: { name: { equals: parsed.categoryName, mode: 'insensitive' } },
    });

    res.status(200).json({
      status: 'success',
      data: {
        transaction: {
          ...parsed,
          categoryId: category?.id || null,
        },
      },
    });
  } catch (error) {
    next(error);
  }
};

export const autoCategorize = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { merchant, notes } = req.body;
    const { SmartParserService } = await import('../services/smart-parser.service');
    const categoryName = SmartParserService.categorize(merchant, notes);

    const category = await prisma.category.findFirst({
      where: { name: { equals: categoryName, mode: 'insensitive' } },
    });

    res.status(200).json({
      status: 'success',
      data: {
        categoryName,
        categoryId: category?.id || null,
      },
    });
  } catch (error) {
    next(error);
  }
};
