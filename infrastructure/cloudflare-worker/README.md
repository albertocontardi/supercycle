# SuperCycle Community Patterns Worker

Cloudflare Worker that receives anonymous error patterns from SuperCycle users and serves aggregated community patterns.

## Deploy

1. Install wrangler: `npm install -g wrangler`
2. Login: `wrangler login`
3. Set the GitHub token secret: `wrangler secret put GITHUB_TOKEN`
   - The token needs `contents: write` permission on `albertocontardi/supercycle`
4. Deploy: `wrangler deploy`

## Endpoints

### POST `/patterns`
Receives anonymous error patterns. No auth required, rate-limited to 10 requests/hour per user_hash.

### GET `/patterns/:stack`
Serves aggregated patterns for a stack. Cached at edge for 1 hour. Query param `min_reporters` (default: 3) filters by minimum distinct reporters.

## Security

- No authentication required (patterns are anonymous, rate-limited)
- GITHUB_TOKEN has ONLY `contents: write` on the repo
- Payloads > 50KB rejected
- No file paths or extensions allowed in pattern content
- Only counters are logged, never pattern content
