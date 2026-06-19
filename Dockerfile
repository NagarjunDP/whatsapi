FROM node:24-alpine AS builder

RUN apk update && \
    apk add --no-cache git ffmpeg wget curl bash openssl

LABEL version="2.3.1" description="Api to control whatsapp features through http requests." 
LABEL maintainer="Davidson Gomes" git="https://github.com/DavidsonGomes"
LABEL contact="contato@evolution-api.com"

WORKDIR /evolution

COPY ./package*.json ./
COPY ./tsconfig.json ./
COPY ./tsup.config.ts ./

RUN npm ci --silent

COPY ./src ./src
COPY ./public ./public
COPY ./prisma ./prisma
COPY ./manager ./manager
COPY ./.env.example ./.env
COPY ./runWithProvider.js ./

COPY ./Docker ./Docker

RUN chmod +x ./Docker/scripts/* && dos2unix ./Docker/scripts/*

RUN ./Docker/scripts/generate_database.sh

RUN npm run build

FROM node:24-alpine AS final

RUN apk update && \
    apk add tzdata ffmpeg bash openssl

ENV TZ=America/Sao_Paulo
ENV DOCKER_ENV=true
ENV SERVER_PORT=7860

WORKDIR /evolution

RUN chown -R node:node /evolution

COPY --chown=node:node --from=builder /evolution/package.json ./package.json
COPY --chown=node:node --from=builder /evolution/package-lock.json ./package-lock.json

COPY --chown=node:node --from=builder /evolution/node_modules ./node_modules
COPY --chown=node:node --from=builder /evolution/dist ./dist
COPY --chown=node:node --from=builder /evolution/prisma ./prisma
COPY --chown=node:node --from=builder /evolution/manager ./manager
COPY --chown=node:node --from=builder /evolution/public ./public
COPY --chown=node:node --from=builder /evolution/.env ./.env
COPY --chown=node:node --from=builder /evolution/Docker ./Docker
COPY --chown=node:node --from=builder /evolution/runWithProvider.js ./runWithProvider.js
COPY --chown=node:node --from=builder /evolution/tsup.config.ts ./tsup.config.ts

ENV DOCKER_ENV=true

EXPOSE 7860

USER node

ENTRYPOINT ["/bin/bash", "-c", ". ./Docker/scripts/deploy_database.sh && npm run start:prod" ]
