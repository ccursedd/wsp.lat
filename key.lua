local KEY = "VOID-LLJE-8V4A-Y9FB"

local VoidAuth = {}
local HttpService = game:GetService("HttpService")

VoidAuth.endpoint = "https://tqninassljbrerabkcyd.supabase.co/rest/v1/rpc/check_license"
VoidAuth.apikey   = "sb_publishable_pXlWJepgj8moF0WN9ZSllA_yR8Ukwtb"

-- Detect the executor's HTTP function (works on all major executors)
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

-- HWID: tries executor identity, falls back to a stored random id
local function getHWID()
    if syn and syn.get_hwid then 
        return syn.get_hwid() 
    end
    if get_hwid then 
        return get_hwid() 
    end
    
    -- Stable fallback: persist a random id in a file
    local success, stored = pcall(readfile, "voidauth_hwid.txt")
    if success and stored and #stored > 0 then 
        return stored 
    end
    
    local id = HttpService:GenerateGUID(false):gsub("-", "")
    local writeSuccess, err = pcall(writefile, "voidauth_hwid.txt", id)
    if not writeSuccess then
        -- If can't write file, use a temporary HWID based on game instance
        id = tostring(game:GetService("RunService"):GetRandomSeed()) .. HttpService:GenerateGUID(false)
    end
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
    
    local success, data = pcall(HttpService.JSONDecode, HttpService, res.Body)
    if not success then
        return false, "Bad response from server: " .. tostring(data)
    end
    
    -- Handle different response formats
    if data and type(data) == "table" then
        if data.success ~= nil then
            return data.success == true, data.reason or data.message
        elseif data.valid ~= nil then
            return data.valid == true, data.reason or data.message
        else
            return false, "Invalid response format from server"
        end
    end
    
    return false, "Unexpected response type"
end

-- Execute the check
print("Checking license key...")

local authorized, reason = VoidAuth.check(KEY)

if not authorized then
    warn("[VoidAuth] Access denied: " .. (reason or "invalid key"))
    error("[VoidAuth] Access denied: " .. (reason or "invalid key"))
end

-- ✅ License verified — your script starts below this line
print("✅ License verified successfully!")
print("mev da goat")
