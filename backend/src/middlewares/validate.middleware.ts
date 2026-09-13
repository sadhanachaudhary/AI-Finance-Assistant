import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';

export const validate =
  (schema: ZodSchema) =>
  (req: Request, res: Response, next: NextFunction) => {
    try {
      const validated: any = schema.parse({
        body: req.body,
        query: req.query,
        params: req.params,
      });
      if (validated && validated.body) {
        req.body = validated.body;
      }
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        return res.status(400).json({
          status: 'fail',
          errors: (error as any).issues || (error as any).errors,
        });
      }
      next(error);
    }
  };
