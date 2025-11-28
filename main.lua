local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ════════════════════════════════════════════════════════
-- ⚙️ CONFIG
-- ════════════════════════════════════════════════════════

local CONFIG = {
    WEBHOOK_URL = WEBHOOK_URL,
    LICENSE_KEY = LICENSE_KEY,
    COOLDOWN = 2.5, -- Reduced for faster updates
    BATCH_DELAY = 0.5 -- Delay between operations
}

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

-- Find best HTTP function once (optimization)
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
    -- Use cached data if available
    if Cache.playerData[player.UserId] then
        local cached = Cache.playerData[player.UserId]
        if tick() - cached.time < 1 then -- Cache for 1 second
            return cached.rarest
        end
    end
    
    -- Fetch new data
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
    
    -- Update cache
    Cache.playerData[player.UserId] = {
        rarest = rarest,
        time = tick()
    }
    
    return rarest
end

-- ════════════════════════════════════════════════════════
-- 📤 OPTIMIZED WEBHOOK SENDER
-- ════════════════════════════════════════════════════════

local function sendUpdate(eventType, playerName)
    -- Cooldown check
    local now = tick()
    if now - Cache.lastUpdate < CONFIG.COOLDOWN then
        return
    end
    Cache.lastUpdate = now
    
    -- Gather player data (optimized loop)
    local playerList = {}
    local allPlayers = Players:GetPlayers()
    
    for i = 1, #allPlayers do
        local player = allPlayers[i]
        playerList[i] = {
            name = player.DisplayName,
            rarest = getRarestFish(player)
        }
    end
    
    -- Sort (stable sort for consistency)
    table.sort(playerList, function(a, b) return a.name < b.name end)
    
    -- Build description (pre-allocate table)
    local playerText = table.create(#playerList)
    for i = 1, #playerList do
        playerText[i] = string.format("`%02d` **%s** • `%s`", 
            i, 
            playerList[i].name, 
            playerList[i].rarest
        )
    end
    
    local description = #playerList == 0 and "```\nServer empty\n```" 
                                          or table.concat(playerText, "\n")
    
    -- Event field (conditional)
    local fields = {}
    if eventType ~= "initial" then
        local emoji = eventType == "join" and "📥" or "📤"
        local color = eventType == "join" and "🟢" or "🔴"
        fields[1] = {
            name = "Activity",
            value = string.format("%s **%s** %s", emoji, playerName, color),
            inline = false
        }
    end
    
    -- Build embed (minimal object creation)
    local embed = {
        title = "🎣 Server Status",
        description = description,
        color = eventType == "join" and 5763719 or 15548997,
        fields = fields,
        footer = {text = "Players: " .. #playerList},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S") .. "Z"
    }
    
    -- Send async (non-blocking)
    task.spawn(function()
        httpRequest(
            CONFIG.WEBHOOK_URL,
            HttpService:JSONEncode({embeds = {embed}})
        )
    end)
    
    print("✅ Update sent! Players:", #playerList)
end

-- ════════════════════════════════════════════════════════
-- 🚀 OPTIMIZED EVENT HANDLERS
-- ════════════════════════════════════════════════════════

local function onPlayerAdded(player)
    -- Wait for leaderstats to load
    task.wait(2)
    sendUpdate("join", player.DisplayName)
end

local function onPlayerRemoving(player)
    -- Clear cache
    Cache.playerData[player.UserId] = nil
    sendUpdate("leave", player.DisplayName)
end

-- ════════════════════════════════════════════════════════
-- 🎯 MEMORY CLEANUP (PREVENT MEMORY LEAKS)
-- ════════════════════════════════════════════════════════

local function cleanupCache()
    local now = tick()
    for userId, data in pairs(Cache.playerData) do
        -- Remove stale cache (older than 5 seconds)
        if now - data.time > 5 then
            Cache.playerData[userId] = nil
        end
    end
end

-- Run cleanup every 10 seconds
task.spawn(function()
    while true do
        task.wait(10)
        cleanupCache()
    end
end)

-- ════════════════════════════════════════════════════════
-- 🚀 INITIALIZE
-- ════════════════════════════════════════════════════════

print("👑 Morris Monitor - Ultra Optimized")

-- Initial update
task.wait(1)
sendUpdate("initial", "System")

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

print("✅ Monitor active! (Optimized)")
