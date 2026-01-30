FROM python:3.14-slim

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /usr/src/app/

ENV UV_COMPILE_BYTECODE=1
ENV UV_NO_DEV=1

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-workspace

COPY . .

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked

#CMD ["uv", "run", "main.py"]