import { Request, Response, NextFunction } from 'express';
import prisma from '../config/prisma';

export const getNotifications = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = (req as any).user.id;

    const notifications = await prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    const unreadCount = await prisma.notification.count({
      where: { userId, isRead: false },
    });

    res.status(200).json({
      status: 'success',
      data: {
        notifications,
        unreadCount,
      },
    });
  } catch (error) {
    next(error);
  }
};

export const getUnreadCount = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = (req as any).user.id;

    const unreadCount = await prisma.notification.count({
      where: { userId, isRead: false },
    });

    res.status(200).json({
      status: 'success',
      data: { unreadCount },
    });
  } catch (error) {
    next(error);
  }
};

export const markAsRead = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = (req as any).user.id;
    const { id } = req.params;

    const notification = await prisma.notification.updateMany({
      where: { id, userId },
      data: { isRead: true },
    });

    res.status(200).json({
      status: 'success',
      message: 'Notification marked as read',
      data: { updatedCount: notification.count },
    });
  } catch (error) {
    next(error);
  }
};

export const markAllAsRead = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = (req as any).user.id;

    const result = await prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });

    res.status(200).json({
      status: 'success',
      message: 'All notifications marked as read',
      data: { updatedCount: result.count },
    });
  } catch (error) {
    next(error);
  }
};

export const deleteNotification = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = (req as any).user.id;
    const { id } = req.params;

    await prisma.notification.deleteMany({
      where: { id, userId },
    });

    res.status(200).json({
      status: 'success',
      message: 'Notification deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Evaluates live user metrics and generates contextual smart alerts
 */
export const generateSmartAlerts = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = (req as any).user.id;

    const [expenses, goals, recentNotifications] = await Promise.all([
      prisma.expense.findMany({
        where: { userId },
        include: { category: true },
        orderBy: { date: 'desc' },
      }),
      (prisma as any).goal.findMany({
        where: { userId },
      }).catch(() => []),
      prisma.notification.findMany({
        where: { userId },
        take: 20,
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    const createdAlerts: Array<{ title: string; body: string }> = [];
    const recentTitles = new Set(recentNotifications.map((n) => n.title));

    const totalSpent = expenses.reduce((sum, e) => sum + e.amount, 0);

    // 1. Category Velocity / Budget Alert
    const categoryTotals: Record<string, number> = {};
    for (const exp of expenses) {
      const cat = exp.category?.name || 'Uncategorized';
      categoryTotals[cat] = (categoryTotals[cat] || 0) + exp.amount;
    }

    for (const [catName, amount] of Object.entries(categoryTotals)) {
      if (amount >= 2000 && totalSpent > 0 && amount / totalSpent > 0.35) {
        const title = `⚠️ High Spending Alert: ${catName}`;
        if (!recentTitles.has(title)) {
          const alert = {
            title,
            body: `You've spent ₹${amount.toLocaleString()} on ${catName} this month (${Math.round((amount / totalSpent) * 100)}% of total). Consider pacing to stay on track.`,
          };
          createdAlerts.push(alert);
          recentTitles.add(title);
        }
      }
    }

    // 2. Goal Milestones
    for (const goal of goals) {
      if (goal.targetAmount > 0) {
        const pct = Math.round((goal.currentAmount / goal.targetAmount) * 100);
        if (pct >= 100) {
          const title = `🎉 Goal Achieved: ${goal.name}!`;
          if (!recentTitles.has(title)) {
            const alert = {
              title,
              body: `Congratulations! You've reached 100% of your target for "${goal.name}" (₹${goal.currentAmount.toLocaleString()}).`,
            };
            createdAlerts.push(alert);
            recentTitles.add(title);
          }
        } else if (pct >= 75) {
          const title = `🎯 Milestone Reached: ${goal.name}`;
          if (!recentTitles.has(title)) {
            const alert = {
              title,
              body: `You're at ${pct}% of your "${goal.name}" goal. Just ₹${(goal.targetAmount - goal.currentAmount).toLocaleString()} left to go!`,
            };
            createdAlerts.push(alert);
            recentTitles.add(title);
          }
        } else if (pct >= 50) {
          const title = `🌟 Halfway There: ${goal.name}`;
          if (!recentTitles.has(title)) {
            const alert = {
              title,
              body: `Great job! You've saved 50% towards "${goal.name}". Consistency is paying off!`,
            };
            createdAlerts.push(alert);
            recentTitles.add(title);
          }
        }
      }
    }

    // 3. Recurring Subscriptions Reminder
    const subKeywords = ['netflix', 'spotify', 'hotstar', 'prime', 'gym', 'membership', 'icloud', 'youtube'];
    const activeSubs = expenses.filter((e) =>
      subKeywords.some((kw) => (e.merchant || '').toLowerCase().includes(kw))
    );

    if (activeSubs.length > 0) {
      const title = `🔁 Recurring Subscriptions Audit`;
      if (!recentTitles.has(title)) {
        const alert = {
          title,
          body: `Detected ${activeSubs.length} active recurring subscription charges. Check your AI advisor for optimization recommendations.`,
        };
        createdAlerts.push(alert);
        recentTitles.add(title);
      }
    }

    // 4. Welcome / Baseline Tip if user has few alerts
    if (recentNotifications.length === 0 && createdAlerts.length === 0) {
      createdAlerts.push({
        title: `👋 Welcome to AI Finance Assistant!`,
        body: `Your proactive financial shield is active. We will monitor budget velocity, savings milestones, and recurring bills in real time.`,
      });
    }

    // Insert new alerts into DB
    for (const alert of createdAlerts) {
      await prisma.notification.create({
        data: {
          userId,
          title: alert.title,
          body: alert.body,
          isRead: false,
        },
      });
    }

    // Return all notifications
    const allNotifications = await prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    const unreadCount = await prisma.notification.count({
      where: { userId, isRead: false },
    });

    res.status(200).json({
      status: 'success',
      data: {
        createdCount: createdAlerts.length,
        notifications: allNotifications,
        unreadCount,
      },
    });
  } catch (error) {
    next(error);
  }
};
