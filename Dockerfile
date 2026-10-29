FROM node:22-alpine

WORKDIR /app

# Copy package descriptors
COPY package*.json tsconfig.json ./

# Install dependencies fast without native build bloat
RUN npm install --prefer-offline --no-audit

# Copy source code and schemas
COPY functions ./functions
COPY database ./database
COPY docs ./docs

ENV NODE_ENV=development
ENV PORT=5001

EXPOSE 5001

CMD ["npx", "tsx", "functions/src/index.ts"]
