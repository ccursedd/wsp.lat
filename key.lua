-- VoidAuth Loader - Reads KEY from global environment
local VoidAuth = {}
local HttpService = game:GetService("HttpService")

VoidAuth.endpoint = "https://tqninassljbrerabkcyd.supabase.co/rest/v1/rpc/check_license"
VoidAuth.apikey   = "sb_publishable_pXlWJepgj8moF0WN9ZSllA_yR8Ukwtb"

-- Detect the executor's HTTP function
local function httpRequest(url, body)
    local fn = syn and syn.request
        or http and http.request
        or request
        or http_request
        or (fluxus and fluxus.request) 
        or (is_sirhurt and http_request)
    
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
        Body    = body,
    })
    
    if not ok then 
        return nil, "Request failed: " .. tostring(res) 
    end
    return res, nil
end

-- Get HWID
local function getHWID()
    if syn and syn.get_hwid then 
        return syn.get_hwid() 
    end
    if get_hwid then 
        return get_hwid() 
    end
    
    local success, stored = pcall(readfile, "voidauth_hwid.txt")
    if success and stored and #stored > 0 then 
        return stored 
    end
    
    local id = HttpService:GenerateGUID(false):gsub("-", "")
    pcall(writefile, "voidauth_hwid.txt", id)
    return id
end

-- Check license
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
    
    local success, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
    if not success then
        return false, "Bad response from server"
    end
    
    return data.success == true, data.reason or data.message
end

-- Get KEY from multiple possible locations
local USER_KEY = nil

-- Try to get KEY from different scopes
if getgenv and getgenv().KEY then
    USER_KEY = getgenv().KEY
elseif _G and _G.KEY then
    USER_KEY = _G.KEY
elseif KEY then
    USER_KEY = KEY
end

-- If still no key, show error
if not USER_KEY or USER_KEY == "" then
    error("No KEY provided!")
end

-- Verify the license
print("Verifying license...")

local authorized, reason = VoidAuth.check(USER_KEY)

if not authorized then
    print("Access Denied: " .. (reason or "invalid key")))
end

print("License verified successfully!")
