import os
from contextlib import contextmanager
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

from ..logging.logging import get_logger

logger = get_logger(__name__)

# Load environment variables
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("DATABASE_URL environment variable is not set")

# Ensure proper types for engine parameters
DB_POOL_SIZE = int(os.getenv("DB_POOL_SIZE", 5))
DB_MAX_OVERFLOW = int(os.getenv("DB_MAX_OVERFLOW", 10))
DB_ECHO = os.getenv("DB_ECHO", "false").lower() in ("true", "1", "t")

_engine = None
_SessionLocal = None

# Base class for ORM models
Base = declarative_base()


def get_engine():
    """Get or create a database engine (lazy initialization)"""
    global _engine
    if _engine is None:
        _engine = create_engine(
            DATABASE_URL,
            pool_size=DB_POOL_SIZE,
            max_overflow=DB_MAX_OVERFLOW,
            pool_pre_ping=True,      # Automatically tests connection vitality
            pool_recycle=900,        # Recycles stale connections after 15 min
            pool_timeout=30,
            echo=DB_ECHO,
        )
    return _engine


def get_session_factory():
    """Get or create a SessionLocal factory (lazy initialization)"""
    global _SessionLocal
    if _SessionLocal is None:
        _SessionLocal = sessionmaker(
            autocommit=False,
            autoflush=False,
            bind=get_engine(),
            expire_on_commit=False,  # Prevents detached instance errors after commit
        )
    return _SessionLocal


# Backwards compatibility aliases
engine = get_engine
SessionLocal = get_session_factory


def get_db():
    """Generator function for FastAPI dependency injection."""
    db = get_session_factory()()
    try:
        yield db
    finally:
        db.close()


@contextmanager
def get_db_session():
    """Context manager for non-FastAPI scripts and background tasks."""
    db = get_session_factory()()
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()