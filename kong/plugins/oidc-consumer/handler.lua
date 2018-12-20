local BasePlugin = require "kong.plugins.base_plugin"
local singletons = require "kong.singletons"
local responses = require "kong.tools.responses"
local kong_utils = require "kong.tools.utils"
local constants = require "kong.constants"

local utils = require("kong.plugins.oidc-consumer.utils")
local OidcConsumerHandler = BasePlugin:extend()

local ngx_set_header = ngx.req.set_header
local create_consumer = false

OidcConsumerHandler.PRIORITY = 900


function OidcConsumerHandler:new()
  OidcConsumerHandler.super.new(self, "oidc-consumer")
end

local function set_consumer(consumer)
  ngx_set_header(constants.HEADERS.CONSUMER_ID, consumer.id)
  ngx_set_header(constants.HEADERS.CONSUMER_CUSTOM_ID, consumer.custom_id)
  ngx_set_header(constants.HEADERS.CONSUMER_USERNAME, consumer.username)
  ngx.ctx.authenticated_consumer = consumer
  ngx.ctx.authenticated_credential = { id = "oidc", username = consumer.username }
  ngx_set_header(constants.HEADERS.ANONYMOUS, nil) -- in case of auth plugins concatenation 
end

local function load_consumer_by_username(consumer_username)
  local result, err = singletons.db.consumers:select_by_username(consumer_username)
  if not result then
    if not err then
      -- create consumer when not found in cache and no error occured
      err = "OidcConsumerHandler No consumer found with username: " .. consumer_username
      ngx.log(ngx.DEBUG, err)
      
      if create_consumer then 
        consumer = singletons.db.consumers:insert {
          id = kong_utils.uuid(),
          username = consumer_username
        }
    
        if consumer then 
          ngx.log(ngx.DEBUG, "New consumer created from oidc userInfo")
          return consumer
        end
      end
      return nil, nil
    end
    return nil, err
  end
  return result
end

local function handleOidcHeader(oidcUserInfo, config, ngx)
  local userInfo = utils.decodeUserInfo(oidcUserInfo, ngx)
  local usernameField = config.username_field
  create_consumer = config.create_consumer

  if not usernameField then 
    usernameField = 'email'
  end

  local usernameForLookup = userInfo[usernameField]
  if usernameForLookup then 
    -- get consumer by the username if possible
    local consumer_cache_key = singletons.db.consumers:cache_key(usernameForLookup)
    local consumer, err = singletons.cache:get(consumer_cache_key, nil,
                                                load_consumer_by_username,
                                                usernameForLookup, true)

    if err then
      return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
    end

    if consumer then 
      ngx.log(ngx.DEBUG, "OidcConsumerHandler Setting consumer found")
      set_consumer(consumer)
    end                    
  else
    ngx.log(ngx.DEBUG, "OidcConsumerHandler No username field found on decoded oidc userInfo header")
  end

end

function OidcConsumerHandler:access(config)
  OidcConsumerHandler.super.access(self)
  local oidcUserInfoHeader = ngx.req.get_headers()["X-Userinfo"]

  if oidcUserInfoHeader then
    ngx.log(ngx.DEBUG, "OidcConsumerHandler X-Userinfo  header found:  " .. oidcUserInfoHeader)
    handleOidcHeader(oidcUserInfoHeader, config, ngx)
  else
    ngx.log(ngx.DEBUG, "OidcConsumerHandler ignoring request, path: " .. ngx.var.request_uri)
  end

  ngx.log(ngx.DEBUG, "OidcConsumerHandler done")
end


return OidcConsumerHandler
