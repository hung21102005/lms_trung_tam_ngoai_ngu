# ==============================================================================
# DOCKERFILE — LMS TRUNG TÂM NGOẠI NGỮ (NESTJS BACKEND)
# Multi-stage build for optimal image size and security
# ==============================================================================

# STAGE 1: Builder
FROM node:24-alpine AS builder

WORKDIR /usr/src/app

# Install OpenSSL for Prisma client generation on Alpine
RUN apk add --no-cache openssl libc6-compat

# Install dependencies first for Docker caching
COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci

# Copy source code and build
COPY tsconfig*.json nest-cli.json ./
COPY src ./src

RUN npx prisma generate
RUN npm run build

# STAGE 2: Production Runner
FROM node:24-alpine AS runner

WORKDIR /usr/src/app

ENV NODE_ENV=production
RUN apk add --no-cache openssl libc6-compat

COPY package*.json ./
COPY prisma ./prisma/

# Install only production dependencies
RUN npm ci --omit=dev

# Generate Prisma Client for runtime
RUN npx prisma generate

# Copy built artifacts from builder
COPY --from=builder /usr/src/app/dist ./dist

# Non-root user for security
USER node

EXPOSE 3000

CMD ["node", "dist/main.js"]
