# Presentations deployment

The supported deployment channel for `docs/presentations/` is the manually triggered GitHub Pages
workflow: `.github/workflows/deploy-presentations.yml`.

Vercel and Netlify are not supported channels for this repository. The former PowerShell helper was
removed rather than retaining a second, untested deployment path.

Trigger **Deploy Presentations Book** from the repository Actions tab after enabling GitHub Pages
with **GitHub Actions** as its source. The workflow validates the repository ownership and uploads
the presentations directory as the Pages artifact.
