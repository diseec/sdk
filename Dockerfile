# FROM node:alpine

# WORKDIR /app

# CMD [\
#     "sh", "-c", "yarn add -DW @diseec/devops@$(node -p \"require('./package.json').devDependencies['@diseec/devops']\")"\
#     ]