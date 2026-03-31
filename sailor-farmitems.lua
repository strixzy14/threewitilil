repeat task.wait() until game:IsLoaded()

--// ULTIMATE WEBHOOK LOGGER
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local lp = Players.LocalPlayer

--------------------------------------------------
-- REQUEST UNIVERSAL
--------------------------------------------------
local request =
    syn and syn.request or
    http_request or
    request or
    fluxus and fluxus.request or
    (http and http.request)

if not request then return end

--------------------------------------------------
-- EXECUTOR
--------------------------------------------------
local function GetExecutor()
    local name = "Unknown"
    pcall(function()
        if identifyexecutor then
            name = identifyexecutor()
        end
    end)
    return name
end

--------------------------------------------------
-- FPS
--------------------------------------------------
local function GetFPS()
    local fps = 60
    pcall(function()
        fps = math.floor(1 / RunService.RenderStepped:Wait())
    end)
    return fps
end

--------------------------------------------------
-- PING
--------------------------------------------------
local function GetPing()
    local ping = 0
    pcall(function()
        ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    end)
    return ping
end

--------------------------------------------------
-- MEMORY
--------------------------------------------------
local memory = math.floor(Stats:GetTotalMemoryUsageMb())

--------------------------------------------------
-- REGION
--------------------------------------------------
local region = "Unknown"
pcall(function()
    local r = request({Url="http://ip-api.com/json",Method="GET"})
    local data = HttpService:JSONDecode(r.Body)
    region = data.country
end)

--------------------------------------------------
-- GAME NAME
--------------------------------------------------
local gameName = "Unknown"
pcall(function()
    gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
end)

--------------------------------------------------
-- AVATAR THUMBNAIL (OFFICIAL API)
--------------------------------------------------
local thumb = ""
pcall(function()
    local res = request({
        Url="https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..lp.UserId.."&size=420x420&format=Png&isCircular=false",
        Method="GET"
    })
    local data = HttpService:JSONDecode(res.Body)
    thumb = data.data[1].imageUrl
end)

--------------------------------------------------
-- FLAGS / DETECTIONS
--------------------------------------------------
local flags = {}

if getgenv().DEX_LOADED then
    table.insert(flags,"Dex")
end

if getgenv().rspy then
    table.insert(flags,"RemoteSpy")
end

if lp.AccountAge < 30 then
    table.insert(flags,"Alt Account")
end

if _G.__HUB_ALREADY_RAN then
    table.insert(flags,"Multi Inject")
end
_G.__HUB_ALREADY_RAN = true

