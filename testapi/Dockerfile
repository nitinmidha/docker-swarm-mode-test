FROM node:argon
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY Server/package.json /usr/src/app
RUN npm install
COPY Server /usr/src/app/
CMD ["npm", "start"]