FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY app.js server.js ./

FROM node:20-alpine

RUN apk upgrade --no-cache \
	&& rm -rf /usr/local/lib/node_modules/npm \
	&& rm -f /usr/local/bin/npm /usr/local/bin/npx

WORKDIR /app

COPY --from=build /app/app.js /app/server.js ./
COPY --from=build /app/node_modules ./node_modules

EXPOSE 3000

CMD ["node", "server.js"]
