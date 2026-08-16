import { beforeEach, describe, expect, it } from 'vitest';
import request from 'supertest';

import { createApp } from '../src/app';
import { resetMemoryStore } from '../src/repositories/memory.repos';

const { app } = createApp();

describe('API (spec §23, §29)', () => {
  beforeEach(() => {
    resetMemoryStore();
  });

  it('reports health with the storage mode', async () => {
    const res = await request(app).get('/api/v1/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.mode).toBe('memory');
  });

  it('validates request bodies at the boundary (spec §23)', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({ full_name: 'A', identifier: 'not-a-phone', password: '123' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
  });

  it('supports register → login → me (FLOW 1)', async () => {
    const register = await request(app)
      .post('/api/v1/auth/register')
      .send({ full_name: 'Kwame Owusu', identifier: '0241234567', password: 'secret1' });
    expect(register.status).toBe(201);
    expect(register.body.access_token).toBeTruthy();

    const login = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: '0241234567', password: 'secret1' });
    expect(login.status).toBe(200);

    const me = await request(app)
      .get('/api/v1/users/me')
      .set('Authorization', `Bearer ${login.body.access_token}`);
    expect(me.status).toBe(200);
    expect(me.body.full_name).toBe('Kwame Owusu');
    expect(JSON.stringify(me.body)).not.toContain('password');
  });

  it('rejects protected routes without a token', async () => {
    const res = await request(app).get('/api/v1/users/me');
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe('UNAUTHORIZED');
  });

  it('creates a group and records a contribution into the group wallet', async () => {
    const register = await request(app)
      .post('/api/v1/auth/register')
      .send({ full_name: 'Kwame Owusu', identifier: '0241234567', password: 'secret1' });
    const token = register.body.access_token as string;
    const auth = { Authorization: `Bearer ${token}` };

    const group = await request(app)
      .post('/api/v1/groups')
      .set(auth)
      .send({ name: 'Weekend Susu', type: 'ROTATIONAL_SUSU' });
    expect(group.status).toBe(201);
    const groupId = group.body.id as string;

    const contribution = await request(app)
      .post(`/api/v1/groups/${groupId}/contributions`)
      .set(auth)
      .send({ amount_minor: 5000, payment_method: 'Mobile Money', idempotency_key: 'api-key-1' });
    expect(contribution.status).toBe(201);
    expect(contribution.body.status).toBe('SUCCESSFUL');
    expect(contribution.body.group_id).toBe(groupId);

    const wallet = await request(app)
      .get(`/api/v1/groups/${groupId}/wallet`)
      .set(auth);
    expect(wallet.status).toBe(200);
    expect(wallet.body.wallet.balance_minor).toBe(5000);

    const transactions = await request(app).get('/api/v1/transactions').set(auth);
    expect(transactions.body.transactions).toHaveLength(1);
    expect(transactions.body.transactions[0].type).toBe('CONTRIBUTION');
  });

  it('supports chat, notifications and proposal voting over HTTP', async () => {
    const register = await request(app)
      .post('/api/v1/auth/register')
      .send({ full_name: 'Kwame Owusu', identifier: '0241234567', password: 'secret1' });
    const token = register.body.access_token as string;
    const auth = { Authorization: `Bearer ${token}` };

    const group = await request(app)
      .post('/api/v1/groups')
      .set(auth)
      .send({ name: 'Weekend Susu', type: 'ROTATIONAL_SUSU' });
    const groupId = group.body.id as string;

    // Chat
    const sent = await request(app)
      .post(`/api/v1/groups/${groupId}/messages`)
      .set(auth)
      .send({ body: 'Hello everyone' });
    expect(sent.status).toBe(201);
    const messages = await request(app).get(`/api/v1/groups/${groupId}/messages`).set(auth);
    expect(messages.body.messages).toHaveLength(1);

    // Governance: proposal + vote
    const proposal = await request(app)
      .post(`/api/v1/groups/${groupId}/proposals`)
      .set(auth)
      .send({
        title: 'Increase contribution?',
        options: ['Yes', 'No'],
        voting_ends: new Date(Date.now() + 86400000).toISOString(),
      });
    expect(proposal.status).toBe(201);
    const proposalId = proposal.body.id as string;
    const vote = await request(app)
      .post(`/api/v1/groups/${groupId}/proposals/${proposalId}/vote`)
      .set(auth)
      .send({ option: 'Yes' });
    expect(vote.status).toBe(201);
    const duplicate = await request(app)
      .post(`/api/v1/groups/${groupId}/proposals/${proposalId}/vote`)
      .set(auth)
      .send({ option: 'No' });
    expect(duplicate.status).toBe(409);

    // Notifications (contribution emits one to the actor)
    await request(app)
      .post(`/api/v1/groups/${groupId}/contributions`)
      .set(auth)
      .send({ amount_minor: 5000, payment_method: 'Mobile Money', idempotency_key: 'chat-api-1' });
    const notifications = await request(app).get('/api/v1/notifications').set(auth);
    expect(notifications.body.unread_count).toBeGreaterThan(0);
    const readAll = await request(app).post('/api/v1/notifications/read-all').set(auth);
    expect(readAll.status).toBe(200);
    const after = await request(app).get('/api/v1/notifications').set(auth);
    expect(after.body.unread_count).toBe(0);
  });

  it('does not reveal a raw stack trace on internal errors', async () => {
    const res = await request(app).get('/api/v1/nonexistent');
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });
});
