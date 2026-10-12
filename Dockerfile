ARG NODE_VERSION=24.13.0-slim

# deps: install exactly what the lockfile says
FROM node:${NODE_VERSION} AS deps
WORKDIR /app
COPY app/package.json app/package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --no-audit --no-fund

# builder: build the web app and the worker
FROM node:${NODE_VERSION} AS builder
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1
COPY --from=deps /app/node_modules ./node_modules
COPY app/ .
RUN npm run build && npm run build:worker

# runner: distroless, just the Node runtime, no shell or package manager
FROM gcr.io/distroless/nodejs24-debian13:nonroot AS runner
WORKDIR /app
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    PORT=3000 \
    HOSTNAME=0.0.0.0

COPY --from=builder --chown=nonroot:nonroot /app/.next/standalone ./
COPY --from=builder --chown=nonroot:nonroot /app/.next/static ./.next/static
COPY --from=builder --chown=nonroot:nonroot /app/public ./public
COPY --from=builder --chown=nonroot:nonroot /app/dist/worker.js ./worker.js

USER nonroot
EXPOSE 3000
CMD ["server.js"]