# --- Builder ----------------------------------------------------------------
FROM python:3.12-alpine AS build

WORKDIR /app

# uv (used by uv.lock) is much faster than pip and honours the lockfile.
RUN pip install --no-cache-dir uv

COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

COPY app ./app

# --- Runtime ----------------------------------------------------------------
FROM python:3.12-alpine AS final

WORKDIR /app

# Non-root user for the Kyverno `require-run-as-non-root` policy.
RUN addgroup -S app && adduser -S app -G app

COPY --from=build --chown=app:app /app/.venv /app/.venv
COPY --from=build --chown=app:app /app/app /app/app

USER app

ENV PATH="/app/.venv/bin:$PATH"
EXPOSE 8080

ENTRYPOINT ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
