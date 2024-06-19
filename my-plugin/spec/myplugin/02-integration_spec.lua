local helpers = require "spec.helpers"


local PLUGIN_NAME = "myplugin"

local strategy = "postgres"

describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
  local client

  lazy_setup(function()

    local bp = helpers.get_db_utils(strategy == "off" and "postgres" or strategy, nil, { PLUGIN_NAME })

    -- Inject a test route. No need to create a service, there is a default
    -- service which will echo the request.
    local route1 = bp.routes:insert({
      paths = {"/test"}
    })

    -- add the plugin to test to the route we created
    bp.plugins:insert{
      name = PLUGIN_NAME,
      route = {
          id = route1.id
      },
      config = {
          authentication_url = "http://authservice:3000/auth/validate/token",
          authorization_url = "http://authservice:3000/auth/validate/customer"
      }
    }

    -- start kong
    assert(helpers.start_kong({
      -- set the strategy
      database   = strategy,
      -- use the custom test template to create a local mock server
      nginx_conf = "spec/fixtures/custom_nginx.template",
      -- make sure our plugin gets loaded
      plugins = "bundled," .. PLUGIN_NAME,
      -- write & load declarative config, only if 'strategy=off'
      declarative_config = strategy == "off" and helpers.make_yaml_file() or nil,
    }))
  end)

  lazy_teardown(function()
    helpers.stop_kong(nil, true)
  end)

  before_each(function()
    client = helpers.proxy_client()
  end)

  after_each(function()
    if client then client:close() end
  end)

  describe("Happy Path", function()
    it("authentication and authorization", function()
        -- add the plugin to test to the route we created
        local r = client:get("/test", {
            headers = {
                authorization = "Bearer token1"
            },
            query = {
              custId = "customer1"
            }
        })
        print(r)
        -- validate that the request succeeded, response status 200
        assert.response(r).has.status(200)
    end)
  end)

  describe("Failure Scenarios", function()
    it("Authentication failed", function()

        local r = client:get("/test", {
            headers = {
            }
        })
        assert.response(r).has.status(401)
        local body, err = r:read_body()
        assert.equal("Authentication Failed", body)
    end)

    it("Authorization failed", function()

        local r = client:get("/test", {
            headers = {
                authorization = "Bearer token1"
            }
        })
        assert.response(r).has.status(403)
        local body, err = r:read_body()
        assert.equal("Authorization Failed", body)
    end)
  end)

end)