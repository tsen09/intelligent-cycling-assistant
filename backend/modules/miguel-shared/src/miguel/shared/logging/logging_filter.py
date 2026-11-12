import logging


class RequestIdFilter(logging.Filter):
    def filter(self, record):
        from .logging_context import request_id_ctx

        # Ensure request_id exists on the record for the formatter
        if not hasattr(record, "request_id"):
            record.request_id = request_id_ctx.get("-")
        return True
