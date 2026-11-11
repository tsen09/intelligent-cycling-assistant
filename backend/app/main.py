import os
import tomllib
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates


# ---------------------------------------------------------------------------
# Application configuration
# ---------------------------------------------------------------------------

BASE_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = BASE_DIR.parent
TEMPLATES_DIR = BASE_DIR / "templates"
ASSETS_DIR = PROJECT_ROOT.parent / ".github" / "assets"

# Read project metadata from backend/pyproject.toml
with open(PROJECT_ROOT / "pyproject.toml", "rb") as file:
    PROJECT_METADATA = tomllib.load(file)["project"]

VERSION = PROJECT_METADATA["version"]
APP_NAME = PROJECT_METADATA["name"]
ENVIRONMENT = os.getenv("ENV", "development")  # Defaults to development if not set


# ---------------------------------------------------------------------------
# FastAPI application
# ---------------------------------------------------------------------------

app = FastAPI(
    title=APP_NAME,
    description="Your intelligent cycling companion.",
    version=VERSION,
)

app.mount("/.github/assets", StaticFiles(directory=str(ASSETS_DIR)), name="assets")

templates = Jinja2Templates(directory=str(TEMPLATES_DIR))


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@app.get("/", response_class=HTMLResponse, include_in_schema=False)
async def home(request: Request):
    """Serve the Miguel application landing page."""

    return templates.TemplateResponse(
        request=request,
        name="home.html",
        context={
            "version": VERSION,
            "env": ENVIRONMENT,
        },
    )


@app.get("/health", tags=["Health"])
async def health_check():
    """Check backend service health."""

    return {
        "application": APP_NAME,
        "status": "healthy",
        "version": VERSION,
        "environment": ENVIRONMENT,
    }
