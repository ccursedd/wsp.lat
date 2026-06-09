-- VoidAuth Loader - Reads KEY from global environment
local VoidAuth = {}
local HttpService = game:GetService("HttpService")

VoidAuth.endpoint = "https://tqninassljbrerabkcyd.supabase.co/rest/v1/rpc/check_license"
VoidAuth.apikey   = "sb_publishable_pXlWJepgj8moF0WN9ZSllA_yR8Ukwtb"

local function httpRequest(url, body)
    local fn = syn and syn.request or http and http.request or request or http_request
    if not fn then
        return nil, "No HTTP function found"
    end
    local ok, res = pcall(fn, {
        Url = url,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["apikey"] = VoidAuth.apikey,
        },
        Body = body,
    })
    if not ok then return nil, "Request failed" end
    return res, nil
end

local function getHWID()
    if syn and syn.get_hwid then return syn.get_hwid() end
    if get_hwid then return get_hwid() end
    local success, stored = pcall(readfile, "voidauth_hwid.txt")
    if success and stored and #stored > 0 then return stored end
    local id = HttpService:GenerateGUID(false):gsub("-", "")
    pcall(writefile, "voidauth_hwid.txt", id)
    return id
end

function VoidAuth.check(key)
    if not key or key == "" then return false, "No key provided" end
    local hwid = getHWID()
    local body = HttpService:JSONEncode({ license_key = key, hwid = hwid })
    local res, err = httpRequest(VoidAuth.endpoint, body)
    if not res then return false, err end
    local success, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
    if not success then return false, "Bad response" end
    return data.success == true, data.reason
end

local USER_KEY = getgenv and getgenv().KEY or _G.KEY or KEY
if not USER_KEY or USER_KEY == "" then
    error("No KEY provided! Set: local KEY = 'your-key'")
end

local authorized, reason = VoidAuth.check(USER_KEY)
if not authorized then
    error("Access denied: " .. (reason or "invalid key"))
end

print("License verified!")
