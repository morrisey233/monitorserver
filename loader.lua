local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- ════════════════════════════════════════════════════════
-- ⚙️ CONFIG
-- ════════════════════════════════════════════════════════

local CONFIG = {
    LICENSE_DB_URL = "https://raw.githubusercontent.com/morrisey233/monitorserver/main/licenses.json",
    MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/morrisey233/monitorserver/main/main.lua",
    LOG_WEBHOOK = "https://discord.com/api/webhooks/1443821638524211250/kZ6vVZyXzVKDxaK3PeMH6HwDg8Un-v-zZYta_gBXXWBafM2_bLoAkeUv9i_VnGB3zDYE",
    VERSION = "2.0.0"
}

-- ════════════════════════════════════════════════════════
-- 🔧 UTILITIES
-- ════════════════════════════════════════════════════════

local function getHWID()
    local success, hwid = pcall(function()
        if gethwid then return gethwid() end
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    return success and hwid or "UNKNOWN"
end

local function saveLocal(data)
    pcall(function()
        if not isfolder("MorrisData") then makefolder("MorrisData") end
        writefile("MorrisData/session.json", HttpService:JSONEncode(data))
    end)
end

local function loadLocal()
    local success, data = pcall(function()
        if isfile("MorrisData/session.json") then
            return HttpService:JSONDecode(readfile("MorrisData/session.json"))
        end
    end)
    return success and data or nil
end

local function notify(text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Morris Monitor",
            Text = text,
            Duration = 3
        })
    end)
end

local function httpRequest(url, method, headers, body)
    local funcs = {
        request,
        http_request,
        (syn and syn.request),
        (http and http.request)
    }
    
    for _, func in pairs(funcs) do
        if func then
            local success, result = pcall(function()
                return func({
                    Url = url,
                    Method = method,
                    Headers = headers,
                    Body = body
                })
            end)
            if success then return true, result end
        end
    end
    
    return false, nil
end

-- ════════════════════════════════════════════════════════
-- 📡 VALIDATION
-- ════════════════════════════════════════════════════════

local function fetchDatabase()
    local success, response = pcall(function()
        return game:HttpGet(CONFIG.LICENSE_DB_URL)
    end)
    
    if not success then return nil, "Connection failed" end
    
    local parseSuccess, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    
    if not parseSuccess then return nil, "Database error" end
    
    return data, nil
end

local function validateKey(key)
    if not string.match(key, "^MORRIS%-[A-Z0-9]+$") then
        return false, "Invalid format"
    end
    
    local db, err = fetchDatabase()
    if not db then return false, err end
    
    if not db[key] then return false, "Key not found" end
    
    local license = db[key]
    
    if license.status == "banned" then return false, "Key banned" end
    
    local currentDate = os.date("%Y-%m-%d")
    if currentDate > license.expiry then return false, "Key expired" end
    
    return true, license
end

-- ════════════════════════════════════════════════════════
-- 📤 LOGGING
-- ════════════════════════════════════════════════════════

