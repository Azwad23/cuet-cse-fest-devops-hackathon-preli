FROM node:18-alpine AS production

RUN addgroup -g 1001 -S nodejs && \
    adduser -S gateway -u 1001

WORKDIR /app

COPY --chown=gateway:nodejs package*.json ./
RUN npm install --only=production && npm cache clean --force

COPY --chown=gateway:nodejs . .

USER gateway

EXPOSE 5921

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:5921/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

CMD ["npm", "start"]