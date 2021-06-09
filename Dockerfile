FROM       crystallang/crystal:1.0.0
WORKDIR    /usr/local
COPY       . .
RUN        shards build --production --static --no-debug --release -s -t

FROM       scratch
EXPOSE     3000
COPY       --from=0 /usr/local/bin/docker-state /docker-state
ENTRYPOINT ["/docker-state"]
