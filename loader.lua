local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- ════════════════════════════════════════════════════════
-- ⚙️ CONFIGURATION
-- ════════════════════════════════════════════════════════

local CONFIG = {
    -- GitHub URLs (Update with your username)
    LICENSE_DB_URL = "https://raw.githubusercontent.com/morrisey233/monitorserver/main/licenses.json",
    MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/morrisey233/monitorserver/main/main.lua",
    
    -- Discord Webhook for Execution Logs
    LOG_WEBHOOK = "https://discord.com/api/webhooks/1443821638524211250/kZ6vVZyXzVKDxaK3PeMH6HwDg8Un-v-zZYta_gBXXWBafM2_bLoAkeUv9i_VnGB3zDYE",
    
    -- Info
    VERSION = "2.0.0",
    BRAND = "MORRIS MONITOR"
}

-- ════════════════════════════════════════════════════════
-- 🔐 SYSTEM FUNCTIONS
-- ════════════════════════════════════════════════════════

local function getHWID()
    return gethwid and gethwid() or game:GetService("RbxAnalyticsService"):GetClientId()
end

local function getExecutor()
    return identifyexecutor and identifyexecutor() or "Unknown"
end

local function saveLocal(data)
    if not isfolder("MorrisData") then makefolder("MorrisData") end
    writefile("MorrisData/session.json", HttpService:JSONEncode(data))
end

local function loadLocal()
    if isfile("MorrisData/session.json") then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile("MorrisData/session.json"))
        end)
        if success then return data end
    end
    return nil
end

local function notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end)
end

-- ════════════════════════════════════════════════════════
-- 📡 LICENSE VALIDATION
-- ════════════════════════════════════════════════════════

local function fetchDatabase()
    print("📥 Fetching database...")
    
    local success, response = pcall(function()
        return game:HttpGet(CONFIG.LICENSE_DB_URL)
    end)
    
    if not success then
        return nil, "❌ Connection failed!"
    end
    
    local parseSuccess, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    
    if not parseSuccess then
        return nil, "❌ Database error!"
    end
    
    return data, nil
end

local function validateKey(key)
    if not string.match(key, "^MORRIS%-[A-Z0-9]+$") then
        return false, "❌ Invalid format!\nUse: MORRIS-XXXXXXXX"
    end
    
    local db, err = fetchDatabase()
    if not db then return false, err end
    
    if not db[key] then
        return false, "❌ Key not found!"
    end
    
    local license = db[key]
    
    if license.status == "banned" then
        return false, "🔴 Key banned!"
    end
    
    if license.status == "expired" then
        return false, "⚫ Key expired: " .. license.expiry
    end
    
    local currentDate = os.date("%Y-%m-%d")
    if currentDate > license.expiry then
        return false, "⚫ Key expired: " .. license.expiry
    end
    
    return true, "✅ Valid! Welcome " .. license.user, license
end

-- ════════════════════════════════════════════════════════
-- 📡 EXECUTION LOG
-- ════════════════════════════════════════════════════════

local function sendLog(key, licenseData)
    local player = Players.LocalPlayer
    local hwid = getHWID()
    local executor = getExecutor()
    
    local embed = {
        title = "🚀 Script Execution",
        color = 5763719,
        fields = {
            {name = "🔑 Key", value = "`" .. key .. "`", inline = false},
            {name = "👤 Name", value = "**" .. player.DisplayName .. "**", inline = true},
            {name = "💎 Tier", value = licenseData.tier:upper(), inline = true},
            {name = "🖥️ HWID", value = "`" .. hwid:sub(1, 40) .. "...`", inline = false},
            {name = "⚙️ Executor", value = executor, inline = true},
            {name = "📅 Expires", value = licenseData.expiry, inline = true},
            {name = "🌐 Job ID", value = "`" .. game.JobId:sub(1, 20) .. "...`", inline = false}
        },
        footer = {text = "Morris Monitor v" .. CONFIG.VERSION},
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S") .. "Z"
    }
    
    pcall(function()
        request({
            Url = CONFIG.LOG_WEBHOOK,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                username = "Morris Monitor - Execution Log",
                embeds = {embed}
            })
        })
    end)
