local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"
local constants = require "kong.constants"
local jwt_decoder = require "kong.plugins.jwt.jwt_parser"
local string_format = string.format
local dao = dao
local ngx_re_gmatch = ngx.re.gmatch


local JwtHandler = BasePlugin:extend()

JwtHandler.PRIORITY = 1000

--- Retrieve a JWT in a request.
-- Checks for the JWT in the `Authorization` header.
-- @param request ngx request object
-- @param conf Plugin configuration
-- @return token JWT token contained in request or nil
-- @return err
local function retrieve_token(request, conf)
  local uri_parameters = request.get_uri_args()

  local authorization_header = request.get_headers()["authorization"]
  if authorization_header then
    local iterator, iter_err = ngx_re_gmatch(authorization_header, "\\s*[Bb]earer\\s+(.+)")
    if not iterator then
      return nil, iter_err
    end

    local m, err = iterator()
    if err then
      return nil, err
    end

    if m and #m > 0 then
      return m[1]
    end
  end
end

function JwtHandler:new()
  JwtHandler.super.new(self, "jwt")
end

function JwtHandler:access(conf)
  JwtHandler.super.access(self)
  local token, err = retrieve_token(ngx.req, conf)
  if err then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
  end

  if not token then
    return responses.send_HTTP_UNAUTHORIZED()
  end

  -- Decode token to find out who the consumer is
  local jwt, err = jwt_decoder:new(token)
  if err then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR()
  end

  jwt_secret_value = conf.jwt_secret

  -- Now verify the JWT signature
  if not jwt:verify_signature(jwt_secret_value) then
    return responses.send_HTTP_FORBIDDEN("Invalid signature")
  end

  ngx.req.set_header("X-User-UUID", jwt.claims.uuid)

end

return JwtHandler
