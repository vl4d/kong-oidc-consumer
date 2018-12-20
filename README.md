# Thanks
This project is utilizing other open source projects to provide its functionality. 
Specifically [nokia's kong oidc plugin](https://github.com/nokia/kong-oidc) Which adds the functionality of OpenID Connect Relaying party to [Kong](https://github.com/Mashape/kong).


# What is Kong OIDC Consumer plugin

The `X-Userinfo` header from the `kong-oidc` plugin contains the payload from the Userinfo Endpoint. 

```
X-Userinfo: {"preferred_username":"alice",
"email": "alice@wonderland.com","id":"60f65308-3510-40ca-83f0-e9c0151cc680","sub":"60f65308-3510-40ca-83f0-e9c0151cc680"}
```

Ensure that `email` is one of the scopes configured on the `kong-oidc` plugin as this is the default.

The plugin will then lookup the consumer based on a field within the `X-Userinfo` header (it is a configuration option with the default being email) to match a consumer's username. If the consumer doesn't exist it will create this consumer within kong. 

The plugin then sets the `ngx.ctx.authenticated_consumer` variable, which can be using in other Kong plugins:
```
ngx.ctx.authenticated_consumer = {{matched_consumer_found_or_created}}
```


## Dependencies

**kong-oidc** depends on the following package:

- [`lua-resty-openidc`](https://github.com/pingidentity/lua-resty-openidc/)
- [`kong-oidc` plugin](https://github.com/nokia/kong-oidc)


## Installation

If you're using `luarocks` execute the following:

     luarocks install kong-oidc-consumer

You also need to set the `KONG_PLUGINS` environment variable to contain the oidc-consumer plugin

     export KONG_PLUGINS=oidc,oidc-consumer
     
## Usage

### Parameters

| Parameter | Default  | Required | description |
| --- | --- | --- | --- |
| `name` || true | plugin name, has to be `oidc-consumer` |
| `config.username_field` |"email"| true | userInfo field that stores the username to be matched or created as a consumer |
| `config.create_consumer` |false| true | boolean which if `true` creates consumer if not found with the username being the username from the field above on the userInfo |

### Enabling OIDC-Consumer
Please first enable and configure the [`kong-oidc` plugin](https://github.com/nokia/kong-oidc).

### Oidc-consumer Mapping to Kong Versions
- oidc-consumer v0.0.1 -> kong 0.14.x


## Development

 - TODO
   -    [ ] Add Testing
   -    [ ] Update ReadMe with curl commands to configure plugin
   -    [ ] Get a continuos test environment


### Testing locally
Please see the `/scrips` folder which has a couple bash scripts than can help testing out the plugin. Assuming that you have docker locally installed.

- `build.sh`: To build the a docker image of of kong (called oidc-kong) which includes the kong-oidc plugin installed. 
- `install.sh`: Used to run docker for postgres and the kong built by `build.sh` and add the oidc plugin and oidc-consumer plugin available for kong. It also has konga as an option to manage the kong instance created. It  is linked to the running kong using hostname `kong`.

Run them with
```
$ sh ./scripts/build.sh
$ sh ./scripts/install.sh
```

This would require to manually setup the endpoint and plugins using a UI like konga or curl/http commands from the console. 

I utilize auth0 as my OIDP, which is why the docker image name is called `kong-auth0`.