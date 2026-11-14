# =============================================================================
# atlas-platform-app — Multi-stage Production Build
# Stage 1: Install dependencies (builder)
# Stage 2: Copy only what's needed (runtime) — non-root, <100MB
# =============================================================================

# --- Stage 1: Builder ---
FROM python:3.12-slim AS builder

WORKDIR /build

COPY requirements.txt .
RUN pip install --no-cache-dir --timeout=120 --retries=10 -r requirements.txt

COPY . ./app/

# --- Stage 2: Runtime ---
FROM python:3.12-slim

WORKDIR /app

# Security: non-root user
RUN groupadd -r appuser && useradd -r -g appuser -s /sbin/nologin appuser

# Copy installed packages + app source
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin/uvicorn /usr/local/bin/uvicorn
COPY --from=builder /build/app ./app/

# Security: non-root execution
USER appuser

EXPOSE 8000

# app/ directory is at /app/app/ → module path is app.main:app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]