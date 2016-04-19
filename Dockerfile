FROM centos:7

ENV KONG_VERSION 0.8.0

RUN yum install -y epel-release
RUN yum install -y https://github.com/Mashape/kong/releases/download/$KONG_VERSION/kong-$KONG_VERSION.el7.noarch.rpm && \
    yum clean all

ADD . /kong/plugins/jwt-validate
COPY kong.yml /etc/kong/kong.yml
VOLUME ["/etc/kong/"]

ENV LUA_PATH ";;;/kong/plugins/jwt-validate/?.lua"

RUN chmod +x /kong/plugins/jwt-validate/setup.sh

CMD /kong/plugins/jwt-validate/./setup.sh && kong start

EXPOSE 8000 8443 8001 7946