end

-- ════════════════════════════════════════════════════════
-- 🎨 GUI
-- ════════════════════════════════════════════════════════

local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    local Main = Instance.new("Frame")
    local UICorner = Instance.new("UICorner")
    local UIGradient = Instance.new("UIGradient")
    
    local Header = Instance.new("Frame")
    local HeaderCorner = Instance.new("UICorner")
    local Logo = Instance.new("TextLabel")
    local Version = Instance.new("TextLabel")
    
    local KeyLabel = Instance.new("TextLabel")
    local KeyBox = Instance.new("TextBox")
    local KeyCorner = Instance.new("UICorner")
    
    local WebhookLabel = Instance.new("TextLabel")
    local WebhookBox = Instance.new("TextBox")
    local WebhookCorner = Instance.new("UICorner")
    
    local ActivateBtn = Instance.new("TextButton")
    local BtnCorner = Instance.new("UICorner")
    
    local Status = Instance.new("TextLabel")
    local CloseBtn = Instance.new("TextButton")
    
    ScreenGui.Name = "MorrisLoader"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    Main.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Main.BorderSizePixel = 0
    Main.Position = UDim2.new(0.5, -220, 0.5, -180)
    Main.Size = UDim2.new(0, 440, 0, 360)
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui
    
    UICorner.CornerRadius = UDim.new(0, 16)
    UICorner.Parent = Main
    
    UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25))
    }
    UIGradient.Rotation = 135
    UIGradient.Parent = Main
    
    Header.BackgroundColor3 = Color3.fromRGB(200, 50, 100)
    Header.BorderSizePixel = 0
    Header.Size = UDim2.new(1, 0, 0, 80)
    Header.Parent = Main
    
    HeaderCorner.CornerRadius = UDim.new(0, 16)
    HeaderCorner.Parent = Header
    
    Logo.BackgroundTransparency = 1
    Logo.Position = UDim2.new(0, 20, 0, 15)
    Logo.Size = UDim2.new(1, -40, 0, 40)
    Logo.Font = Enum.Font.GothamBold
    Logo.Text = "👑 MORRIS MONITOR"
    Logo.TextColor3 = Color3.fromRGB(255, 255, 255)
    Logo.TextSize = 24
    Logo.TextXAlignment = Enum.TextXAlignment.Left
    Logo.Parent = Header
    
    Version.BackgroundTransparency = 1
    Version.Position = UDim2.new(0, 20, 0, 55)
    Version.Size = UDim2.new(1, -40, 0, 20)
    Version.Font = Enum.Font.Gotham
    Version.Text = "Fish IT Monitor • v" .. CONFIG.VERSION
    Version.TextColor3 = Color3.fromRGB(255, 200, 220)
    Version.TextSize = 11
    Version.TextXAlignment = Enum.TextXAlignment.Left
    Version.Parent = Header
    
    KeyLabel.BackgroundTransparency = 1
    KeyLabel.Position = UDim2.new(0, 20, 0, 100)
    KeyLabel.Size = UDim2.new(1, -40, 0, 20)
    KeyLabel.Font = Enum.Font.GothamBold
    KeyLabel.Text = "🔑 Enter Your MORRIS Key"
    KeyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyLabel.TextSize = 13
    KeyLabel.TextXAlignment = Enum.TextXAlignment.Left
    KeyLabel.Parent = Main
    
    KeyBox.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    KeyBox.BorderSizePixel = 0
    KeyBox.Position = UDim2.new(0, 20, 0, 125)
    KeyBox.Size = UDim2.new(1, -40, 0, 45)
    KeyBox.Font = Enum.Font.GothamMedium
    KeyBox.PlaceholderText = "MORRIS-XXXXXXXX"
    KeyBox.Text = ""
    KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyBox.TextSize = 14
    KeyBox.ClearTextOnFocus = false
    KeyBox.Parent = Main
    
    KeyCorner.CornerRadius = UDim.new(0, 10)
    KeyCorner.Parent = KeyBox
    
    WebhookLabel.BackgroundTransparency = 1
    WebhookLabel.Position = UDim2.new(0, 20, 0, 185)
    WebhookLabel.Size = UDim2.new(1, -40, 0, 20)
    WebhookLabel.Font = Enum.Font.GothamBold
    WebhookLabel.Text = "🔗 Discord Webhook URL"
    WebhookLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    WebhookLabel.TextSize = 13
    WebhookLabel.TextXAlignment = Enum.TextXAlignment.Left
    WebhookLabel.Visible = false
    WebhookLabel.Parent = Main
    
    WebhookBox.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    WebhookBox.BorderSizePixel = 0
    WebhookBox.Position = UDim2.new(0, 20, 0, 210)
    WebhookBox.Size = UDim2.new(1, -40, 0, 45)
    WebhookBox.Font = Enum.Font.GothamMedium
    WebhookBox.PlaceholderText = "https://discord.com/api/webhooks/..."
    WebhookBox.Text = ""
    WebhookBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    WebhookBox.TextSize = 12
    WebhookBox.ClearTextOnFocus = false
    WebhookBox.Visible = false
    WebhookBox.Parent = Main
    
    WebhookCorner.CornerRadius = UDim.new(0, 10)
    WebhookCorner.Parent = WebhookBox
    
    ActivateBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 100)
    ActivateBtn.BorderSizePixel = 0
    ActivateBtn.Position = UDim2.new(0, 20, 0, 275)
    ActivateBtn.Size = UDim2.new(1, -40, 0, 55)
    ActivateBtn.Font = Enum.Font.GothamBold
    ActivateBtn.Text = "🚀 VALIDATE KEY"
    ActivateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ActivateBtn.TextSize = 16
    ActivateBtn.Parent = Main
    
    BtnCorner.CornerRadius = UDim.new(0, 12)
    BtnCorner.Parent = ActivateBtn
    
    Status.BackgroundTransparency = 1
    Status.Position = UDim2.new(0, 20, 0, 335)
    Status.Size = UDim2.new(1, -40, 0, 20)
    Status.Font = Enum.Font.Gotham
    Status.Text = "💡 Enter your MORRIS key to continue"
    Status.TextColor3 = Color3.fromRGB(150, 150, 150)
    Status.TextSize = 10
    Status.Parent = Main
    
    CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Position = UDim2.new(1, -40, 0, 10)
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 20
    CloseBtn.Parent = Main
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 8)
    CloseCorner.Parent = CloseBtn
    
    return {
        GUI = ScreenGui,
        Main = Main,
        KeyBox = KeyBox,
        WebhookLabel = WebhookLabel,
        WebhookBox = WebhookBox,
        ActivateBtn = ActivateBtn,
        Status = Status,
        CloseBtn = CloseBtn
    }
