
FROM alpine:latest

WORKDIR /app

COPY . .

CMD ["sh", "cli", "--help"]