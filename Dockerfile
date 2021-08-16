FROM quay.io/luet/base:master
ADD conf/luet.yaml.docker /etc/luet/luet.yaml
ADD conf/repos.conf.d/ /etc/luet/repos.conf.d

ENV USER=root

SHELL ["/usr/bin/luet", "install", "-y", "-d"]

RUN repository/luet
RUN repository/mocaccino-micro-stable
RUN utils/busybox

SHELL ["/bin/sh", "-c"]
RUN rm -rf /var/cache/luet/packages/ /var/cache/luet/repos/

ENV TMPDIR=/tmp
ENTRYPOINT ["/bin/sh"]
