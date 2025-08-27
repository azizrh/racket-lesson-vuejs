# FROM racket/racket:8.13

# WORKDIR /srv

# # Install needed libs (web server + sandbox + json)
# RUN raco pkg install --batch --auto web-server-lib sandbox-lib json-lib

# COPY validator.rkt server.rkt ./

# EXPOSE 8080
# CMD ["racket", "server.rkt"]


FROM racket/racket:8.13-full

WORKDIR /srv
COPY validator.rkt server.rkt ./

EXPOSE 8080
CMD ["racket", "server.rkt"]
