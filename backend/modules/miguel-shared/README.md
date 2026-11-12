# Miguel Shared Module

Centralised utilities—including logging, database connections, and custom exceptions—for the Miguel Application.

`miguel-shared` provides a consistent, reusable foundational layer for the Miguel project and its modules. It is designed to work across development, testing, and production environments while remaining independent of application-specific business logic.

---

## ✨ Features

- **Centralised Logging:** Dynamic module-based log files, timed log rotation, gzip compression, configurable retention, and console/file output.
- **Database Connections:** Shared SQLAlchemy engine and session management configured via environment variables (with PostgreSQL support).
- **Custom Exceptions:** Standardised base exception classes for consistent error handling across all application services.
- **Environment-Driven:** Full `.env` support with sensible local defaults and `pathlib.Path` OS-independent filesystem handling.
- **Python 3.13+ Support:** Built for modern Python environments.

---

## ⚙️ Installation

### Development Installation

From the root of the Miguel project:

```bash
pip install -e backend/modules/miguel-shared
```

An editable installation is recommended during development so changes to the package are immediately available without reinstalling.

### Regular Installation

```bash
pip install backend/modules/miguel-shared
```

---

## 📁 Package Structure

```text
miguel-shared/
├── pyproject.toml
├── README.md
└── src/
    └── miguel/
        └── shared/
            ├── __init__.py
            ├── logging.py
            ├── database.py
            └── exceptions.py
```

| Attribute | Value |
|---|---|
| Distribution package | `miguel-shared` |
| Python import namespace | `miguel.shared` |

### Import Examples

```python
from miguel.shared.logging import get_logger
from miguel.shared.database import get_db_session
from miguel.shared.exceptions import MiguelBaseError
```

---

## 🔧 Configuration

`miguel-shared` reads configuration values from environment variables or the project's root `.env` file.

### Environment Variables

```dotenv
# Logging Configuration
LOGS_DIR=logs

# Database Configuration
DATABASE_URL=postgresql+psycopg2://user:password@localhost:5432/miguel_db
```

### Logging Directory Behaviour

The logging directory is resolved using `pathlib.Path`:

- **Relative paths:** Paths such as `logs` or `logs/application` resolve relative to `<project-root>/`.
- **Absolute paths:** Paths such as `/var/log/miguel` on Linux/macOS or `C:/logs/miguel` on Windows are supported natively.
- **Default:** If `LOGS_DIR` is omitted, logs default to `<project-root>/logs`.

---

## 🚀 Usage

### 1. Logging

Create a logger using the module's `__name__`:

```python
from miguel.shared.logging import get_logger

logger = get_logger(__name__)

def process_document(document_id: str) -> None:
    logger.info("Processing document: %s", document_id)

    try:
        # Processing logic
        ...
    except Exception:
        logger.exception("Failed to process document: %s", document_id)
        raise
```

#### Dynamic Module Log Files

Log files are determined dynamically from the logger namespace.

| Logger | Output File |
|---|---|
| `get_logger("backend")` | `logs/backend.log` |
| `get_logger("frontend")` | `logs/frontend.log` |
| `get_logger("data_ingestion")` | `logs/data_ingestion.log` |

#### Log Rotation & Levels

- Log files rotate automatically based on the configured schedule.
- Rotated archives are compressed using gzip (e.g., `backend.log.2026-08-15.gz`).
- Old backups are automatically purged according to the configured retention policy.
- Standard Python logging levels are supported: `DEBUG`, `INFO`, `WARNING`, `ERROR`, and `CRITICAL`.

### 2. Database Connections

Use the shared database utilities to obtain SQLAlchemy sessions or engines without duplicating connection pooling logic across services.

```python
from miguel.shared.database import get_db_session

with get_db_session() as session:
    # Execute database queries
    ...
```

### 3. Custom Exceptions

Inherit from or raise standardised exceptions defined in `miguel.shared.exceptions` so upstream API layers and workers can handle errors uniformly.

```python
from miguel.shared.exceptions import MiguelBaseError

class DocumentProcessingError(MiguelBaseError):
    """Raised when document parsing fails."""
```

---

## 🏗️ Architecture & Dependency Principles

`miguel-shared` sits at the base of the dependency graph. Application modules depend on `miguel-shared`, never the reverse.

```text
                Miguel Application
                        |
        +---------------+---------------+
        v               v               v
     Backend          Agents          Workers
        |               |               |
        +---------------+---------------+
                        |
                        v
                  miguel-shared
          (Logging | Database | Exceptions)
```

To prevent circular imports and maintain reusability, `miguel-shared` must remain completely agnostic of:

- Domain-specific models.
- API routes and application endpoints.
- Application-specific business logic.

It should provide foundational infrastructure only, allowing all Miguel modules to consume the same shared utilities without introducing unnecessary dependencies.

---

## 🧪 Development

Install the package in editable mode and run the test suite from the project root.

### Install

```bash
pip install -e backend/modules/miguel-shared
```

### Run Tests

```bash
pytest backend/modules/miguel-shared/tests/
```

---

## 📋 Requirements

| Requirement | Specification |
|---|---|
| Python | `>=3.13` |
| Dependencies | `python-dotenv`, `sqlalchemy`, `psycopg2-binary` |
| Operating System | Linux, macOS, Windows |

---

## 📄 License

This project is licensed under the **MIT License**.

Copyright © Tanmoy Sen.