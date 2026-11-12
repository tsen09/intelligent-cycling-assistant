import gzip
import logging
import os
import shutil
import sys
import time
from logging.handlers import RotatingFileHandler, TimedRotatingFileHandler
from typing import Optional
from pathlib import Path
from .logging_utils import _ensure_logs_dir, _get_module_log_file


class _WindowsSafeTimedRotatingFileHandler(TimedRotatingFileHandler):
    """
    TimedRotatingFileHandler that handles file locks on Windows and supports compression.
    """

    def __init__(
        self,
        filename,
        when="h",
        interval=1,
        backupCount=0,
        encoding=None,
        delay=False,
        utc=False,
        atTime=None,
        errors=None,
    ):
        super().__init__(filename, when, interval, backupCount, encoding, delay, utc, atTime, errors)

    def doRollover(self) -> None:
        """
        Do a rollover, with Windows safety and gzip compression.
        """
        if self.stream:
            self.stream.close()
            self.stream = None

        # Get the time that this sequence started at and make it a time-tuple
        currentTime = int(self.rolloverAt)
        dstNow = time.localtime(currentTime)[-1]
        t = self.rolloverAt - self.interval
        if self.utc:
            timeTuple = time.gmtime(t)
        else:
            timeTuple = time.localtime(t)
            dstThen = timeTuple[-1]
            if dstNow != dstThen:
                if dstNow:
                    addend = 3600
                else:
                    addend = -3600
                timeTuple = time.localtime(t + addend)

        dfn = self.rotation_filename(self.baseFilename + "." + time.strftime(self.suffix, timeTuple))

        # Check if the destination file already exists and handle it
        if os.path.exists(dfn):
            try:
                os.remove(dfn)
            except (PermissionError, OSError):
                # If we can't remove it, we can't roll over to it safely on Windows
                return

        try:
            if os.path.exists(self.baseFilename):
                os.rename(self.baseFilename, dfn)
        except (PermissionError, OSError):
            # If rename fails (file locked), we skip this rollover
            return

        if self.backupCount > 0:
            for s in self.getFilesToDelete():
                try:
                    os.remove(s)
                except (PermissionError, OSError):
                    pass

        if not self.delay:
            self.stream = self._open()

        newRolloverAt = self.computeRollover(currentTime)
        while newRolloverAt <= currentTime:
            newRolloverAt = newRolloverAt + self.interval

        # If DST changes and we are moving at a system-wide level, this next line
        # might need to be adjusted.
        if (self.when == "MIDNIGHT" or self.when.startswith("W")) and not self.utc:
            dstAtRollover = time.localtime(newRolloverAt)[-1]
            if dstNow != dstAtRollover:
                if not dstNow:  # DST starts
                    addend = -3600
                else:  # DST ends
                    addend = 3600
                newRolloverAt += addend
        self.rolloverAt = newRolloverAt

        # Trigger compression in a separate step or via rotator if supported.
        # Here we directly compress after rollover for simplicity.
        self.compress_file(dfn)

    def compress_file(self, filename: str) -> None:
        """Compress the rotated log file using gzip."""
        try:
            with open(filename, "rb") as f_in:
                with gzip.open(f"{filename}.gz", "wb") as f_out:
                    shutil.copyfileobj(f_in, f_out)
            os.remove(filename)
        except Exception:
            # If compression fails, we still have the original rotated file (unless it was deleted)
            # Or if it fails, we just leave it as is.
            pass


LOGS_DIR = _ensure_logs_dir()


