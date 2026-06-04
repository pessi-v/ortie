# Debian (NOT alpine) — @tensorflow/tfjs-node's prebuilt native binary needs glibc.
FROM node:20-bookworm-slim

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci --omit=dev || npm install --omit=dev

# Bake the model into the image (no runtime network dependency).
COPY bin ./bin
RUN node bin/fetch_model.mjs

COPY server.js ./

ENV PORT=3000
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD node -e "fetch('http://localhost:'+(process.env.PORT||3000)+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "server.js"]