end

-- ════════════════════════════════════════════════════════
-- 🚀 MAIN
-- ════════════════════════════════════════════════════════

local function main()
    print("═══════════════════════════════════════")
    print("👑 MORRIS MONITOR")
    print("📌 Version: " .. CONFIG.VERSION)
    print("═══════════════════════════════════════")
    
    local saved = loadLocal()
    if saved and saved.key and saved.webhook then
        print("🔍 Auto-login...")
        
        local valid, msg, licenseData = validateKey(saved.key)
        if valid then
            print("✅ Auto-login successful!")
            sendLog(saved.key, licenseData)
            
            print("📥 Loading main script...")
            local success, mainScript = pcall(function()
                return game:HttpGet(CONFIG.MAIN_SCRIPT_URL)
            end)
            
            if success then
                local env = getfenv()
                env.WEBHOOK_URL = saved.webhook
                env.LICENSE_KEY = saved.key
                loadstring(mainScript)()
                return
            end
        else
            print("⚠️ Auto-login failed")
        end
    end
    
    local GUI = createGUI()
    local validatedKey = nil
    local validatedLicense = nil
    
    GUI.ActivateBtn.MouseButton1Click:Connect(function()
        if not validatedKey then
            local key = GUI.KeyBox.Text:upper():gsub("%s+", "")
            
            if key == "" then
                GUI.Status.Text = "❌ Please enter your MORRIS key!"
                GUI.Status.TextColor3 = Color3.fromRGB(255, 100, 100)
                notify("❌ Error", "Key required!", 3)
                return
            end
            
            GUI.Status.Text = "⏳ Validating key..."
            GUI.Status.TextColor3 = Color3.fromRGB(255, 200, 100)
            GUI.ActivateBtn.Text = "⏳ VALIDATING..."
            
            wait(1)
            
            local valid, msg, licenseData = validateKey(key)
            
            if not valid then
                GUI.Status.Text = msg
                GUI.Status.TextColor3 = Color3.fromRGB(255, 100, 100)
                GUI.ActivateBtn.Text = "🚀 VALIDATE KEY"
                notify("❌ Invalid", msg, 5)
                return
            end
            
            validatedKey = key
            validatedLicense = licenseData
            
            GUI.Status.Text = "✅ Key valid! Now enter webhook"
            GUI.Status.TextColor3 = Color3.fromRGB(100, 255, 100)
            notify("✅ Success", msg, 3)
            
            GUI.WebhookLabel.Visible = true
            GUI.WebhookBox.Visible = true
            GUI.ActivateBtn.Text = "🚀 START MONITOR"
            GUI.ActivateBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
            
            TweenService:Create(GUI.Main, TweenInfo.new(0.3), {
                Size = UDim2.new(0, 440, 0, 450)
            }):Play()
            
        else
            local webhook = GUI.WebhookBox.Text:gsub("%s+", "")
            
            if webhook == "" or not string.match(webhook, "^https://discord%.com/api/webhooks/%d+/[%w_-]+$") then
                GUI.Status.Text = "❌ Invalid webhook URL!"
                GUI.Status.TextColor3 = Color3.fromRGB(255, 100, 100)
                notify("❌ Error", "Invalid webhook!", 3)
                return
            end
            
            GUI.Status.Text = "✅ Starting monitor..."
            GUI.Status.TextColor3 = Color3.fromRGB(100, 255, 100)
            
            sendLog(validatedKey, validatedLicense)
            saveLocal({key = validatedKey, webhook = webhook})
            
            wait(1)
            GUI.GUI:Destroy()
            
            print("📥 Loading main script...")
            local success, mainScript = pcall(function()
                return game:HttpGet(CONFIG.MAIN_SCRIPT_URL)
            end)
            
            if success then
                local env = getfenv()
                env.WEBHOOK_URL = webhook
                env.LICENSE_KEY = validatedKey
                loadstring(mainScript)()
                notify("✅ Started", "Monitor active!", 5)
            else
                warn("❌ Failed to load main script!")
                notify("❌ Error", "Load failed!", 5)
            end
        end
    end)
    
    GUI.CloseBtn.MouseButton1Click:Connect(function()
        GUI.GUI:Destroy()
    end)
