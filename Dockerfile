FROM kong:0.14.1-alpine

RUN luarocks install kong-oidc
RUN luarocks install kong-oidc-consumer

# COPY kong/plugins/oidc-consumer /usr/local/share/lua/5.1/kong/plugins/oidc-consumer

CMD ["kong", "docker-start"]
