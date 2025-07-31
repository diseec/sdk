FROM node:alpine

WORKDIR /app

COPY . .

VOLUME [ "/project" ]

CMD ["sh", "cli", "help"]