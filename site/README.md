# dotViewer Site

Marketing site for `dotViewer.app`.

## Local development

```bash
cd site
npm install
npm run dev
```

## Download configuration

The site resolves the latest macOS installer in this order:

1. `DIRECT_DOWNLOAD_URL`
2. `GITHUB_REPO` via GitHub Releases
3. Vercel Git repo env vars (`VERCEL_GIT_REPO_OWNER` + `VERCEL_GIT_REPO_SLUG`)

The public download flow uses:

- `/download` as the release-aware landing page with auto-start download + version history
- `/download/latest` as the stable direct-download redirect

If no download source is configured, `/download/latest` falls back to GitHub Releases or the home page install section.

## Deployment

Recommended target: Vercel on `dotViewer.app`.

Set:

- `NEXT_PUBLIC_SITE_URL=https://dotviewer.app`
- `GITHUB_REPO=owner/repo`

Optional:

- `GITHUB_TOKEN` for authenticated GitHub API requests