local function sendLog(key, licenseData)
    pcall(function()
        local player = Players.LocalPlayer
        
        local embed = {
            title = "🚀 Execution",
            color = 5763719,
            fields = {
                {name = "Key", value = "`" .. key .. "`", inline = false},
                {name = "Name", value = player.DisplayName, inline = true},
                {name = "Tier", value = licenseData.tier, inline = true},
                {name = "HWID", value = "`" .. getHWID():sub(1, 30) .. "...`", inline = false}
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S") .. "Z"
        }
        
        httpRequest(
            CONFIG.LOG_WEBHOOK,
            "POST",
            {["Content-Type"] = "application/json"},
            HttpService:JSONEncode({embeds = {embed}})
        )
    end)
end

-- ════════════════════════════════════════════════════════
-- 🎨 GUI
-- ════════════════════════════════════════════════════════

local function createGUI()
    -- Protect GUI creation
    local success, Screen = pcall(function()
        local s = Instance.new("ScreenGui")
        s.Name = "MorrisAuth"
        
        -- Try gethui() first (best), then PlayerGui (fallback)
        if gethui then
            s.Parent = gethui()
        else
            s.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
        end
        
        s.ResetOnSpawn = false
        s.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        return s
    end)
    
    if not success then
        warn("Failed to create GUI")
        return nil
    end
    
    -- Main Frame
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 0, 0, 0)
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    Main.BorderSizePixel = 0
    Main.Parent = Screen
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = Main
    
    -- Header
    local Header = Instance.new("TextLabel")
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundColor3 = Color3.fromRGB(200, 50, 100)
    Header.BorderSizePixel = 0
    Header.Text = "👑 MORRIS MONITOR"
    Header.TextColor3 = Color3.new(1, 1, 1)
    Header.TextSize = 18
    Header.Font = Enum.Font.GothamBold
    Header.Parent = Main
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header
    
    -- Key Input
    local KeyLabel = Instance.new("TextLabel")
    KeyLabel.Size = UDim2.new(1, -40, 0, 20)
    KeyLabel.Position = UDim2.new(0, 20, 0, 70)
    KeyLabel.BackgroundTransparency = 1
    KeyLabel.Text = "🔑 License Key"
    KeyLabel.TextColor3 = Color3.new(1, 1, 1)
    KeyLabel.TextSize = 12
    KeyLabel.Font = Enum.Font.GothamBold
    KeyLabel.TextXAlignment = Enum.TextXAlignment.Left
    KeyLabel.Parent = Main
    
    local KeyBox = Instance.new("TextBox")
    KeyBox.Size = UDim2.new(1, -40, 0, 40)
    KeyBox.Position = UDim2.new(0, 20, 0, 95)
    KeyBox.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    KeyBox.BorderSizePixel = 0
    KeyBox.PlaceholderText = "MORRIS-XXXXXXXX"
    KeyBox.Text = ""
    KeyBox.TextColor3 = Color3.new(1, 1, 1)
    KeyBox.TextSize = 14
    KeyBox.Font = Enum.Font.Gotham
    KeyBox.ClearTextOnFocus = false
    KeyBox.Parent = Main
    
    local KeyCorner = Instance.new("UICorner")
    KeyCorner.CornerRadius = UDim.new(0, 8)
    KeyCorner.Parent = KeyBox
    
    -- Webhook Input
    local WebhookLabel = Instance.new("TextLabel")
    WebhookLabel.Size = UDim2.new(1, -40, 0, 20)
    WebhookLabel.Position = UDim2.new(0, 20, 0, 150)
    WebhookLabel.BackgroundTransparency = 1
    WebhookLabel.Text = "🔗 Discord Webhook"
    WebhookLabel.TextColor3 = Color3.new(1, 1, 1)
    WebhookLabel.TextSize = 12
    WebhookLabel.Font = Enum.Font.GothamBold
    WebhookLabel.TextXAlignment = Enum.TextXAlignment.Left
    WebhookLabel.Visible = false
    WebhookLabel.Parent = Main
    
    local WebhookBox = Instance.new("TextBox")
    WebhookBox.Size = UDim2.new(1, -40, 0, 40)
    WebhookBox.Position = UDim2.new(0, 20, 0, 175)
    WebhookBox.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    WebhookBox.BorderSizePixel = 0
    WebhookBox.PlaceholderText = "https://discord.com/api/webhooks/..."
    WebhookBox.Text = ""
    WebhookBox.TextColor3 = Color3.new(1, 1, 1)
    WebhookBox.TextSize = 11
    WebhookBox.Font = Enum.Font.Gotham
    WebhookBox.ClearTextOnFocus = false
    WebhookBox.Visible = false
    WebhookBox.Parent = Main
    
    local WebhookCorner = Instance.new("UICorner")
    WebhookCorner.CornerRadius = UDim.new(0, 8)
    WebhookCorner.Parent = WebhookBox
    
    -- Button
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -40, 0, 45)
    Btn.Position = UDim2.new(0, 20, 0, 150)
    Btn.BackgroundColor3 = Color3.fromRGB(200, 50, 100)
    Btn.BorderSizePixel = 0
    Btn.Text = "VALIDATE"
    Btn.TextColor3 = Color3.new(1, 1, 1)
    Btn.TextSize = 14
    Btn.Font = Enum.Font.GothamBold
    Btn.Parent = Main
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = Btn
    
    -- Status
    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1, -40, 0, 15)
    Status.Position = UDim2.new(0, 20, 0, 205)
    Status.BackgroundTransparency = 1
    Status.Text = "Enter your key"
    Status.TextColor3 = Color3.fromRGB(150, 150, 150)
    Status.TextSize = 10
    Status.Font = Enum.Font.Gotham
    Status.Parent = Main
    
    -- Close
    local Close = Instance.new("TextButton")
    Close.Size = UDim2.new(0, 30, 0, 30)
    Close.Position = UDim2.new(1, -35, 0, 10)
    Close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    Close.BorderSizePixel = 0
    Close.Text = "×"
    Close.TextColor3 = Color3.new(1, 1, 1)
    Close.TextSize = 18
    Close.Font = Enum.Font.GothamBold
    Close.Parent = Main
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(1, 0)
    CloseCorner.Parent = Close
    
    -- Animate
    pcall(function()
        TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 380, 0, 230)
        }):Play()
    end)
    
    return {
        Screen = Screen,
        Main = Main,
        KeyBox = KeyBox,
        WebhookLabel = WebhookLabel,
        WebhookBox = WebhookBox,
        Btn = Btn,
        Status = Status,
        Close = Close
    }
