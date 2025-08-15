FROM node:alpine

RUN apk add bash curl git git-lfs

RUN npm install -g @diseec/devops

WORKDIR /app

ENV IS_IN_CONTAINER=true

COPY . .

CMD ["bash", "cli", "help"]