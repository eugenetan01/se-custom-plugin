FROM kong/kong-gateway:3.4.0.0
USER root
RUN mkdir -p /tmp/my-plugin
COPY ./my-plugin /tmp/my-plugin
WORKDIR /tmp/my-plugin
RUN luarocks make
USER kong