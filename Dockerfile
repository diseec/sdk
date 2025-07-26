FROM node:alpine

RUN apk add --no-cache curl tar

WORKDIR /app

COPY . .

VOLUME [ "/project" ]

# CMD [\
#     "sh", "-c", "yarn add -DW @diseec/devops@$(node -p \"require('./package.json').devDependencies['@diseec/devops']\")"\
#     ]
CMD ["sh", "cli", "help"]