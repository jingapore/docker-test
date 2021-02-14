FROM alpine:3.10

RUN ["apk", "update"]
RUN ["apk", "upgrade"]
RUN ["apk", "add", "bash"]

COPY set_bash_env /etc
COPY set_sh_env /etc
COPY entrypoint.sh /etc

ENV ENV "/etc/set_sh_env"
ENV BASH_ENV "/etc/set_bash_env"
RUN ["chmod", "+x", "/etc/entrypoint.sh"]
ENTRYPOINT [ "/etc/entrypoint.sh" ]