local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ════════════════════════════════════════════════════════
-- ⚙️ CONFIG
-- ════════════════════════════════════════════════════════

local CONFIG = {
    WEBHOOK_URL = WEBHOOK_URL,
    LICENSE_KEY = LICENSE_KEY,
    COOLDOWN = 2.5,
    BATCH_DELAY = 0.5,
    LOGO_URL = "https://cdn.discordapp.com/attachments/1389619964767371324/1440828732704161892/Desain_tanpa_judul__3_-removebg-preview.png"
}

-- ════════════════════════════════════════════════════════
-- 🔐 LICENSE VERIFICATION
-- ════════════════════════════════════════════════════════

local function verifyLicense()
    -- Check if LICENSE_KEY exists
    if not CONFIG.LICENSE_KEY or CONFIG.LICENSE_KEY == "" or CONFIG.LICENSE_KEY == "LICENSE_KEY" then
        return false, "No license key provided"
    end
    
    -- Check if WEBHOOK_URL exists
    if not CONFIG.WEBHOOK_URL or CONFIG.WEBHOOK_URL == "" or CONFIG.WEBHOOK_URL == "WEBHOOK_URL" then
        return false, "No webhook URL provided"
    end
    
    -- Additional validation: check license format (optional)
    if #CONFIG.LICENSE_KEY < 10 then
        return false, "Invalid license key format"
    end
    
    return true, "License verified"
end

-- ════════════════════════════════════════════════════════
-- 💾 CACHE SYSTEM (PERFORMANCE BOOST)
-- ════════════════════════════════════════════════════════

local Cache = {
    lastUpdate = 0,
    playerData = {},
    requestQueue = {},
    isProcessing = false
}

-- ════════════════════════════════════════════════════════
-- 📡 OPTIMIZED HTTP REQUEST
-- ════════════════════════════════════════════════════════

local httpFunc = nil

local function findHttpFunc()
    if httpFunc then return httpFunc end
    
    local funcs = {request, http_request, (syn and syn.request), (http and http.request)}
    
    for _, func in pairs(funcs) do
        if func then
            httpFunc = func
            return func
        end
    end
    
    return nil
end

local function httpRequest(url, body)
    local func = findHttpFunc()
    if not func then return false end
    
    return pcall(function()
        func({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = body
        })
    end)
end

-- ════════════════════════════════════════════════════════
-- 🎣 OPTIMIZED DATA FETCHING
-- ════════════════════════════════════════════════════════

local function getRarestFish(player)
    if Cache.playerData[player.UserId] then
        local cached = Cache.playerData[player.UserId]
        if tick() - cached.time < 1 then
            return cached.rarest
        end
    end
    
    local rarest = "N/A"
    pcall(function()
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local rarestStat = leaderstats:FindFirstChild("Rarest Fish") 
                            or leaderstats:FindFirstChild("Rarest")
                            or leaderstats:FindFirstChild("RarestFish")
            if rarestStat then
                rarest = tostring(rarestStat.Value)
            end
        end
    end)
    
    Cache.playerData[player.UserId] = {
        rarest = rarest,
        time = tick()
    }
    
    return rarest
end

-- ════════════════════════════════════════════════════════
-- 📤 OPTIMIZED WEBHOOK SENDER (ADVANCED EMBED)
-- ════════════════════════════════════════════════════════