end

main()📁 FILE 3: main.lualua--[[
    🎣 FISH IT MONITOR - MAIN SCRIPT
    👑 MORRIS Edition
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local CONFIG = {
    WEBHOOK_URL = WEBHOOK_URL or error("WEBHOOK_URL not set!"),
    LICENSE_KEY = LICENSE_KEY or error("LICENSE_KEY not set!"),
    VERSION = "2.0.0",
    COOLDOWN = 3,
    ICON_URL = "https://media.discordapp.net/attachments/1389619964767371324/1440828732704161892/Desain_tanpa_judul__3_-removebg-preview.png"
}

local Storage = {
    lastUpdate = 0,
    isRunning = false,
    connections = {},
    gui = nil
}

local function getRarestFish(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local rarest = leaderstats:FindFirstChild("Rarest Fish") 
                    or leaderstats:FindFirstChild("Rarest")
                    or leaderstats:FindFirstChild("RarestFish")
        if rarest then
            return tostring(rarest.Value)
        end
    end
    return "N/A"
end

local function notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5,
            Icon = CONFIG.ICON_URL
        })
    end)
end

local function sendUpdate(eventType, playerName)
    local now = tick()
    if now - Storage.lastUpdate < CONFIG.COOLDOWN then
        print("⏳ Cooldown active...")
        return
    end
    Storage.lastUpdate = now
    
    local playerList = {}
    local playerCount = 0
    
    for _, player in pairs(Players:GetPlayers()) do
        playerCount = playerCount + 1
        table.insert(playerList, {
            name = player.DisplayName,
            rarest = getRarestFish(player)
        })
    end
    
    table.sort(playerList, function(a, b) return a.name < b.name end)
    
    local playerText = {}
    for i, p in ipairs(playerList) do
        table.insert(playerText, string.format(
            "`%02d` **%s** • `%s`",
            i, p.name, p.rarest
        ))
    end
    
    local description = playerCount == 0 and "```\n⚠️ Server empty\n```" or table.concat(playerText, "\n")
    
    local eventField = nil
    if eventType ~= "initial" then
        local emoji = eventType == "join" and "📥" or "📤"
        local action = eventType == "join" and "joined" or "left"
        local color = eventType == "join" and "🟢" or "🔴"
        
        eventField = {
            name = "🔔 Recent Activity",
            value = string.format("%s **%s** %s %s the server", emoji, playerName, color, action),
            inline = false
        }
    end
    
    local embed = {
        author = {
            name = "Morris Monitor v" .. CONFIG.VERSION,
            icon_url = CONFIG.ICON_URL
        },
        title = "🎣 Live Server Status",
        description = description,
        color = eventType == "join" and 5763719 or (eventType == "leave" and 15548997 or 3447003),
        fields = {},
        footer = {
            text = string.format("Online: %d • Job: %s", playerCount, game.JobId:sub(1, 8) .. "..."),
            icon_url = CONFIG.ICON_URL
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S") .. "Z"
    }
    
    if eventField then table.insert(embed.fields, eventField) end
    
    table.insert(embed.fields, {
        name = "📊 Server Statistics",
        value = string.format("```\nActive Players: %d\nStatus: 🟢 Online\n```", playerCount),
        inline = false
    })
    
    pcall(function()
        request({
            Url = CONFIG.WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                username = "Morris Monitor",
                avatar_url = CONFIG.ICON_URL,
                embeds = {embed}
            })
        })
    end)
    
    print(string.format("✅ Update sent! Players: %d", playerCount))
