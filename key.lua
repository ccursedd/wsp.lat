local VoidAuth    = {}
local HttpService = game:GetService("HttpService")

VoidAuth.endpoint = "https://tqninassljbrerabkcyd.supabase.co/rest/v1/rpc/check_license"
VoidAuth.apikey   = "sb_publishable_pXlWJepgj8moF0WN9ZSllA_yR8Ukwtb"

-- Detect the executor's HTTP function (works on all major executors)
local function httpRequest(url, body)
  local fn = syn and syn.request
           or http and http.request
           or request
           or http_request

  if not fn then
    return nil, "No HTTP function found in this executor"
  end

  local ok, res = pcall(fn, {
    Url     = url,
    Method  = "POST",
    Headers = {
      ["Content-Type"]  = "application/json",
      ["apikey"]        = VoidAuth.apikey,
    },
    Body = body,
  })

  if not ok then return nil, "Request failed: " .. tostring(res) end
  return res, nil
end

-- HWID: tries executor identity, falls back to a stored random id
local function getHWID()
  if syn and syn.get_hwid then return syn.get_hwid() end
  if get_hwid then return get_hwid() end

  -- Stable fallback: persist a random id in a file
  local ok, stored = pcall(readfile, "voidauth_hwid.txt")
  if ok and stored and #stored > 0 then return stored end

  local id = HttpService:GenerateGUID(false):gsub("-", "")
  pcall(writefile, "voidauth_hwid.txt", id)
  return id
end

function VoidAuth.check(key)
  if not key or key == "" then
    return false, "No key provided"
  end

  local hwid = getHWID()
  local body = HttpService:JSONEncode({ license_key = key, hwid = hwid })
  local res, err = httpRequest(VoidAuth.endpoint, body)

  if not res then
    return false, err
  end

  local ok2, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
  if not ok2 then
    return false, "Bad response from server"
  end

  return data.success == true, data.reason
end


local authorized, reason = VoidAuth.check(KEY)

if not authorized then
  error("[VoidAuth] Access denied: " .. (reason or "invalid key"))
end

-- ✅ License verified — your script starts below this line

print("hi")
