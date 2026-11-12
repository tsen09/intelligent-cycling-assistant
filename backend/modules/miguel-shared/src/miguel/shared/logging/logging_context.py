import contextvars

# This will hold request_id per request
request_id_ctx = contextvars.ContextVar("request_id", default="NA")
