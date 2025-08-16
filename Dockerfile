FROM node:alpine

RUN apk add bash curl git git-lfs gh

RUN npm install -g @diseec/devops

WORKDIR /app

ENV IS_IN_CONTAINER=true

COPY . .

CMD ["bash", "cli", "help"]