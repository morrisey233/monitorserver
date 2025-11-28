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
    VERSION = "1.0.0"
}

-- ════════════════════════════════════════════════════════
-- 🔧 UTILITIES (OPTIMIZED)
-- ════════════════════════════════════════════════════════

local function getHWID()
    return pcall(function()
        return gethwid and gethwid() or game:GetService("RbxAnalyticsService"):GetClientId()
    end) and gethwid() or "UNKNOWN"
end

local function notify(text)
    task.spawn(function()
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Morris",
                Text = text,
                Duration = 2
            })
        end)
    end)
end

-- Find HTTP function once
local httpFunc = request or http_request or (syn and syn.request) or (http and http.request)

local function httpRequest(url, method, headers, body)
    if not httpFunc then return false end
    return pcall(function()
        httpFunc({Url = url, Method = method, Headers = headers, Body = body})
    end)
end

-- ════════════════════════════════════════════════════════
-- 📡 VALIDATION (CACHED)
-- ════════════════════════════════════════════════════════

local cachedDB = nil
local dbCacheTime = 0

local function fetchDatabase()
    -- Use cache if fresh (30 seconds)
    if cachedDB and tick() - dbCacheTime < 30 then
        return cachedDB, nil
    end
    
    local success, response = pcall(function()
        return game:HttpGet(CONFIG.LICENSE_DB_URL)
    end)
    
    if not success then return nil, "Connection failed" end
    
    local parseSuccess, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    
    if not parseSuccess then return nil, "Database error" end
    
    -- Update cache
    cachedDB = data
    dbCacheTime = tick()
    
    return data, nil
end

local function validateKey(key)
    if not string.match(key, "^MORRIS%-[A-Z0-9]+$") then
        return false, "Invalid format"
    end
    
    local db, err = fetchDatabase()
    if not db then return false, err end
    
    local license = db[key]
    if not license then return false, "Key not found" end
    if license.status == "banned" then return false, "Key banned" end
    
    if os.date("%Y-%m-%d") > license.expiry then
        return false, "Key expired"
    end
    
    return true, license
end

-- ════════════════════════════════════════════════════════
-- 📤 LOGGING (ASYNC)
-- ════════════════════════════════════════════════════════

local function sendLog(key, licenseData)
    task.spawn(function()
        pcall(function()
            local embed = {
                title = "🚀 Execution",
                color = 5763719,
                fields = {
                    {name = "Key", value = "`" .. key .. "`", inline = false},
                    {name = "Name", value = Players.LocalPlayer.DisplayName, inline = true},
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
    end)
end

-- ════════════════════════════════════════════════════════
-- 🎨 LIGHTWEIGHT GUI
-- ════════════════════════════════════════════════════════

local function createGUI()
    local Screen = Instance.new("ScreenGui")
    Screen.Name = "MorrisAuth"
    Screen.Parent = gethui and gethui() or Players.LocalPlayer:WaitForChild("PlayerGui")
    Screen.ResetOnSpawn = false
    Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 0, 0, 0)
    Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    Main.BorderSizePixel = 0
    Main.Parent = Screen
    
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
    
    local Header = Instance.new("TextLabel")
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundColor3 = Color3.fromRGB(200, 50, 100)
    Header.BorderSizePixel = 0
    Header.Text = "👑 MORRIS MONITOR"
    Header.TextColor3 = Color3.new(1, 1, 1)
    Header.TextSize = 18
    Header.Font = Enum.Font.GothamBold
    Header.Parent = Main
    
    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)
    
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
    
    Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 8)
    
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
    
    Instance.new("UICorner", WebhookBox).CornerRadius = UDim.new(0, 8)
    
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
    
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    
    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1, -40, 0, 15)
    Status.Position = UDim2.new(0, 20, 0, 205)
    Status.BackgroundTransparency = 1
    Status.Text = "Enter your key"
    Status.TextColor3 = Color3.fromRGB(150, 150, 150)
    Status.TextSize = 10
    Status.Font = Enum.Font.Gotham
    Status.Parent = Main
    
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
    
    Instance.new("UICorner", Close).CornerRadius = UDim.new(1, 0)
    
    -- Animate
    task.spawn(function()
        TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 380, 0, 230)
        }):Play()
    end)
    
    return {Screen=Screen, Main=Main, KeyBox=KeyBox, WebhookLabel=WebhookLabel, 
            WebhookBox=WebhookBox, Btn=Btn, Status=Status, Close=Close}
end

-- ════════════════════════════════════════════════════════
-- 🚀 MAIN
-- ════════════════════════════════════════════════════════

local GUI = createGUI()
local validatedKey, validatedLicense = nil, nil

GUI.Btn.MouseButton1Click:Connect(function()
    if not validatedKey then
        local key = GUI.KeyBox.Text:upper():gsub("%s+", "")
        if key == "" then
            GUI.Status.Text = "❌ Enter key!"
            GUI.Status.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        
        GUI.Status.Text = "⏳ Validating..."
        GUI.Btn.Text = "..."
        
        task.wait(0.3)
        
        local valid, result = validateKey(key)
        if not valid then
            GUI.Status.Text = "❌ " .. result
            GUI.Status.TextColor3 = Color3.fromRGB(255, 100, 100)
            GUI.Btn.Text = "VALIDATE"
            notify(result)
            return
        end
        
        validatedKey, validatedLicense = key, result
        GUI.Status.Text = "✅ Valid! Enter webhook"
        GUI.Status.TextColor3 = Color3.fromRGB(100, 255, 100)
        GUI.WebhookLabel.Visible = true
        GUI.WebhookBox.Visible = true
        GUI.Btn.Text = "START"
        GUI.Btn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
        
        TweenService:Create(GUI.Main, TweenInfo.new(0.2), {Size = UDim2.new(0, 380, 0, 310)}):Play()
        TweenService:Create(GUI.Btn, TweenInfo.new(0.2), {Position = UDim2.new(0, 20, 0, 230)}):Play()
        TweenService:Create(GUI.Status, TweenInfo.new(0.2), {Position = UDim2.new(0, 20, 0, 285)}):Play()
    else
        local webhook = GUI.WebhookBox.Text:gsub("%s+", "")
        if not webhook:match("discord%.com/api/webhooks") then
            GUI.Status.Text = "❌ Invalid webhook!"
            GUI.Status.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        
        GUI.Status.Text = "🚀 Starting..."
        sendLog(validatedKey, validatedLicense)
        
        task.wait(0.3)
        GUI.Screen:Destroy()
        
        local script = game:HttpGet(CONFIG.MAIN_SCRIPT_URL)
        getfenv().WEBHOOK_URL = webhook
        getfenv().LICENSE_KEY = validatedKey
        loadstring(script)()
        notify("✅ Started!")
    end
end)

GUI.Close.MouseButton1Click:Connect(function() GUI.Screen:Destroy() end)
