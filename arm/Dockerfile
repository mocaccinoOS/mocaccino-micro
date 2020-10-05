FROM luetpm/luet:latest-arm
ADD conf/luet.yaml.docker /etc/luet/luet.yaml
ADD conf/repos.conf.d/ /etc/luet/repos.conf.d

ENV USER=root

SHELL ["/usr/bin/luet", "install", "-d"]

RUN repository/luet-arm
RUN repository/mocaccino-micro-arm
RUN utils/busybox

SHELL ["/bin/sh", "-c"]
RUN rm -rf /var/cache/luet/packages/ /var/cache/luet/repos/

ENV TMPDIR=/tmp
ENTRYPOINT ["/bin/sh"]
