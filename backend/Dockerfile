FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install && npm cache clean --force

COPY . .
RUN npm run build
RUN npm prune --production

FROM node:18-alpine AS production

RUN addgroup -g 1001 -S nodejs && \
    adduser -S backend -u 1001

WORKDIR /app

COPY --from=builder --chown=backend:nodejs /app/dist ./dist
COPY --from=builder --chown=backend:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=backend:nodejs /app/package*.json ./

USER backend

EXPOSE 3847

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3847/api/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

CMD ["npm", "start"]