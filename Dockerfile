FROM    node:12
EXPOSE  3000
WORKDIR /app
RUN     npm install --save express@4 dockerode@3
COPY    src /app/
CMD     ["node","app.js"]
