import { Request, Response, NextFunction } from 'express';
import { AiAdvisorService } from '../services/ai-advisor.service';

export const handleAiChat = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.userId!;
    const { message, history = [] } = req.body;

    if (!message || typeof message !== 'string') {
      return res.status(400).json({ status: 'fail', message: 'Message is required' });
    }

    const ctx = await AiAdvisorService.getUserFinancialContext(userId);
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