local flagText = (#flags>0 and table.concat(flags,", ")) or "None"

--------------------------------------------------
-- TIME
--------------------------------------------------
local unix = os.time()

--------------------------------------------------
-- EMBED
--------------------------------------------------
local embed = {
["embeds"] = {{
    ["title"] = "EXECUTION LOG",
    ["color"] = 0x00ff99,
    ["thumbnail"] = {["url"] = thumb},

    ["fields"] = {

        -- PLAYER
        {name="👤 Player",value=lp.Name.." ("..lp.DisplayName..")",inline=true},
        {name="🔎 Profile",value="https://www.roblox.com/users/"..lp.UserId.."/profile",inline=true},
        {name="📊 Account Age",value=lp.AccountAge.." days",inline=true},

        -- ENVIRONMENT
        {name="💻 Executor",value=GetExecutor(),inline=true},
        {name="⚡ Performance",value="FPS: "..GetFPS().." | Ping: "..GetPing().."ms",inline=true},
        {name="🧠 Memory",value=memory.." MB",inline=true},

        -- SERVER
        {name="🎮 Game",value=gameName,inline=true},
        {name="👥 Players",value=#Players:GetPlayers().."/"..Players.MaxPlayers,inline=true},
        {name="🌍 Country",value=region,inline=true},

        {name="🧩 PlaceId",value=tostring(game.PlaceId),inline=true},
        {name="🚨 Flags",value=flagText,inline=true},

        {name="📅 Executed",value="<t:"..unix..":R>",inline=false},
    },

    ["footer"] = {["text"]="xdflex logger"}
}}
}

--------------------------------------------------
-- SEND
--------------------------------------------------
request({
    Url = "https://discord.com/api/webhooks/1475079529377562645/wv_BURKvPsSF4kieeLvLQ2BiOuhZCC6SDxu-t4t-PCoG_4-4ORt2B1pws66r6RkiCkD6",
    Method = "POST",
    Headers = {["Content-Type"]="application/json"},
    Body = HttpService:JSONEncode(embed)
})

-------------------------------------------------
-- SERVICES
-------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local EquipRemote = Remotes:WaitForChild("EquipWeapon")
local PortalRemote = Remotes:WaitForChild("TeleportToPortal")
local HakiRemote = RemoteEvents:WaitForChild("HakiRemote")
local ObservationRemote = RemoteEvents:WaitForChild("ObservationHakiRemote")
local SettingsToggle = RemoteEvents:WaitForChild("SettingsToggle")

-------------------------------------------------
-- GLOBAL TOGGLES & CONFIG
-------------------------------------------------
local _G_AutoFarm = true
if getgenv().AutoFarm ~= nil then 
    _G_AutoFarm = getgenv().AutoFarm 
end

local _G_WhiteScreen = true
if getgenv().WhiteScreen ~= nil then 
    _G_WhiteScreen = getgenv().WhiteScreen 
end

local WEAPONS = {"Soul Reaper", "Strongest In History"} 
if getgenv().Weapons ~= nil and type(getgenv().Weapons) == "table" then
    WEAPONS = getgenv().Weapons
end

-- 🌟 ระบบตั้งค่าปุ่มสกิลผ่าน getgenv
local SKILLS = {"X"} -- ค่าเริ่มต้นถ้าไม่ได้ตั้ง config
if getgenv().Skills ~= nil and type(getgenv().Skills) == "table" then
    SKILLS = getgenv().Skills
end

-------------------------------------------------
-- 🚫 DISABLE ROBLOX NETWORK PAUSE NOTIFICATION (UPDATED)
-------------------------------------------------
task.spawn(function()
    local CoreGui = game:GetService("CoreGui")
    
    local function removeTarget(parent, name)
        pcall(function()
            local target = parent:FindFirstChild(name)
            if target then
                target:Destroy()
            end
        end)
    end

    -- 1. ลบ Notification UI ตัวหลัก
    removeTarget(CoreGui, "RobloxNetworkPauseNotification")

    -- 2. ลบ Module และ CoreScript ใน RobloxGui
    local robloxGui = CoreGui:FindFirstChild("RobloxGui")
    if robloxGui then
        -- ลบ Modules/NetworkPauseNotification
        local modules = robloxGui:FindFirstChild("Modules")
        if modules then
            removeTarget(modules, "NetworkPauseNotification")
        end
        
        -- ลบ CoreScripts/NetworkPause
        removeTarget(robloxGui, "CoreScripts/NetworkPause")
    end
end)

-------------------------------------------------
-- 💎 ULTRA MINIMAL CAPSULE UI (No Black Borders)
-------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XDFlex_Ultimate"
ScreenGui.ResetOnSpawn = false 
ScreenGui.DisplayOrder = 9999
ScreenGui.IgnoreGuiInset = true

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = player:WaitForChild("PlayerGui") end

local WhiteScreenFrame = Instance.new("Frame")
WhiteScreenFrame.Size = UDim2.new(1, 0, 1, 0)
WhiteScreenFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
WhiteScreenFrame.BorderSizePixel = 0
WhiteScreenFrame.ZIndex = 1 
WhiteScreenFrame.Visible = _G_WhiteScreen 
WhiteScreenFrame.Parent = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 360, 0, 45) 
MainFrame.Position = UDim2.new(0.5, -180, 0, 30) 
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ZIndex = 2 
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(1, 0)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Horizontal
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = MainFrame

local function CreateButton(text, color, z)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 105, 0, 32)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.ZIndex = z
    btn.Parent = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    return btn
end

