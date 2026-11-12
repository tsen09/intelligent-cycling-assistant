import logging
import os
from pathlib import Path


def _get_project_root() -> Path:
    """
    Find the Multiagentic Framework repository root.

    The project root is identified by the presence of the expected
    top-level directories.
    """
    current_path = Path(__file__).resolve()

    for parent in current_path.parents:
        if (
            (parent / "backend").is_dir()
            and (parent / "frontend").is_dir()
        ):
            return parent

    raise RuntimeError(
        "Could not determine the Multiagentic Framework project root."
    )


def _ensure_logs_dir() -> Path:
    """
    Ensure the logs directory exists and is writable.

    LOGS_DIR:
        If set, its value is used.

        Absolute path:
            /some/path/logs

        Relative path:
            <project-root>/some/path/logs

    If LOGS_DIR is not set:
        <project-root>/logs

    Returns:
        Path: The resolved logs directory.
    """
    logs_dir = os.getenv("LOGS_DIR")

    if logs_dir:
        path = Path(logs_dir).expanduser()

        # Relative LOGS_DIR values are relative to project root.
        if not path.is_absolute():
            path = _get_project_root() / path
    else:
        path = _get_project_root() / "logs"

    path = path.resolve()

    try:
        path.mkdir(parents=True, exist_ok=True)

        test_file = path / ".write_test"

        try:
            test_file.touch()
        finally:
            if test_file.exists():
                test_file.unlink()

    except PermissionError as exc:
        raise PermissionError(
            f"Log directory is not writable: {path}"
        ) from exc

    except OSError as exc:
        raise OSError(
            f"Failed to create or access log directory: {path}"
        ) from exc

    return path


def _is_airflow_managed_logging() -> bool:
    root_logger = logging.getLogger()
    for handler in root_logger.handlers:
        handler_module = handler.__class__.__module__
        if handler_module.startswith("airflow."):
            return True
        stream = getattr(handler, "stream", None)
        stream_module = stream.__class__.__module__ if stream is not None else ""
        if stream_module.startswith("airflow."):
            return True
    return False


def _get_module_name(logger_name: str) -> str:
    """
    Derive a module name from a logger name.
    """
    normalized_name = logger_name.lower().replace("-", "_")

    parts = [
        part
        for part in normalized_name.split(".")
        if part
    ]

    if not parts:
        return "application"

    # Use the first meaningful namespace component.
    return parts[0]

def _get_module_log_file(logger_name: str, logs_dir: Path) -> Path:
    module_name = _get_module_name(logger_name)

    return logs_dir / f"{module_name}.log"