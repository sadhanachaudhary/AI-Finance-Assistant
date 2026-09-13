import { Request, Response, NextFunction } from 'express';
import { AiAdvisorService } from '../services/ai-advisor.service';
import prisma from '../config/prisma';

export const handleAiChat = async (req: Request, res: Response, next: NextFunction) => {
  try {
    let userId = req.userId;

    if (!userId) {
      const demoUser = await prisma.user.findFirst({
        where: { email: 'demo@aifinance.com' },
      });
      if (demoUser) {
        userId = demoUser.id;
      } else {
        const anyUser = await prisma.user.findFirst();
        userId = anyUser?.id;
      }
    }

    const { message, history = [] } = req.body;

    if (!message || typeof message !== 'string') {
      return res.status(400).json({ status: 'fail', message: 'Message is required' });
    }

    const ctx = await AiAdvisorService.getUserFinancialContext(userId || '');
    const reply = await AiAdvisorService.generateAnswer(message, history, ctx);

    res.status(200).json({
      status: 'success',
      data: {
        reply,
        timestamp: new Date().toISOString(),
      },
    });
  } catch (error) {
    next(error);
  }
};
