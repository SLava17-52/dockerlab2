FROM python:3.11-alpine AS builder

WORKDIR /app

RUN apk add --no-cache \
    build-base \
    libffi-dev \
    musl-dev

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt


FROM python:3.11-alpine AS runner

ARG LAB_LOGIN
ARG LAB_TOKEN

LABEL org.lab.login="${LAB_LOGIN}" \
      org.lab.token="${LAB_TOKEN}"

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    ROCKET_SIZE=medium

RUN adduser -u 10042 -D -s /bin/sh apprunner

WORKDIR /home/apprunner/app

COPY --from=builder /opt/venv /opt/venv
COPY --chown=apprunner:apprunner app/ .

USER apprunner

HEALTHCHECK --interval=25s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; resp = urllib.request.urlopen('http://localhost:8000/health'); exit(0 if resp.status == 200 else 1)"

ENTRYPOINT ["/opt/venv/bin/python", "app.py"]