end

local function createStatusGUI()
    if Storage.gui then pcall(function() Storage.gui:Destroy() end) end
    
    local ScreenGui = Instance.new("ScreenGui")
    local MainFrame = Instance.new("Frame")
    local UICorner = Instance.new("UICorner")
    local UIStroke = Instance.new("UIStroke")
    
    local Header = Instance.new("Frame")
    local HeaderCorner = Instance.new("UICorner")
    local Title = Instance.new("TextLabel")
    local CloseBtn = Instance.new("TextButton")
    
    local StatusLabel = Instance.new("TextLabel")
    local InfoLabel = Instance.new("TextLabel")
    
    ScreenGui.Name = "MorrisStatus"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 999
    ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    MainFrame.Size = UDim2.new(0, 280, 0, 90)
    MainFrame.Position = UDim2.new(1, -290, 0, 10)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = MainFrame
    
    UIStroke.Color = Color3.fromRGB(200, 50, 100)
    UIStroke.Thickness = 2
    UIStroke.Parent = MainFrame
    
    Header.Size = UDim2.new(1, 0, 0, 35)
    Header.BackgroundColor3 = Color3.fromRGB(200, 50, 100)
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header
    
    local HeaderFix = Instance.new("Frame")
    HeaderFix.Size = UDim2.new(1, 0, 0, 15)
    HeaderFix.Position = UDim2.new(0, 0, 1, -15)
    HeaderFix.BackgroundColor3 = Color3.fromRGB(200, 50, 100)
    HeaderFix.BorderSizePixel = 0
    HeaderFix.Parent = Header
    
    Title.Size = UDim2.new(1, -60, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "👑 Morris Monitor"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header
    
    CloseBtn.Size = UDim2.new(0, 25, 0, 25)
    CloseBtn.Position = UDim2.new(1, -30, 0, 5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 18
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = Header
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(1, 0)
    CloseCorner.Parent = CloseBtn
    
    StatusLabel.Size = UDim2.new(1, -20, 0, 20)
    StatusLabel.Position = UDim2.new(0, 10, 0, 45)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "🟢 Active • Monitoring..."
    StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    StatusLabel.TextSize = 12
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = MainFrame
    
    InfoLabel.Size = UDim2.new(1, -20, 0, 18)
    InfoLabel.Position = UDim2.new(0, 10, 0, 67)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.Text = "📊 Players: 0 • Updates: 0"
    InfoLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    InfoLabel.TextSize = 10
    InfoLabel.Font = Enum.Font.Gotham
    InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    InfoLabel.Parent = MainFrame
    
    Storage.gui = ScreenGui
    
    CloseBtn.MouseButton1Click:Connect(function()
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(1, 0, 0, 10)
        }):Play()
        wait(0.3)
        ScreenGui:Destroy()
        Storage.gui = nil
    end)
    
    local updateCount = 0
    task.spawn(function()
        while ScreenGui.Parent do
            wait(CONFIG.COOLDOWN)
            updateCount = updateCount + 1
            InfoLabel.Text = string.format("📊 Players: %d • Updates: %d", #Players:GetPlayers(), updateCount)
        end
    end)
    
    task.spawn(function()
        while ScreenGui.Parent do
            TweenService:Create(UIStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Transparency = 0.3
            }):Play()
            wait(1)
            TweenService:Create(UIStroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Transparency = 0
            }):Play()
            wait(1)
        end
    end)
