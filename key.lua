-- This file receives the KEY from the global environment
-- It does NOT define its own KEY

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
        or (OxygenU and OxygenU.request)
        or (VegaX and VegaX.request)
    
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

-- Get REAL HWID from executor
local function getHWID()
    -- Try all known HWID functions
    if syn and syn.get_hwid then 
        return syn.get_hwid() 
    end
    if get_hwid then 
        return get_hwid() 
    end
    if fluxus and fluxus.get_hwid then
        return fluxus.get_hwid()
    end
    if sirhurt and sirhurt.get_hwid then
        return sirhurt.get_hwid()
    end
    if OxygenU and OxygenU.getHWID then
        return OxygenU.getHWID()
    end
    if VegaX and VegaX.getHWID then
        return VegaX.getHWID()
    end
    if identifyexecutor and identifyexecutor() == "ScriptWare" then
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end
    
    -- Fallback: generate and store a persistent HWID
    local success, stored = pcall(readfile, "voidauth_hwid.txt")
    if success and stored and #stored > 0 then 
        return stored 
    end
    
    -- Generate a unique ID based on system info
    local id = HttpService:GenerateGUID(false):gsub("-", "")
    local writeSuccess = pcall(writefile, "voidauth_hwid.txt", id)
    
    if not writeSuccess then
        -- Last resort: use game instance ID
        id = tostring(game:GetService("RunService"):GetRandomSeed()) .. 
             tostring(game:GetService("HttpService"):GenerateGUID(false))
        id = id:gsub("[^%w]", ""):sub(1, 32)
    end
    
    return id
end

-- Verify license with server
function VoidAuth.check(key)
    if not key or key == "" then
        return false, "No key provided"
    end
    
    local hwid = getHWID()
    
    local body = HttpService:JSONEncode({ 
        license_key = key, 
        hwid = hwid,
        timestamp = os.time(),
        executor = identifyexecutor and identifyexecutor() or "Unknown"
    })
    
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
        if data.success == true then
            return true, data.message or "License valid"
        elseif data.success == false then
            return false, data.reason or "Invalid license"
        elseif data.valid == true then
            return true, data.message or "License valid"
        elseif data.error then
            return false, data.error
        else
            return false, "Invalid response format"
        end
    end
    
    return false, "Unexpected response type"
end

-- Get the KEY from the global variable (set by the user's script)
-- This is the key change - it reads from _G or getgenv()
local USER_KEY = getgenv and getgenv().KEY or _G.KEY

if not USER_KEY or USER_KEY == "" then
    error("[VoidAuth] No KEY provided! Please set: local KEY = 'your-key' before loadstring")
end

-- Execute the license check
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("  CompassAuth License System v2.0  ")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🔑 Checking license key...")

local authorized, reason = VoidAuth.check(USER_KEY)

if not authorized then
    print("Access Denied!")
end

-- ✅ License verified — your script starts below this line
print("License verified successfully!")

-- ============================================
-- YOUR SCRIPT GOES BELOW THIS LINE
-- ============================================

-- The actual script content will be appended here by the loader
