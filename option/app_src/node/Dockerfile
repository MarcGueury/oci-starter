FROM node:16
COPY src/* /app/
WORKDIR /app
RUN npm install
ENTRYPOINT ["node","rest.js"]