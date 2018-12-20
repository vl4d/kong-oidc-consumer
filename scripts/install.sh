docker stop postgres && docker rm postgres
docker run -e "POSTGRES_USER=adminadmin" -e "POSTGRES_PASSWORD=something" -e "POSTGRES_DB=kong_tests" -d --name postgres postgres:9.5.15

echo "sleeping while postgres gets up and running (15 seconds)"
sleep 15

docker stop kong-auth0 && docker rm kong-auth0

docker run --rm \
    --name kong-auth0 \
    --link postgres:postgres \
    -e "KONG_DATABASE=postgres" \
    -e "KONG_PG_USER=adminadmin" \
    -e "KONG_PG_PASSWORD=something" \
    -e "KONG_PG_HOST=postgres" \
    -e "KONG_PG_DATABASE=kong_tests" \
    oidc-kong kong migrations up

echo "sleeping while migrations finish up (5 seconds)"
sleep 5

docker run -d \
    --name kong-auth0 \
    --link postgres:postgres \
    -e "KONG_DATABASE=postgres" \
    -e "KONG_PG_USER=adminadmin" \
    -e "KONG_PG_PASSWORD=something" \
    -e "KONG_PG_HOST=postgres" \
    -e "KONG_PG_DATABASE=kong_tests" \
    -e "KONG_ADMIN_LISTEN=0.0.0.0:8001" \
    -e "KONG_ADMIN_LISTEN_SSL=0.0.0.0:8444" \
    -e "KONG_LOG_LEVEL=debug" \
    -e "KONG_PLUGINS=oidc,oidc-consumer,jwt,acl" \
    -e "KONG_LUA_PACKAGE_PATH=/usr/local/oidc/?.lua;;" \
    -p 8000:8000 \
    -p 8443:8443 \
    -p 8001:8001 \
    -p 7946:7946 \
    -p 7946:7946/udp \
    oidc-kong


# docker stop konga && docker rm konga

# docker run -d \
# 	-p 1337:1337 \
#     --link kong-auth0:kong \
# 	--name konga \
# 	pantsel/konga:0.12.2

# docker stop pgadmin && docker rm pgadmin
# docker run -d \
#     --name pgadmin \
#     --link postgres:postgres \
#     -p 8080:80 \
#     -e "PGADMIN_DEFAULT_EMAIL=user@domain.com" \
#     -e "PGADMIN_DEFAULT_PASSWORD=SuperSecret" \
#     dpage/pgadmin4