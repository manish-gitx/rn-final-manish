FROM node:20-alpine AS builder

WORKDIR /app

COPY TalkToJesus-backend/package*.json ./
RUN npm ci

COPY TalkToJesus-backend/tsconfig.json ./
COPY TalkToJesus-backend/src ./src
RUN npm run build

FROM node:20-alpine

WORKDIR /app

COPY TalkToJesus-backend/package*.json ./
RUN npm ci --omit=dev

COPY --from=builder /app/dist ./dist

EXPOSE 8080

ENV PORT=8080
ENV NODE_ENV=production

CMD ["node", "dist/index.js"]
