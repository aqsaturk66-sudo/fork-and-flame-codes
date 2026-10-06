FROM node:22-slim AS build
WORKDIR /app
COPY package*.json ./
RUN apt-get update && apt-get install -y python3 make g++ && rm -rf /var/lib/apt/lists/* && npm ci
COPY . .
RUN npm run build && npm prune --omit=dev

FROM node:22-slim
WORKDIR /app
ENV NODE_ENV=production DATA_DIR=/data PORT=3000
COPY --from=build /app/package*.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/dist-server ./dist-server
VOLUME /data
EXPOSE 3000
CMD ["node", "dist-server/index.mjs"]
