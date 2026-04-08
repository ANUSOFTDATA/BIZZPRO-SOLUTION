# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Install all dependencies (including devDependencies for TypeScript)
COPY package*.json ./
RUN npm ci

# Copy source code
COPY . .

# Build frontend
RUN npx vite build

# Compile server TypeScript
RUN npx tsc -p tsconfig.server.json

# Production stage
FROM node:20-alpine

WORKDIR /app

# Install production dependencies only
COPY package*.json ./
RUN npm ci --only=production

# Copy Prisma schema and generate client
COPY prisma ./prisma/
RUN npx prisma generate

# Copy compiled server code
COPY --from=builder /app/dist ./dist

# Copy uploads directory
COPY uploads ./uploads

# Expose port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:4000/health', (r) => { process.exit(r.statusCode === 200 ? 0 : 1) })"

# Start server
CMD ["node", "dist/index.js"]
