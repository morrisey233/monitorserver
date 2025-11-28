local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local CONFIG = {
    WEBHOOK_URL = WEBHOOK_URL,
    LICENSE_KEY = LICENSE_KEY,
    COOLDOWN = 3
}

local lastUpdate = 0

local function httpRequest(url, method, headers, body)
    local funcs = {
        request,
        http_request,
        (syn and syn.request),
        (http and http.request)
    }
    
    for _, func in pairs(funcs) do
        if func then
            local success = pcall(function()
                func({
                    Url = url,
                    Method = method,
                    Headers = headers,
                    Body = body
                })
            end)
            if success then return true end
        end
    end
    
    return false
end

local function getRarestFish(player)
    local success, result = pcall(function()
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local rarest = leaderstats:FindFirstChild("Rarest Fish") 
                        or leaderstats:FindFirstChild("Rarest")
                        or leaderstats:FindFirstChild("RarestFish")
            if rarest then return tostring(rarest.Value) end
        end
        return "N/A"
    end)
    return success and result or "N/A"
end

local function sendUpdate(eventType, playerName)
    if tick() - lastUpdate < CONFIG.COOLDOWN then return end
    lastUpdate = tick()
    
    local playerList = {}
    for _, player in pairs(Players:GetPlayers()) do
        table.insert(playerList, {
            name = player.DisplayName,
            rarest = getRarestFish(player)
        })
    end
    
    table.sort(playerList, function(a, b) return a.name < b.name end)
    
    local playerText = {}
    for i, p in ipairs(playerList) do
        table.insert(playerText, string.format("`%02d` **%s** • `%s`", i, p.name, p.rarest))
    end
    
    local description = #playerList == 0 and "```\nServer empty\n```" or table.concat(playerText, "\n")
    
    local eventField = nil
    if eventType ~= "initial" then
        local emoji = eventType == "join" and "📥" or "📤"
        local color = eventType == "join" and "🟢" or "🔴"
        eventField = {
            name = "Activity",
            value = string.format("%s **%s** %s", emoji, playerName, color),
            inline = false
        }
    end
    
    local embed = {
        title = "🎣 Server Status",
        description = description,
        color = eventType == "join" and 5763719 or 15548997,
        fields = {},
        footer = {text = "Players: " .. #playerList},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S") .. "Z"
    }
    
    if eventField then table.insert(embed.fields, eventField) end
    
    pcall(function()
        httpRequest(
            CONFIG.WEBHOOK_URL,
            "POST",
            {["Content-Type"] = "application/json"},
            HttpService:JSONEncode({embeds = {embed}})
        )
    end)
    
    print("✅ Update sent! Players:", #playerList)
end

print("👑 Morris Monitor Active")

wait(1)
sendUpdate("initial", "System")

Players.PlayerAdded:Connect(function(player)
    wait(2)
    sendUpdate("join", player.DisplayName)
end)

Players.PlayerRemoving:Connect(function(player)
    sendUpdate("leave", player.DisplayName)
end)

print("✅ Monitoring started!")