end

local function startMonitoring()
    if Storage.isRunning then return end
    Storage.isRunning = true
    
    print("═══════════════════════════════════════")
    print("👑 MORRIS MONITOR")
    print("📌 Version: " .. CONFIG.VERSION)
    print("═══════════════════════════════════════")
    
    createStatusGUI()
    
    print("📤 Sending initial update...")
    wait(1)
    sendUpdate("initial", "System")
    
    local joinConn = Players.PlayerAdded:Connect(function(player)
        print("📥 Player joined:", player.DisplayName)
        wait(2)
        sendUpdate("join", player.DisplayName)
        notify("Player Joined", player.DisplayName .. " joined!", 3)
    end)
    table.insert(Storage.connections, joinConn)
    
    local leaveConn = Players.PlayerRemoving:Connect(function(player)
        print("📤 Player left:", player.DisplayName)
        sendUpdate("leave", player.DisplayName)
        notify("Player Left", player.DisplayName .. " left!", 3)
    end)
    table.insert(Storage.connections, leaveConn)
    
    print("✅ Monitor active!")
    notify("👑 Morris Monitor", "Monitor is now active!", 5)
end

print("✅ Main script loaded!")
print("🚀 Starting monitor...")

startMonitoring()

print("🎉 Morris Monitor initialized!")
