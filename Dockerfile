FROM quay.io/luet/base:develop
ADD conf/luet.yaml.docker /etc/luet/luet.yaml

ENV USER=root

SHELL ["/usr/bin/luet", "install", "-d"]

RUN repository/luet
RUN repository/mocaccino-micro
RUN utils/busybox

SHELL ["/bin/sh", "-c"]
RUN rm -rf /var/cache/luet/packages/ /var/cache/luet/repos/

ENV TMPDIR=/tmp
ENTRYPOINT ["/bin/sh"]