end

-- ════════════════════════════════════════════════════════
-- 🚀 MAIN
-- ════════════════════════════════════════════════════════

local function main()
    print("👑 MORRIS MONITOR v" .. CONFIG.VERSION)
    
    -- Auto-login
    local saved = loadLocal()
    if saved and saved.key and saved.webhook then
        local valid, licenseData = validateKey(saved.key)
        if valid then
            sendLog(saved.key, licenseData)
            
            local success, script = pcall(function()
                return game:HttpGet(CONFIG.MAIN_SCRIPT_URL)
            end)
            
            if success then
                getfenv().WEBHOOK_URL = saved.webhook
                getfenv().LICENSE_KEY = saved.key
                loadstring(script)()
                return
            end
        end
    end
    
    -- Show GUI
    local GUI = createGUI()
    if not GUI then
        warn("GUI creation failed")
        return
    end
    
    local validatedKey = nil
    local validatedLicense = nil
    
    GUI.Btn.MouseButton1Click:Connect(function()
        if not validatedKey then
            -- Step 1: Validate Key
            local key = GUI.KeyBox.Text:upper():gsub("%s+", "")
            
            if key == "" then
                GUI.Status.Text = "Enter a key!"
                GUI.Status.TextColor3 = Color3.fromRGB(255, 100, 100)
                return
            end
            
            GUI.Status.Text = "Validating..."
            GUI.Btn.Text = "..."
            wait(0.5)
            
            local valid, result = validateKey(key)
            
            if not valid then
                GUI.Status.Text = result
                GUI.Status.TextColor3 = Color3.fromRGB(255, 100, 100)
                GUI.Btn.Text = "VALIDATE"
                notify("Invalid: " .. result)
                return
            end
            
            validatedKey = key
            validatedLicense = result
            
            GUI.Status.Text = "Key valid! Enter webhook"
            GUI.Status.TextColor3 = Color3.fromRGB(100, 255, 100)
            notify("Key valid!")
            
            GUI.WebhookLabel.Visible = true
            GUI.WebhookBox.Visible = true
            GUI.Btn.Text = "START"
            GUI.Btn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
            
            pcall(function()
                TweenService:Create(GUI.Main, TweenInfo.new(0.3), {
                    Size = UDim2.new(0, 380, 0, 310)
                }):Play()
                TweenService:Create(GUI.Btn, TweenInfo.new(0.3), {
                    Position = UDim2.new(0, 20, 0, 230)
                }):Play()
                TweenService:Create(GUI.Status, TweenInfo.new(0.3), {
                    Position = UDim2.new(0, 20, 0, 285)
                }):Play()
            end)
            
        else
            -- Step 2: Start
            local webhook = GUI.WebhookBox.Text:gsub("%s+", "")
            
            if webhook == "" or not webhook:match("discord%.com/api/webhooks") then
                GUI.Status.Text = "Invalid webhook!"
                GUI.Status.TextColor3 = Color3.fromRGB(255, 100, 100)
                return
            end
            
            GUI.Status.Text = "Starting..."
            
            sendLog(validatedKey, validatedLicense)
            saveLocal({key = validatedKey, webhook = webhook})
            
            wait(0.5)
            GUI.Screen:Destroy()
            
            local success, script = pcall(function()
                return game:HttpGet(CONFIG.MAIN_SCRIPT_URL)
            end)
            
            if success then
                getfenv().WEBHOOK_URL = webhook
                getfenv().LICENSE_KEY = validatedKey
                loadstring(script)()
                notify("Monitor started!")
            else
                notify("Failed to load script!")
            end
        end
    end)
    
    GUI.Close.MouseButton1Click:Connect(function()
        GUI.Screen:Destroy()
    end)
end

-- Run with error handling
local success, err = pcall(main)
if not success then
    warn("Error:", err)
    notify("Error: " .. tostring(err))
end
