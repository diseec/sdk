FROM node:alpine

WORKDIR /app

RUN apk add bash

COPY . .

VOLUME [ "/project" ]

CMD ["sh", "cli", "help"]