local FarmBtn = CreateButton(_G_AutoFarm and "⚔️ Farm: ✅" or "⚔️ Farm: ❌", _G_AutoFarm and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60), 3)
local WhiteScreenBtn = CreateButton(_G_WhiteScreen and "⚪ Screen: ✅" or "⚫ Screen: ❌", _G_WhiteScreen and Color3.fromRGB(149, 165, 166) or Color3.fromRGB(52, 73, 94), 3)
local DiscordBtn = CreateButton("👾 Discord", Color3.fromRGB(88, 101, 242), 3)

if _G_WhiteScreen then pcall(function() RunService:Set3dRenderingEnabled(false) end) end

local function MakeDraggable(gui)
    local dragging, dragInput, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = gui.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
MakeDraggable(MainFrame)

FarmBtn.MouseButton1Click:Connect(function()
    _G_AutoFarm = not _G_AutoFarm
    FarmBtn.BackgroundColor3 = _G_AutoFarm and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
    FarmBtn.Text = _G_AutoFarm and "⚔️ Farm: ✅" or "⚔️ Farm: ❌"
end)

WhiteScreenBtn.MouseButton1Click:Connect(function()
    _G_WhiteScreen = not _G_WhiteScreen
    WhiteScreenBtn.BackgroundColor3 = _G_WhiteScreen and Color3.fromRGB(149, 165, 166) or Color3.fromRGB(52, 73, 94)
    WhiteScreenBtn.Text = _G_WhiteScreen and "⚪ Screen: ✅" or "⚫ Screen: ❌"
    WhiteScreenFrame.Visible = _G_WhiteScreen
    pcall(function() RunService:Set3dRenderingEnabled(not _G_WhiteScreen) end)
end)

DiscordBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        pcall(function() setclipboard("https://discord.gg/paWWE2nZzf") end)
        DiscordBtn.Text = "✅ Copied!"
        DiscordBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
    else
        DiscordBtn.Text = "❌ Error"
        DiscordBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    end
    task.delay(1.5, function()
        DiscordBtn.Text = "👾 Discord"
        DiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    end)
end)

-------------------------------------------------
-- GAME SETTINGS & FPS BOOST
-------------------------------------------------
pcall(function()
    local settingsToToggle = {"DisableCutscene", "DisableVFX", "MuteSFX", "MuteMusic", "DisableScreenShake", "RemoveTexture", "RemoveShadows"}
    for _, name in ipairs(settingsToToggle) do
        SettingsToggle:FireServer(name, true)
        task.wait(0.1)
    end
end)
settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

-------------------------------------------------
-- MAIN FARM ROUTE
-------------------------------------------------
local FarmRoute = {
    {portal = "Shibuya", pos = CFrame.new(1400.0594, 8.4861, 484.9847)},
    {portal = "Shibuya", pos = CFrame.new(1557.5450, 72.7205, -38.0354)},
    {portal = "Shibuya", pos = CFrame.new(1526.7109, 8.4861, 226.4409)},
    {portal = "Shibuya", pos = CFrame.new(1852.6188, 8.4861, 345.3439)},
    {portal = "HuecoMundo", pos = CFrame.new(-369.4567, -0.1593, 1092.5155)},
    {portal = "Shinjuku", pos = CFrame.new(-17.3715, 1.8984, -1842.6716)},
    {portal = "Shinjuku", pos = CFrame.new(666.2935, 1.8831, -1692.1214)},
    {portal = "Slime", pos = CFrame.new(-1123.8552, 13.9182, 368.3176)},
    {portal = "Academy", pos = CFrame.new(1068.3764, 1.7783, 1277.8568)},
    {portal = "Judgement", pos = CFrame.new(-1270.6287, 1.1774, -1192.4418)},
    {portal = "Ninja", pos = CFrame.new(-1878.8419, 8.5140, -739.5654)},
    {portal = "Lawless", pos = CFrame.new(52.5574, 0.5787, 1815.9211)},
    {portal = "Tower", pos = CFrame.new(-1270.6287, 1.1774, -1192.4418)}
}