def setup_logging(
    level: str | None = None,
    log_format: str = "[%(asctime)s] %(levelname)s - %(name)s - %(message)s", 
    log_date_format: str = "%Y-%m-%d %H:%M:%S",
) -> logging.Logger:
    """
    Setup structured logging for the application with separate log files per module.
    """
    log_level = level or "INFO".upper()

    numeric_level = getattr(logging, log_level, logging.INFO)
    logger = logging.getLogger(__name__)

    root_logger = logging.getLogger()
    root_logger.setLevel(numeric_level)
    root_logger.handlers.clear()

    from .logging_filter import RequestIdFilter

    # Also configure uvicorn loggers if they exist, to ensure they use our format and filters
    for uvicorn_logger_name in ["uvicorn", "uvicorn.error", "uvicorn.access"]:
        uv_logger = logging.getLogger(uvicorn_logger_name)
        uv_logger.handlers.clear()
        uv_logger.propagate = True  # Propagate to root logger which has our handlers

    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(numeric_level)
    console_formatter = logging.Formatter(log_format, datefmt=log_date_format)
    console_handler.setFormatter(console_formatter)
    console_handler.addFilter(RequestIdFilter())
    root_logger.addHandler(console_handler)

    logger.info(f"Logging configured with level: {log_level}")
    logger.info(f"Log files will be created in: {LOGS_DIR}")

    return logger


# Global logger instance
logger = setup_logging()


def get_logger(
    name: str,
    log_level: str | None = None,
    log_format: str = "[%(asctime)s] %(levelname)s - %(name)s - %(message)s",
    log_date_format: str = "%Y-%m-%d %H:%M:%S",
    logs_dir: Optional[str] = None,
) -> logging.Logger:
    """
    Get a logger instance for a specific module with file logging.
    """
    module_logger = logging.getLogger(name)
    log_directory = Path(logs_dir or LOGS_DIR)

    # Ensure the requested log directory exists.
    log_directory.mkdir(
        parents=True,
        exist_ok=True,
    )

    log_file = _get_module_log_file(
        logger_name=name,
        logs_dir=log_directory,
    )

    # Check if file handler already exists for this logger
    has_file_handler = any(
        (isinstance(handler, TimedRotatingFileHandler) or isinstance(handler, RotatingFileHandler))
        and handler.baseFilename == str(log_file)
        for handler in module_logger.handlers
    )

    if not has_file_handler:
        try:
            from .logging_filter import RequestIdFilter

            # Add timed rotating file handler (Rotate every day, keep 7 days)
            # We use our Windows-safe version with compression
            file_handler = _WindowsSafeTimedRotatingFileHandler(
                str(log_file), when="midnight", interval=1, backupCount=7, encoding="utf-8"
            )
            # Use the current level from settings for the file handler as well
            log_level = log_level or "INFO".upper()
            numeric_level = getattr(logging, log_level, logging.INFO)
            file_handler.setLevel(numeric_level)

            file_formatter = logging.Formatter(
                log_format, datefmt=log_date_format
            )
            file_handler.setFormatter(file_formatter)
            file_handler.addFilter(RequestIdFilter())
            module_logger.addHandler(file_handler)
        except (PermissionError, Exception) as e:
            # If we still can't write to the log file, we just log to console
            # which is already configured in setup_logging()
            module_logger.warning(f"⚠️ Failed to initialize file logging for {name} at {log_file}: {e}")

    return module_logger


def reset_log_file_for_logger(logger: logging.Logger, expected_module_name: Optional[str] = None) -> bool:
    """
    Truncate the backing module log file for the given logger.

    Returns:
        True when truncation succeeds, False otherwise.
    """
    if logger is None:
        return False

    module_name = _get_module_name(logger.name)
    if expected_module_name and module_name != expected_module_name:
        return False
    log_file = MODULE_LOG_FILES.get(module_name)
    if log_file is None:
        return False

    # Prefer truncating an already-open file handler stream to avoid
    # file locking issues on Windows and to keep the same descriptor.
    candidate_loggers = [logger, logging.getLogger()]
    for candidate in candidate_loggers:
        for handler in candidate.handlers:
            if not isinstance(handler, (RotatingFileHandler, TimedRotatingFileHandler)):
                continue
            if os.path.normcase(handler.baseFilename) != os.path.normcase(str(log_file)):
                continue
            try:
                handler.acquire()
                stream = getattr(handler, "stream", None)
                if stream is None:
                    handler.release()
                    continue
                handler.flush()
                stream.seek(0)
                stream.truncate(0)
                stream.flush()
                handler.release()
                return True
            except Exception:
                try:
                    handler.release()
                except Exception:
                    pass

    # Fallback: direct truncate.
    try:
        with open(log_file, "w", encoding="utf-8"):
            pass
        return True
    except Exception:
        return False
