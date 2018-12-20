local cjson = require("cjson")

local M = {}

function M.decodeUserInfo(oidcUserInfoHeader, ngx)
  if not oidcUserInfoHeader then
    return {}
  end

  local userinfo = ngx.decode_base64(oidcUserInfoHeader)
  return cjson.decode(userinfo)
end

return M
