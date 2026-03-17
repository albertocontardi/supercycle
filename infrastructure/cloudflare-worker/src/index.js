// SuperCycle Community Patterns Worker
// Receives anonymous error patterns from users and serves aggregated patterns.
// Max ~100 lines. No auth required. Rate-limited by user_hash.

const RATE_LIMIT = 10; // max POST per user_hash per hour
const MAX_PAYLOAD = 50 * 1024; // 50KB
const PATH_REGEX = /[/\\]|\.js|\.py|\.ts|\.md|\.html|\.css|\.json/i;

const rateLimitMap = new Map();

function isRateLimited(userHash) {
  const now = Date.now();
  const key = userHash;
  const entry = rateLimitMap.get(key);
  if (!entry || now - entry.windowStart > 3600000) {
    rateLimitMap.set(key, { windowStart: now, count: 1 });
    return false;
  }
  if (entry.count >= RATE_LIMIT) return true;
  entry.count++;
  return false;
}

function validatePayload(data) {
  if (!data.stack || typeof data.stack !== 'string' || data.stack.length > 50 || !/^[a-zA-Z0-9-]+$/.test(data.stack))
    return 'Invalid stack: must be alphanumeric, max 50 chars';
  if (!data.user_hash || typeof data.user_hash !== 'string' || !/^[a-f0-9]{64}$/.test(data.user_hash))
    return 'Invalid user_hash: must be 64-char hex string';
  if (!Array.isArray(data.patterns) || data.patterns.length > 50)
    return 'Invalid patterns: must be array, max 50 elements';
  for (const p of data.patterns) {
    if (!p.id || !p.triggers || !p.error || !p.resolution || !p.severity)
      return 'Each pattern must have id, triggers, error, resolution, severity';
    if (PATH_REGEX.test(p.error) || PATH_REGEX.test(p.resolution))
      return 'Pattern error/resolution must not contain file paths or extensions';
  }
  return null;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // POST /patterns — receive anonymous patterns
    if (request.method === 'POST' && url.pathname === '/patterns') {
      if ((request.headers.get('content-length') || 0) > MAX_PAYLOAD)
        return new Response(JSON.stringify({ error: 'Payload too large' }), { status: 413 });

      let data;
      try { data = await request.json(); }
      catch { return new Response(JSON.stringify({ error: 'Invalid JSON' }), { status: 400 }); }

      const validationError = validatePayload(data);
      if (validationError)
        return new Response(JSON.stringify({ error: validationError }), { status: 400 });

      if (isRateLimited(data.user_hash))
        return new Response(JSON.stringify({ error: 'Rate limited' }), { status: 429 });

      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const prefix = data.user_hash.substring(0, 8);
      const path = `community-patterns/inbox/${data.stack}/${timestamp}-${prefix}.json`;

      const commitResponse = await fetch(`https://api.github.com/repos/${env.GITHUB_REPO}/contents/${path}`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${env.GITHUB_TOKEN}`,
          'Content-Type': 'application/json',
          'User-Agent': 'supercycle-patterns-worker',
        },
        body: JSON.stringify({
          message: `patterns: ${data.stack} from ${prefix}`,
          content: btoa(JSON.stringify(data, null, 2)),
          branch: env.GITHUB_BRANCH,
        }),
      });

      if (!commitResponse.ok) {
        const err = await commitResponse.text();
        return new Response(JSON.stringify({ error: 'GitHub commit failed', detail: err }), { status: 502 });
      }

      return new Response(JSON.stringify({ status: 'accepted', patterns_received: data.patterns.length }), {
        status: 201, headers: { 'Content-Type': 'application/json' },
      });
    }

    // GET /patterns/:stack — serve aggregated patterns
    if (request.method === 'GET' && url.pathname.startsWith('/patterns/')) {
      const stack = url.pathname.split('/')[2];
      if (!stack || !/^[a-zA-Z0-9-]+$/.test(stack))
        return new Response(JSON.stringify({ error: 'Invalid stack' }), { status: 400 });

      const minReporters = parseInt(url.searchParams.get('min_reporters') || '3', 10);
      const rawUrl = `https://raw.githubusercontent.com/${env.GITHUB_REPO}/${env.GITHUB_BRANCH}/community-patterns/aggregated/${stack}.json`;

      const cached = await caches.default.match(request);
      if (cached) return cached;

      const ghResponse = await fetch(rawUrl, { headers: { 'User-Agent': 'supercycle-patterns-worker' } });
      if (!ghResponse.ok)
        return new Response(JSON.stringify({ status: 'no_patterns', stack }), { status: 404 });

      const data = await ghResponse.json();
      data.patterns = (data.patterns || []).filter(p => (p.reporters || 0) >= minReporters);
      data.pattern_count = data.patterns.length;

      const response = new Response(JSON.stringify(data), {
        headers: { 'Content-Type': 'application/json', 'Cache-Control': 'public, max-age=3600' },
      });

      await caches.default.put(request, response.clone());
      return response;
    }

    return new Response(JSON.stringify({ error: 'Not found' }), { status: 404 });
  },
};
