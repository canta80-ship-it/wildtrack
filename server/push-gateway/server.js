import fs from 'node:fs/promises';
import path from 'node:path';
import express from 'express';
import admin from 'firebase-admin';

const PORT = Number(process.env.PORT || 8080);
const DATA_FILE = process.env.WILDTRACK_PUSH_DATA || path.resolve('push-devices.json');
const INTERNAL_SECRET = process.env.WILDTRACK_PUSH_SECRET || '';

function initFirebase() {
  if (admin.apps.length) return;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON mancante');
  admin.initializeApp({credential: admin.credential.cert(JSON.parse(raw))});
}

async function loadRegistry() {
  try {
    const raw = await fs.readFile(DATA_FILE, 'utf8');
    const data = JSON.parse(raw);
    return data && typeof data === 'object' ? data : {};
  } catch {
    return {};
  }
}

async function saveRegistry(registry) {
  await fs.mkdir(path.dirname(DATA_FILE), {recursive: true});
  const tmp = `${DATA_FILE}.tmp`;
  await fs.writeFile(tmp, JSON.stringify(registry, null, 2));
  await fs.rename(tmp, DATA_FILE);
}

function normalizeRegistration(body = {}) {
  const token = String(body.token || '').trim();
  if (token.length < 20) throw new Error('token FCM non valido');
  return {
    token,
    platform: String(body.platform || 'android').slice(0, 20),
    nickname: String(body.nickname || '').slice(0, 40),
    chat: body.chat !== false,
    sightings: body.sightings !== false,
    updatedAt: new Date().toISOString(),
  };
}

function requireInternal(req, res, next) {
  if (!INTERNAL_SECRET) return res.status(503).json({error: 'WILDTRACK_PUSH_SECRET non configurato'});
  if ((req.get('x-wildtrack-push-secret') || '') !== INTERNAL_SECRET) {
    return res.status(401).json({error: 'non autorizzato'});
  }
  next();
}

async function send(kind, payload) {
  initFirebase();
  const registry = await loadRegistry();
  const prefKey = kind === 'chat' ? 'chat' : 'sightings';
  const tokens = Object.values(registry)
    .filter((entry) => entry[prefKey] === true)
    .map((entry) => entry.token);

  if (!tokens.length) return {targeted: 0, successCount: 0, failureCount: 0};

  const message = {
    tokens,
    notification: {
      title: String(payload.title || (kind === 'chat' ? 'Nuovo messaggio WildTrack' : 'Nuovo avvistamento WildTrack')),
      body: String(payload.body || '').slice(0, 240),
    },
    data: Object.fromEntries(
      Object.entries(payload.data || {}).map(([key, value]) => [String(key), String(value)]),
    ),
    android: {
      priority: 'high',
      notification: {
        channelId: kind === 'chat' ? 'wildtrack_chat' : 'wildtrack_sightings',
        sound: 'default',
      },
    },
  };

  const result = await admin.messaging().sendEachForMulticast(message);
  const invalid = [];
  result.responses.forEach((response, index) => {
    const code = response.error?.code || '';
    if (code.includes('registration-token-not-registered') || code.includes('invalid-registration-token')) {
      invalid.push(tokens[index]);
    }
  });
  if (invalid.length) {
    for (const token of invalid) delete registry[token];
    await saveRegistry(registry);
  }

  return {
    targeted: tokens.length,
    successCount: result.successCount,
    failureCount: result.failureCount,
    invalidRemoved: invalid.length,
  };
}

const app = express();
app.use(express.json({limit: '256kb'}));

app.get('/health', (_req, res) => res.json({ok: true, service: 'wildtrack-push-gateway'}));

app.post('/push/register', async (req, res) => {
  try {
    const registration = normalizeRegistration(req.body);
    const registry = await loadRegistry();
    registry[registration.token] = registration;
    await saveRegistry(registry);
    res.json({ok: true});
  } catch (error) {
    res.status(400).json({error: String(error.message || error)});
  }
});

app.delete('/push/register', async (req, res) => {
  const token = String(req.body?.token || '').trim();
  const registry = await loadRegistry();
  delete registry[token];
  await saveRegistry(registry);
  res.json({ok: true});
});

app.post('/internal/notify/chat', requireInternal, async (req, res) => {
  try {
    res.json(await send('chat', req.body || {}));
  } catch (error) {
    res.status(500).json({error: String(error.message || error)});
  }
});

app.post('/internal/notify/sighting', requireInternal, async (req, res) => {
  try {
    res.json(await send('sighting', req.body || {}));
  } catch (error) {
    res.status(500).json({error: String(error.message || error)});
  }
});

app.listen(PORT, () => {
  console.log(`WildTrack push gateway listening on :${PORT}`);
});