-------------------------------------------------
-- ☢️ OPTIMIZED NUKE MAP SYSTEM 
-------------------------------------------------
local PlatformFolder = workspace:FindFirstChild("FarmPlatforms") or Instance.new("Folder", workspace)
PlatformFolder.Name = "FarmPlatforms"

for _, area in ipairs(FarmRoute) do
    local platform = Instance.new("Part")
    platform.Size = Vector3.new(200, 5, 200)
    platform.CFrame = area.pos * CFrame.new(0, -6, 0)
    platform.Anchored = true
    platform.Transparency = 1
    platform.CanCollide = true
    platform.Parent = PlatformFolder
end

local function SuperNuke(v)
    local char = player.Character
    if not v or v == char or v == PlatformFolder or v.Name == "FarmPlatforms" then return end
    if v:IsA("Camera") or v:IsA("Terrain") then return end
    if v:FindFirstChildOfClass("Humanoid") or v:IsA("Model") and v:FindFirstChildOfClass("Humanoid", true) then return end
    pcall(function() v:Destroy() end)
end

task.spawn(function()
    task.wait(3)
    local Terrain = workspace:FindFirstChildOfClass("Terrain")
    if Terrain then Terrain:Clear() end
    for _, v in pairs(workspace:GetChildren()) do SuperNuke(v) end
end)

workspace.ChildAdded:Connect(function(v)
    task.spawn(function() task.wait(0.1); SuperNuke(v) end)
end)

-------------------------------------------------
-- AUTO SYSTEMS
-------------------------------------------------
local function fasttp(cf)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for i = 1, 3 do hrp.CFrame = cf; task.wait() end
end

local function portal(name)
    pcall(function() PortalRemote:FireServer(name) end)
end

local function enableBuso()
    task.wait(1)
    pcall(function() HakiRemote:FireServer("Toggle") end)
end
if player.Character then enableBuso() end
player.CharacterAdded:Connect(enableBuso)

task.spawn(function()
    while task.wait(30) do
        if _G_AutoFarm then pcall(function() ObservationRemote:FireServer("Toggle") end) end
    end
end)

-- Auto Equip
task.spawn(function()
    local currentWeaponIndex = 1
    while task.wait(0.5) do 
        if not _G_AutoFarm then continue end
        local char = player.Character
        local backpack = player:FindFirstChild("Backpack")
        if char and backpack then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local weaponName = WEAPONS[currentWeaponIndex]
                local tool = backpack:FindFirstChild(weaponName)
                if tool then hum:EquipTool(tool) end
                currentWeaponIndex = currentWeaponIndex + 1
                if currentWeaponIndex > #WEAPONS then currentWeaponIndex = 1 end
            end
        end
    end
end)

-- 🌟 Auto Skill (วนลูปกดตาม Config)
task.spawn(function()
    while task.wait(0.25) do 
        if _G_AutoFarm then
            pcall(function()
                for _, key in ipairs(SKILLS) do
                    VirtualInputManager:SendKeyEvent(true, key, false, game)
                    task.wait()
                    VirtualInputManager:SendKeyEvent(false, key, false, game)
                    task.wait(0.05) -- หน่วงนิดนึงให้การกดแต่ละปุ่มแยกกันชัดเจน
                end
            end)
        end
    end
end)

-- Main Farm Loop
task.spawn(function()
    while true do
        if _G_AutoFarm then
            for _, area in ipairs(FarmRoute) do
                if not _G_AutoFarm then break end
                pcall(function() PortalRemote:FireServer(area.portal) end)
                task.wait(0.3)
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for i = 1, 3 do hrp.CFrame = area.pos; task.wait() end
                end
                task.wait(2.7)
            end
        else
            task.wait(1)
        end
    end
end)

-- Anti-RAM Leak
local LogService = game:GetService("LogService")
local ScriptContext = game:GetService("ScriptContext")
pcall(function()
    LogService.MessageOut:Connect(function() end)
    ScriptContext.Error:Connect(function() end)
end)
task.spawn(function()
    while task.wait(60) do collectgarbage("step", 200) end
end)
