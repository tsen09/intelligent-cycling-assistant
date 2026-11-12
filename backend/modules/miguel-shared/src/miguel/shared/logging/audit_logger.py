import json
import logging

audit_logger = logging.getLogger("audit")


def audit_event(
    event_type: str, username: str | None = None, request_id: str | None = None, metadata: dict | None = None
):
    audit_logger.info(
        json.dumps(
            {"event_type": event_type, "username": username, "request_id": request_id, "metadata": metadata or {}}
        )
    )
