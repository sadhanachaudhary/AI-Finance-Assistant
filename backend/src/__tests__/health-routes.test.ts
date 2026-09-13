import request from 'supertest';
import app from '../app';
import * as prismaModule from '../config/prisma';

describe('Health & System Routes Integration Tests', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('GET /health returns 200 and status ok when DB is healthy', async () => {
    jest.spyOn(prismaModule, 'checkDbHealth').mockResolvedValue(true);

    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('status', 'ok');
    expect(response.body).toHaveProperty('database', 'connected');
    expect(response.body).toHaveProperty('timestamp');
  });

  test('GET /health returns 503 degraded when DB is unavailable', async () => {
    jest.spyOn(prismaModule, 'checkDbHealth').mockResolvedValue(false);

    const response = await request(app).get('/health');
    expect(response.status).toBe(503);
    expect(response.body).toHaveProperty('status', 'degraded');
    expect(response.body).toHaveProperty('database', 'disconnected');
  });

  test('GET /api/categories rejects unauthenticated request with 401', async () => {
    const response = await request(app).get('/api/categories');
    expect(response.status).toBe(401);
  });
});
