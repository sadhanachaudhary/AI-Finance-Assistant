import { Request, Response, NextFunction } from 'express';
import prisma from '../config/prisma';
import { cacheService } from '../utils/cache.service';

export const getAnalyticsSummary = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const cacheKey = `analytics:summary:${userId}`;

    const summary = await cacheService.getOrSet(
      cacheKey,
      async () => {
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

        return {
          totalSpent,
          transactionCount: count,
          categoryBreakdown,
        };
      },
      60 // 60-second TTL
    );

    res.status(200).json({
      status: 'success',
      data: summary,
    });
  } catch (error) {
    next(error);
  }
};

export const getRecurringExpenses = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const cacheKey = `analytics:recurring:${userId}`;

    const result = await cacheService.getOrSet(
      cacheKey,
      async () => {
        const expenses = await prisma.expense.findMany({
          where: { userId },
          include: { category: true },
          orderBy: { date: 'desc' },
        });

        const subscriptionKeywords = ['netflix', 'spotify', 'gym', 'membership', 'icloud', 'prime', 'electricity', 'broadband', 'water', 'sub'];

        const recurring: Array<{
          merchant: string;
          amount: number;
          categoryName: string;
          frequency: string;
          estimatedAnnualCost: number;
        }> = [];

        const seenMerchants = new Set<string>();

        for (const exp of expenses) {
          const merchant = exp.merchant || 'Subscription';
          const lower = merchant.toLowerCase();

          const isSub = subscriptionKeywords.some((kw) => lower.includes(kw));

          if (isSub && !seenMerchants.has(lower)) {
            seenMerchants.add(lower);
            recurring.push({
              merchant,
              amount: exp.amount,
              categoryName: exp.category?.name || 'Bills & Utilities',
              frequency: 'Monthly',
              estimatedAnnualCost: exp.amount * 12,
            });
          }
        }

        const totalMonthlySubscriptionCost = recurring.reduce((sum, item) => sum + item.amount, 0);

        return {
          totalMonthlyCost: totalMonthlySubscriptionCost,
          count: recurring.length,
          subscriptions: recurring,
        };
      },
      60
    );

    res.status(200).json({
      status: 'success',
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

export const getSpendingForecast = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const cacheKey = `analytics:forecast:${userId}`;

    const forecast = await cacheService.getOrSet(
      cacheKey,
      async () => {
        const expenses = await prisma.expense.findMany({
          where: { userId },
          orderBy: { date: 'desc' },
        });

        const totalSpent = expenses.reduce((sum, exp) => sum + exp.amount, 0);
        const now = new Date();
        const currentDay = now.getDate();
        const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();

        const dailyBurnRate = currentDay > 0 ? totalSpent / currentDay : 0;
        const projectedMonthlySpend = dailyBurnRate * daysInMonth;

        return {
          currentSpend: totalSpent,
          daysPassed: currentDay,
          daysRemaining: daysInMonth - currentDay,
          dailyBurnRate: Math.round(dailyBurnRate * 100) / 100,
          projectedMonthlySpend: Math.round(projectedMonthlySpend * 100) / 100,
        };
      },
      60
    );

    res.status(200).json({
      status: 'success',
      data: forecast,
    });
  } catch (error) {
    next(error);
  }
};
