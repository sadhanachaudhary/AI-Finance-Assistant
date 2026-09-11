import { Request, Response, NextFunction } from 'express';
import prisma from '../config/prisma';

export const getAnalyticsSummary = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;

    const expenses = await prisma.expense.findMany({
      where: { userId },
      include: {
        category: true,
      },
      orderBy: { date: 'desc' },
    });

    const totalSpent = expenses.reduce((sum, exp) => sum + exp.amount, 0);
    const count = expenses.length;

    // Group by category
    const categoryMap: { [key: string]: { name: string; icon?: string | null; color?: string | null; amount: number; count: number } } = {};

    for (const exp of expenses) {
      const catName = exp.category?.name || 'Uncategorized';
      if (!categoryMap[catName]) {
        categoryMap[catName] = {
          name: catName,
          icon: exp.category?.icon,
          color: exp.category?.color,
          amount: 0,
          count: 0,
        };
      }
      categoryMap[catName].amount += exp.amount;
      categoryMap[catName].count += 1;
    }

    const categoryBreakdown = Object.values(categoryMap).map((cat) => ({
      ...cat,
      percentage: totalSpent > 0 ? (cat.amount / totalSpent) * 100 : 0,
    })).sort((a, b) => b.amount - a.amount);

    res.status(200).json({
      status: 'success',
      data: {
        totalSpent,
        transactionCount: count,
        categoryBreakdown,
      },
    });
  } catch (error) {
    next(error);
  }
};
