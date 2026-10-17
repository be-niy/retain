FROM node:24-bookworm-slim AS frontend-build
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
ENV VITE_API_URL=/api
RUN npm run build

FROM node:24-bookworm-slim AS production
ENV NODE_ENV=production
WORKDIR /app/backend
COPY backend/package*.json ./
RUN npm ci --omit=dev
COPY backend/src/ ./src/
COPY --from=frontend-build /app/frontend/dist/ /app/frontend/dist/
USER node
CMD ["node", "src/server.js"]
