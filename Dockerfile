FROM       crystallang/crystal:1.2.2-alpine
WORKDIR    /usr/local
COPY       . .
RUN        shards build --release --production --static --no-debug

FROM       crystallang/crystal:1.2.2-alpine AS development
RUN        apk add bash zsh fish git git-lfs zsh-vcs vim curl httpie
CMD        ["sleep","inf"]

FROM       scratch AS production
EXPOSE     3000
COPY       --from=0 /usr/local/bin/docker-state /docker-state
ENTRYPOINT ["/docker-state"]
