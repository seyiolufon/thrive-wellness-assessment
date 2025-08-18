FROM node:20-alpine
WORKDIR /app
COPY app/package.json .
RUN npm ci --omit=dev || npm i --omit=dev
COPY app/ .
EXPOSE 3000
HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3   CMD wget -qO- http://127.0.0.1:3000/healthz || exit 1
CMD ["npm", "start"]