local function sendUpdate(eventType, playerName)
    local now = tick()
    if now - Cache.lastUpdate < CONFIG.COOLDOWN then
        return
    end
    Cache.lastUpdate = now
    
    local playerList = {}
    local allPlayers = Players:GetPlayers()
    
    for i = 1, #allPlayers do
        local player = allPlayers[i]
        playerList[i] = {
            name = player.DisplayName,
            rarest = getRarestFish(player)
        }
    end
    
    table.sort(playerList, function(a, b) return a.name < b.name end)
    
    -- 🎯 Live Server Status Section
    local playerText = table.create(#playerList)
    for i = 1, #playerList do
        playerText[i] = string.format("`%02d` **%s** • `%s`", 
            i, 
            playerList[i].name, 
            playerList[i].rarest
        )
    end
    
    local playerListText = #playerList == 0 and "```\nNo players online\n```" 
                                              or table.concat(playerText, "\n")
    
    -- 📊 Build Fields
    local fields = {}
    
    -- Field 1: Live Server Status (Player List)
    fields[1] = {
        name = "🔴 Live Server Status",
        value = playerListText,
        inline = false
    }
    
    -- Field 2: Recent Activity
    if eventType ~= "initial" then
        local emoji = eventType == "join" and "🟢" or "🔴"
        local action = eventType == "join" and "joined the server" or "left the server"
        fields[2] = {
            name = "⚠️ Recent Activity",
            value = string.format("%s **%s** %s", emoji, playerName, action),
            inline = false
        }
    end
    
    -- Field 3: Server Statistics
    local jobId = game.JobId or "N/A"
    local region = "Auto"
    pcall(function()
        region = game:GetService("LocalizationService"):GetCountryRegionForPlayerAsync(Players.LocalPlayer) or "Auto"
    end)
    
    fields[#fields + 1] = {
        name = "📊 Server Statistics",
        value = string.format(
            "```\nActive Players: %d\nServer Status: 🟢 Online\nRegion: %s\n```",
            #playerList,
            region
        ),
        inline = false
    }
    
    -- 🎨 Build Embed
    local embed = {
        title = "🎣 Morris Monitor - Server Dashboard",
        color = eventType == "join" and 5763719 or (eventType == "leave" and 15548997 or 3447003),
        fields = fields,
        thumbnail = {
            url = CONFIG.LOGO_URL
        },
        footer = {
            text = string.format("Online: %d Players • Job: %s", #playerList, jobId:sub(1, 10)),
            icon_url = CONFIG.LOGO_URL
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S") .. "Z"
    }
    
    task.spawn(function()
        httpRequest(
            CONFIG.WEBHOOK_URL,
            HttpService:JSONEncode({embeds = {embed}})
        )
    end)
    
    print("✅ Dashboard updated! Players:", #playerList)
end

-- ════════════════════════════════════════════════════════
-- 🚀 OPTIMIZED EVENT HANDLERS
-- ════════════════════════════════════════════════════════

local function onPlayerAdded(player)
    task.wait(2)
    sendUpdate("join", player.DisplayName)
end

local function onPlayerRemoving(player)
    Cache.playerData[player.UserId] = nil
    sendUpdate("leave", player.DisplayName)
end

-- ════════════════════════════════════════════════════════
-- 🎯 MEMORY CLEANUP
-- ════════════════════════════════════════════════════════

local function cleanupCache()
    local now = tick()
    for userId, data in pairs(Cache.playerData) do
        if now - data.time > 5 then
            Cache.playerData[userId] = nil
        end
    end
end

task.spawn(function()
    while true do
        task.wait(10)
        cleanupCache()
    end
end)

-- ════════════════════════════════════════════════════════
-- 🚀 INITIALIZE WITH LICENSE CHECK
-- ════════════════════════════════════════════════════════

print("👑 Morris Monitor - Advanced Dashboard")
print("🔐 Verifying license...")

local isValid, message = verifyLicense()

if not isValid then
    warn("❌ LICENSE VERIFICATION FAILED: " .. message)
    warn("❌ Script terminated - Invalid or missing license")
    warn("⚠️ Please provide a valid LICENSE_KEY and WEBHOOK_URL")
    
    -- Kick local player if running on client
    if Players.LocalPlayer then
        Players.LocalPlayer:Kick("MORRIS GUARD\n\nKEY NOT VALID!!\n\n" .. message .. "\n\nPlease contact the script owner.")
    end
    
    return -- Stop script execution
end

print("✅ License verified: " .. message)

task.wait(1)
sendUpdate("initial", "System")

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("✅ Dashboard active!")
