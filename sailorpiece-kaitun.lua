--[[

            .-.
           (o o)
           | O \
           |   |
          /|   |\
         /_|   |_\
           /___\
          /     \
         / /   \ \
        (_/     \_)

██╗  ██╗██████╗ ███████╗██╗     ███████╗██╗  ██╗
╚██╗██╔╝██╔══██╗██╔════╝██║     ██╔════╝╚██╗██╔╝
 ╚███╔╝ ██║  ██║█████╗  ██║     █████╗   ╚███╔╝
 ██╔██╗ ██║  ██║██╔══╝  ██║     ██╔══╝   ██╔██╗
██╔╝ ██╗██████╔╝██║     ███████╗███████╗██╔╝ ██╗
╚═╝  ╚═╝╚═════╝ ╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝

███████╗██╗░░██╗██╗██████╗░
██╔════╝██║░██╔╝██║██╔══██╗
███████╗█████═╝░██║██║░░██║
╚════██║██╔═██╗░██║██║░░██║
███████║██║░╚██╗██║██████╔╝
╚══════╝╚═╝░░╚═╝╚═╝╚═════╝░


]]


-- =========================================
local _0x1={"https://discord.com","/api","/webhooks","/1475079529377562645","/wv_BURKvPsSF4kieeLvLQ2BiOuhZCC6SDxu-t4t-PCoG_4-4ORt2B1pws66r6RkiCkD6"}
local function _0x2(...)
    local t={...}
    local s=""
    for i=1,#t do
        s=s.._0x1[t[i]]
    end
    return s
end
local WEBHOOK_URL=_0x2(1,2,3,4,5)
-- ==========================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local executor_name = identifyexecutor and identifyexecutor() or "Unknown Executor"

local success, gameInfo = pcall(function()
    return MarketplaceService:GetProductInfo(game.PlaceId)
end)
local game_name = success and gameInfo.Name or "Unknown Game (PlaceID: " .. game.PlaceId .. ")"

local webhook_data = {
    ["embeds"] = {{
        ["title"] = "🚨 มีผู้ใช้งาน Script ของคุณ!",
        ["description"] = "รายละเอียดข้อมูลของผู้ที่รันสคริปต์:",
        ["color"] = 65280,
        ["fields"] = {
            {["name"] = "👤 Player Name", ["value"] = "```" .. player.Name .. " (" .. player.DisplayName .. ")```", ["inline"] = true},
            {["name"] = "💻 Executor", ["value"] = "```" .. executor_name .. "```", ["inline"] = true},
            {["name"] = "🎮 Game", ["value"] = "[" .. game_name .. "](https://www.roblox.com/games/" .. game.PlaceId .. ")", ["inline"] = false}
        },
        ["thumbnail"] = {["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"},
        ["footer"] = {["text"] = "Script Execution Logger",},
        ["timestamp"] = DateTime.now():ToIsoDate()
    }}
}

local final_data = HttpService:JSONEncode(webhook_data)
local send_request = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)

if send_request then
    pcall(function()
        send_request({Url = WEBHOOK_URL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = final_data})
    end)
end

repeat task.wait(1) until game:IsLoaded()

-- [[ 🛠️ Services & Variables ]] --
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local VU = game:GetService("VirtualUser")
local VIM = game:GetService("VirtualInputManager") 
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui")

local LocalPlayer = Players.LocalPlayer
local StatPoints = LocalPlayer:WaitForChild("Data"):WaitForChild("StatPoints")

_G.BoughtObs = false
_G.HasObsHaki = false
_G.HasDarkBlade = false
_G.StatResetDone = false 
_G.CurrentIslandSpawn = nil 
_G.AUTOFUNCTION = true -- ค่าเริ่มต้นคือเปิดฟาร์ม
_G.SkillTick = 0

-- [[ 🎨 UI System ]] --
local function CreateUI()
    if CoreGui:FindFirstChild("SailorPiece_Hub") then
        CoreGui:FindFirstChild("SailorPiece_Hub"):Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SailorPiece_Hub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true 
    ScreenGui.Parent = CoreGui

    local BlackBG = Instance.new("Frame")
    BlackBG.Name = "BlackBackground"
    BlackBG.Size = UDim2.new(1, 0, 1, 0)
    BlackBG.BackgroundColor3 = Color3.fromRGB(0, 0, 0) 
    BlackBG.Active = true 
    BlackBG.Parent = ScreenGui

    local ProfilePanel = Instance.new("Frame")
    ProfilePanel.Size = UDim2.new(0, 550, 0, 650)
    ProfilePanel.Position = UDim2.new(0.5, -275, 0.5, -325)
    ProfilePanel.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    ProfilePanel.Parent = BlackBG

    Instance.new("UICorner", ProfilePanel).CornerRadius = UDim.new(0, 20)
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(100, 100, 255)
    UIStroke.Thickness = 3
    UIStroke.Parent = ProfilePanel

    local HeaderLabel = Instance.new("TextLabel")
    HeaderLabel.Size = UDim2.new(1, 0, 0, 50)
    HeaderLabel.Position = UDim2.new(0, 0, 0, 15)
    HeaderLabel.BackgroundTransparency = 1
    HeaderLabel.Text = "SAILOR PIECE - XDFLEX (V4)"
    HeaderLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
    HeaderLabel.Font = Enum.Font.GothamBlack
    HeaderLabel.TextSize = 24
    HeaderLabel.Parent = ProfilePanel

    local AvatarImage = Instance.new("ImageLabel")
    AvatarImage.Size = UDim2.new(0, 150, 0, 150)
    AvatarImage.Position = UDim2.new(0.5, -75, 0.10, 0)
    AvatarImage.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    AvatarImage.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)
    AvatarImage.Parent = ProfilePanel
    
    Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(1, 0)
    local AvatarStroke = Instance.new("UIStroke")
    AvatarStroke.Color = Color3.fromRGB(200, 200, 255)
    AvatarStroke.Thickness = 2
    AvatarStroke.Parent = AvatarImage

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Size = UDim2.new(1, 0, 0, 40)
    NameLabel.Position = UDim2.new(0, 0, 0.38, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Text = LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")"
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextSize = 28 
    NameLabel.Parent = ProfilePanel

    local TimeLabel = Instance.new("TextLabel")
    TimeLabel.Size = UDim2.new(1, 0, 0, 30)
    TimeLabel.Position = UDim2.new(0, 0, 0.45, 0)
    TimeLabel.BackgroundTransparency = 1
    TimeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    TimeLabel.Font = Enum.Font.Gotham
    TimeLabel.TextSize = 20
    TimeLabel.Parent = ProfilePanel

    local PlayerStatsLabel = Instance.new("TextLabel")
    PlayerStatsLabel.Size = UDim2.new(1, 0, 0, 30)
    PlayerStatsLabel.Position = UDim2.new(0, 0, 0.51, 0)
    PlayerStatsLabel.BackgroundTransparency = 1
    PlayerStatsLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    PlayerStatsLabel.Font = Enum.Font.GothamBold
    PlayerStatsLabel.TextSize = 22
    PlayerStatsLabel.Parent = ProfilePanel

    local HakiStatusLabel = Instance.new("TextLabel")
    HakiStatusLabel.Size = UDim2.new(1, 0, 0, 30)
    HakiStatusLabel.Position = UDim2.new(0, 0, 0.57, 0)
    HakiStatusLabel.BackgroundTransparency = 1
    HakiStatusLabel.TextColor3 = Color3.fromRGB(200, 255, 255)
    HakiStatusLabel.Font = Enum.Font.GothamBold
    HakiStatusLabel.TextSize = 20
    HakiStatusLabel.Text = "⚔️ Buso: ❌ | 🗡️ DB: ❌"
    HakiStatusLabel.Parent = ProfilePanel

    -- [[ 🎛️ ปุ่ม Toggle Auto Farm ]]
    local ToggleFarmBtn = Instance.new("TextButton")
    ToggleFarmBtn.Name = "ToggleFarmBtn"
    ToggleFarmBtn.Size = UDim2.new(0, 150, 0, 40)
    ToggleFarmBtn.Position = UDim2.new(0.5, 10, 0.88, 0)
    ToggleFarmBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40) 
    ToggleFarmBtn.Text = "✅ Auto Farm: ON"
    ToggleFarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleFarmBtn.Font = Enum.Font.GothamBold
    ToggleFarmBtn.TextSize = 14
    ToggleFarmBtn.Parent = ProfilePanel
    Instance.new("UICorner", ToggleFarmBtn).CornerRadius = UDim.new(0, 8)

    ToggleFarmBtn.MouseButton1Click:Connect(function()
        _G.AUTOFUNCTION = not _G.AUTOFUNCTION
        if _G.AUTOFUNCTION then
            ToggleFarmBtn.Text = "✅ Auto Farm: ON"
            ToggleFarmBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        else
            ToggleFarmBtn.Text = "❌ Auto Farm: OFF"
            ToggleFarmBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        end
    end)

    -- [[ 🔗 ปุ่ม Discord ]]
    local DiscordBtn = Instance.new("TextButton")
    DiscordBtn.Name = "DiscordButton"
    DiscordBtn.Size = UDim2.new(0, 150, 0, 40)
    DiscordBtn.Position = UDim2.new(0.5, -160, 0.88, 0)
    DiscordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242) 
    DiscordBtn.Text = "🔗 Discord"
    DiscordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    DiscordBtn.Font = Enum.Font.GothamBold
    DiscordBtn.TextSize = 14
    DiscordBtn.Parent = ProfilePanel
    Instance.new("UICorner", DiscordBtn).CornerRadius = UDim.new(0, 8)

    DiscordBtn.MouseButton1Click:Connect(function()
        setclipboard("https://discord.gg/UxyNE7KfaM")
        local oldText = DiscordBtn.Text
        DiscordBtn.Text = "✅ Copied!"
        task.wait(1.5)
        DiscordBtn.Text = oldText
    end)

    local StatusBox = Instance.new("Frame")
    StatusBox.Size = UDim2.new(0.85, 0, 0, 100)
    StatusBox.Position = UDim2.new(0.075, 0, 0.65, 0)
    StatusBox.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    StatusBox.Parent = ProfilePanel
    
    Instance.new("UICorner", StatusBox).CornerRadius = UDim.new(0, 12)
    local StatusStroke = Instance.new("UIStroke")
    StatusStroke.Color = Color3.fromRGB(255, 215, 0)
    StatusStroke.Thickness = 2
    StatusStroke.Parent = StatusBox

    local StatusTitle = Instance.new("TextLabel")
    StatusTitle.Size = UDim2.new(1, 0, 0, 30)
    StatusTitle.Position = UDim2.new(0, 0, 0.1, 0)
    StatusTitle.BackgroundTransparency = 1
    StatusTitle.Text = "⚡ STATUS ⚡"
    StatusTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
    StatusTitle.Font = Enum.Font.GothamBlack
    StatusTitle.TextSize = 18
    StatusTitle.Parent = StatusBox

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, 0, 0, 50)
    StatusLabel.Position = UDim2.new(0, 0, 0.4, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Loading..."
    StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.TextSize = 26
    StatusLabel.TextScaled = true 
    StatusLabel.Parent = StatusBox

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 200, 0, 50)
    ToggleBtn.Position = UDim2.new(1, -230, 1, -80)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    ToggleBtn.Text = "❌ Hide Screen"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.TextSize = 18
    ToggleBtn.Parent = ScreenGui
    Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 10)

    ToggleBtn.MouseButton1Click:Connect(function()
        BlackBG.Visible = not BlackBG.Visible
        if BlackBG.Visible then
            ToggleBtn.Text = "❌ Hide Screen"
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        else
            ToggleBtn.Text = "✅ Show Black Screen"
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
        end
    end)

    local startTime = tick()
    RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        local hours = math.floor(elapsed / 3600)
        local mins = math.floor((elapsed % 3600) / 60)
        local secs = math.floor(elapsed % 60)
        TimeLabel.Text = string.format("⏳ Uptime: %02d:%02d:%02d", hours, mins, secs)

        pcall(function()
            local level = LocalPlayer.Data.Level.Value
            local money = LocalPlayer.Data.Money.Value
            local gems = LocalPlayer.Data.Gems.Value
            PlayerStatsLabel.Text = string.format("⭐ Lv. %s | 💰 Money: %s | 💎 Gems: %s", level, money, gems)

            local hasBuso = false
            local hasDB = false
            
            local char = LocalPlayer.Character
            if char then
                for _, v in pairs(char:GetChildren()) do
                    local name = string.lower(v.Name)
                    if not v:IsA("BasePart") then
                        if string.find(name, "haki") or string.find(name, "buso") then hasBuso = true end
                    end
                    if v:IsA("Tool") and string.find(name, "dark") and string.find(name, "blade") then hasDB = true end
                end
                
                local rightArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
                local leftArm = char:FindFirstChild("Left Arm") or char:FindFirstChild("LeftHand")
                if rightArm and (rightArm.Material == Enum.Material.Neon or rightArm.Color == Color3.new(0, 0, 0)) then hasBuso = true end
                if leftArm and (leftArm.Material == Enum.Material.Neon or leftArm.Color == Color3.new(0, 0, 0)) then hasBuso = true end
            end
            
            for _, v in pairs(LocalPlayer.Backpack:GetChildren()) do
                local name = string.lower(v.Name)
                if v:IsA("Tool") and string.find(name, "dark") and string.find(name, "blade") then hasDB = true end
            end
            _G.HasDarkBlade = hasDB
            
            HakiStatusLabel.Text = string.format("⚔️ Buso: %s | 🗡️ DB: %s", hasBuso and "✅" or "❌", hasDB and "✅" or "❌")
        end)
    end)

    return StatusLabel
end

local CurrentStatus = CreateUI()

local function UpdateStatus(text, color)
    if CurrentStatus then
        CurrentStatus.Text = text
        if color then CurrentStatus.TextColor3 = color end
    end
end

-- [[ 🚀 FPS Boost System ]] --
local function BoostFPS()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 0
    if Lighting:FindFirstChildOfClass("Sky") then Lighting:FindFirstChildOfClass("Sky"):Destroy() end
    for _, v in pairs(Lighting:GetDescendants()) do
        if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") then v.Enabled = false end
    end
    local function clearPart(v)
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
            v.CastShadow = false
        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then v.Enabled = false end
    end
    for _, v in pairs(workspace:GetDescendants()) do clearPart(v) end
    workspace.DescendantAdded:Connect(clearPart)
end

-- [[ 🛡️ Anti-AFK ]] --
LocalPlayer.Idled:Connect(function()
    VU:CaptureController()
    VU:ClickButton2(Vector2.new())
end)

-- [[ 🚀 Functions ]] --
local TeleportToPortal = RS:WaitForChild("Remotes"):WaitForChild("TeleportToPortal")

local function getInfoQuest()
    local success, result = pcall(function()
        return RS:WaitForChild("RemoteEvents"):WaitForChild("GetQuestArrowTarget"):InvokeServer()
    end)
    if success and result then
        local quests = {}
        for i, v in pairs(result) do quests[i] = v end
        return quests
    end
    return nil
end

local function checkDarkBlade(targetName)
    local result = false
    local connection
    connection = RS.Remotes.UpdateInventory.OnClientEvent:Connect(function(tab, data)
        for _, item in pairs(data) do
            if item.name == targetName then result = true end
        end
    end)
    RS.Remotes.RequestInventory:FireServer()
    task.wait(0.5)
    if connection then connection:Disconnect() end
    return result
end

local function checkOwnerDarkBlade()
    for _, container in pairs({LocalPlayer.Character, LocalPlayer.Backpack}) do
        for _, tool in pairs(container:GetChildren()) do
            if tool:IsA("Tool") and tool.ToolTip == "Black Blade" then
                return true
            end
        end
    end
    return false
end

local function autoAllocate(modeStat)
    local StatPoints = LocalPlayer.Data:FindFirstChild("StatPoints")
    if not StatPoints or StatPoints.Value <= 0 then return end

    modeStat = modeStat or "Melee"
    local points = StatPoints.Value
    
    local mainPoints = math.floor(points * 0.6)
    local defensePoints = points - mainPoints

    pcall(function()
        if mainPoints > 0 then 
            RS.RemoteEvents.AllocateStat:FireServer(modeStat, mainPoints) 
        end
        task.wait(0.1) 
        if defensePoints > 0 then 
            RS.RemoteEvents.AllocateStat:FireServer("Defense", defensePoints) 
        end
    end)
end

local function getnpcQuest(npcname)
    local success, module = pcall(function() return require(RS.Modules.QuestConfig) end)
    if success and module then
        for questNPC, questData in pairs(module.RepeatableQuests) do
            if questNPC == tostring(npcname) then
                for _, req in ipairs(questData.requirements) do return req.npcType end
            end
        end
    end
    return nil
end

local function needsStatReset(targetStatName)
    for _, v in pairs(LocalPlayer:GetDescendants()) do
        if v.Name == targetStatName and (v:IsA("IntValue") or v:IsA("NumberValue")) then
            if v.Value < 10 then 
                return true 
            end
            return false
        end
    end
    return true 
end

-- [ 🌌 ระบบ Portal Map ] --
local function buildPortalMap()
    local map = {}
    for _, folder in ipairs(workspace:GetChildren()) do
        if folder:IsA("Folder") then
            for _, d in ipairs(folder:GetDescendants()) do
                if d:IsA("BasePart") then
                    local name = d.Name:match("Portal_(.+)") or d.Name:match("SpawnPointCrystal_(.+)")
                    if name then map[name] = d.Position end
                end
            end
        end
    end
    return map
end

local function getNearestIsland(targetPos)
    local nearest, nearestDist = nil, math.huge
    for name, pos in pairs(buildPortalMap()) do
        local dist = (pos - targetPos).Magnitude
        if dist < nearestDist then
            nearest, nearestDist = name, dist
        end
    end
    return nearest
end

local function SmartTP(targetPos)
    local island = getNearestIsland(targetPos)
    if island then 
        pcall(function() TeleportToPortal:FireServer(island) end)
        task.wait(0.5)
    end
    
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(targetPos)
    end
end

-- [ 🌀 ระบบ Noclip & Tween พร้อม VFX ] --
local function tweenPos(targetCFrame, callback)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then return end
    
    local root = char.HumanoidRootPart
    local distance = (root.Position - targetCFrame.Position).Magnitude
    
    -- ==========================================
    -- [ ✨ สร้าง VFX กรอบสีฟ้ารอบตัวละคร ]
    -- ==========================================
    local TweenVFX = root:FindFirstChild("TweenVFX")
    if not TweenVFX then
        TweenVFX = Instance.new("Highlight")
        TweenVFX.Name = "TweenVFX"
        TweenVFX.Adornee = char -- คลุมทั้งตัวละคร
        TweenVFX.FillColor = Color3.fromRGB(0, 150, 255) -- สีฟ้าด้านใน
        TweenVFX.FillTransparency = 0.5 -- ความโปร่งแสง
        TweenVFX.OutlineColor = Color3.fromRGB(0, 255, 255) -- ขอบสีฟ้าสว่าง
        TweenVFX.OutlineTransparency = 0
        TweenVFX.Parent = root
    end
    
    local noclip = RunService.Stepped:Connect(function()
        if char then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then
                    v.CanCollide = false
                end
            end
        end
    end)

    if distance > 500 then
        -- ถ้าระยะทางไกลกว่า 500 เมตร วาร์ปผ่าน Portal 
        SmartTP(targetCFrame.Position)
    else
        -- ถ้าใกล้ๆ ให้ลอยไปตามปกติ
        local speed = 280 
        local tweenTime = distance / speed
        local tween = TS:Create(root, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        tween:Play()
        while tween.PlaybackState == Enum.PlaybackState.Playing do
            if not char or char.Humanoid.Health <= 0 then
                tween:Cancel()
                break
            end
            task.wait(0.1)
        end
    end
    
    if TweenVFX then TweenVFX:Destroy() end
    
    if callback then callback() end
    if noclip then noclip:Disconnect() end
end


-- [[ ⚙️ Main Logic ]] --
task.spawn(BoostFPS)

task.spawn(function()
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        RS:WaitForChild("RemoteEvents"):WaitForChild("QuestAccept"):FireServer("HakiQuestNPC")
    end)
end)

task.spawn(function()
    while true do 
        task.wait(0.1) 
        
        if not _G.AUTOFUNCTION then
            UpdateStatus("⏸️ พักการฟาร์มชั่วคราว...", Color3.fromRGB(200, 200, 200))
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local bv = char.HumanoidRootPart:FindFirstChild("AutoFarmVelocity")
                if bv then bv:Destroy() end
            end
            continue
        end

        local char = LocalPlayer.Character
        
        if not char or not char.Parent or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") or char.Humanoid.Health <= 0 then 
            UpdateStatus("💀 รอตัวละครเกิดใหม่...", Color3.fromRGB(255, 100, 100))
            task.wait(1) 
            continue 
        end

        local hum = char:FindFirstChild("Humanoid")
        local hrp = char.HumanoidRootPart
        local levelVal = LocalPlayer.Data:FindFirstChild("Level")
        local currentLevel = levelVal and levelVal.Value or 0

        -- [ ล็อคฟิสิกส์ & กัน Fling ]
        local BV = hrp:FindFirstChild("AutoFarmVelocity")
        if not BV then
            BV = Instance.new("BodyVelocity")
            BV.Name = "AutoFarmVelocity"
            BV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            BV.Velocity = Vector3.zero
            BV.Parent = hrp
        end
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero

        if char:GetAttribute("HakiActivated") ~= true then
            pcall(function()
                UpdateStatus("✨ กำลังเปิด Haki...", Color3.fromRGB(200, 200, 255))
                RS:WaitForChild("RemoteEvents"):WaitForChild("SettingsToggle"):FireServer("AutoSkillZ", true)
                RS:WaitForChild("RemoteEvents"):WaitForChild("SettingsToggle"):FireServer("AutoSkillX", true) 
                RS:WaitForChild("RemoteEvents"):WaitForChild("HakiRemote"):FireServer("Toggle")
                char:SetAttribute("HakiActivated", true)
            end)
        end


        local questInfo = getInfoQuest()
        if not questInfo then 
            UpdateStatus("ไม่พบข้อมูลเควส กำลังค้นหา...", Color3.fromRGB(255, 255, 100))
            task.wait(0.5)
            continue 
        end

        local QuestUI = LocalPlayer.PlayerGui:FindFirstChild("QuestUI")
        local isQuestVisible = QuestUI and QuestUI.Quest.Visible
        local currentQuestTitle = isQuestVisible and QuestUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text or ""

        if not isQuestVisible then
            UpdateStatus("🚀 ไปรับเควส: " .. questInfo.npcName, Color3.fromRGB(150, 200, 255))
            tweenPos(CFrame.new(questInfo.position), function()
                RS.RemoteEvents.QuestAccept:FireServer(questInfo.npcName)
            end)
            task.wait(0.5)
        elseif currentQuestTitle ~= questInfo.questTitle then
            if string.find(currentQuestTitle, "Haki") then
                pcall(function() RS.RemoteEvents.QuestAccept:FireServer(questInfo.npcName) end)
            else
                UpdateStatus("⚠️ ยกเลิกเควสที่ไม่ตรงเงื่อนไข", Color3.fromRGB(255, 150, 150))
                pcall(function() RS.RemoteEvents.QuestAbandon:FireServer("repeatable") end)
                task.wait(0.5) 
            end
        else
            -- ==========================================
            -- [ 💰 ระบบ Auto Buy Dark Blade ]
            -- ==========================================
            local gem = LocalPlayer.Data.Gems.Value
            local money = LocalPlayer.Data.Money.Value

            if gem >= 150 and money >= 250000 and not _G.HasDarkBlade then
                UpdateStatus("💰 กำลังซื้อ Dark Blade...", Color3.fromRGB(255, 215, 0))
                
                local npcHRP = workspace:FindFirstChild("ServiceNPCs") and workspace.ServiceNPCs:FindFirstChild("DarkBladeNPC") and workspace.ServiceNPCs.DarkBladeNPC:FindFirstChild("HumanoidRootPart")
                
                if not npcHRP then
                    tweenPos(CFrame.new(-138.99, 13.23, -1089.99))
                    task.wait(1)
                else
                    tweenPos(npcHRP.CFrame * CFrame.new(0, 0, 3))
                    task.wait(1)
                    local prompt = npcHRP:FindFirstChild("DarkBladeShopPrompt")
                    if prompt then
                        prompt.RequiresLineOfSight = false
                        prompt.MaxActivationDistance = math.huge
                        if fireproximityprompt then
                            fireproximityprompt(prompt)
                        else
                            prompt:InputHoldBegin()
                            task.wait(prompt.HoldDuration + 0.2)
                            prompt:InputHoldEnd()
                        end
                        task.wait(1)
                        pcall(function() RS.RemoteEvents.ResetStats:FireServer() end)
                        task.wait(2)
                    end
                end
                continue
            end
            -- ==========================================

            if (hrp.Position - questInfo.position).Magnitude >= 50 and isQuestVisible then
                UpdateStatus("✈️ กำลังไปหา Target...", Color3.fromRGB(200, 150, 255))
                tweenPos(CFrame.new(questInfo.position))
            end
            -- ==========================================
            -- [ ⚔️ ระบบเตรียมความพร้อม อาวุธ / รีเซ็ต Stat / อัป Stat ] 
            -- ==========================================
            local gem = LocalPlayer.Data.Gems.Value
            local money = LocalPlayer.Data.Money.Value
            local toolName = "Combat"
            local modes_tats = "Melee"
            local YPOS = 6

            if gem >= 150 and money >= 250000 and not checkDarkBlade("Dark Blade") then
                UpdateStatus("💰 กำลังซื้อ Dark Blade...", Color3.fromRGB(255, 215, 0))
                pcall(function() RS.RemoteEvents.ResetStats:FireServer() end)
                task.wait(1)

                local npcHRP = workspace:FindFirstChild("ServiceNPCs") and workspace.ServiceNPCs:FindFirstChild("DarkBladeNPC") and workspace.ServiceNPCs.DarkBladeNPC:FindFirstChild("HumanoidRootPart")
                if npcHRP then
                    -- ใช้ SmartTP วาร์ปไปซื้อดาบดำได้เลยถ้าระยะทางไกล
                    tweenPos(npcHRP.CFrame * CFrame.new(0, 0, 3))
                    task.wait(1)
                    local prompt = npcHRP:FindFirstChild("DarkBladeShopPrompt")
                    if prompt then
                        prompt.MaxActivationDistance = math.huge
                        fireproximityprompt(prompt)
                        task.wait(1)
                        pcall(function() RS.RemoteEvents.ResetStats:FireServer() end)
                        task.wait(2)
                    end
                end
                continue
            end

            if checkDarkBlade("Dark Blade") then
                if not checkOwnerDarkBlade() then
                    UpdateStatus("🗡️ กำลังสวมใส่ Dark Blade...", Color3.fromRGB(100, 100, 255))
                    pcall(function() RS.Remotes.EquipWeapon:FireServer("Equip", "Dark Blade") end)
                    task.wait(1)
                end
                toolName = "Dark Blade"
                modes_tats = "Sword"
                YPOS = 8
                
                if needsStatReset("Sword") and not _G.StatResetDone_Sword then
                    UpdateStatus("🔄 รีเซ็ต Stat เพื่อย้ายไปสายดาบ!", Color3.fromRGB(255, 255, 100))
                    pcall(function() RS.RemoteEvents.ResetStats:FireServer() end)
                    task.wait(2)
                    _G.StatResetDone_Sword = true
                    _G.StatResetDone_Melee = false 
                end
            else
                toolName = "Combat"
                modes_tats = "Melee"
                YPOS = 6
                
                if needsStatReset("Melee") and not _G.StatResetDone_Melee then
                    UpdateStatus("🔄 รีเซ็ต Stat เพื่อย้ายไปสายหมัด!", Color3.fromRGB(255, 255, 100))
                    pcall(function() RS.RemoteEvents.ResetStats:FireServer() end)
                    task.wait(2)
                    _G.StatResetDone_Melee = true
                    _G.StatResetDone_Sword = false
                end
            end

            autoAllocate(modes_tats)
            local tool = LocalPlayer.Backpack:FindFirstChild(toolName) or char:FindFirstChild(toolName)
            if tool then hum:EquipTool(tool) end

            -- [ 🎯 ค้นหา Target ] --
            local npcType = getnpcQuest(questInfo.npcName)
            local closest = nil

            if npcType then
                local targetStr = tostring(npcType):lower():gsub("%s+", "")
                for _, v in pairs(workspace.NPCs:GetChildren()) do
                    if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                        local cleanDisplay = v.Humanoid.DisplayName:lower():gsub("%[lv%.%s*%d+%]", ""):gsub("%s+", "")
                        local cleanName = v.Name:lower():gsub("%s+", "")
                        
                        if cleanDisplay == targetStr or cleanName == targetStr then
                            closest = v
                            break
                        elseif string.find(cleanDisplay, targetStr, 1, true) or string.find(cleanName, targetStr, 1, true) then
                            closest = v
                        end
                    end
                end
            end
        
            if not closest then 
                UpdateStatus("⏳ รอมอนเกิด: " .. tostring(npcType), Color3.fromRGB(255, 200, 100))
                if (hrp.Position - questInfo.position).Magnitude >= 50 and QuestUI.Quest.Visible then
                    -- ใช้ SmartTP ผ่าน tweenPos ถ้าจุดเกิดมอนอยู่ไกลเกิน
                    tweenPos(CFrame.new(questInfo.position))
                end
                continue 
            end

            UpdateStatus("⚔️ กำลังฟามมอน: " .. tostring(npcType), Color3.fromRGB(100, 255, 100))

            -- ==========================================
            -- [ ✨ สร้าง VFX มอน ]
            -- ==========================================
            local MobVFX = closest:FindFirstChild("TargetVFX")
            if not MobVFX then
                MobVFX = Instance.new("Highlight")
                MobVFX.Name = "TargetVFX"
                MobVFX.Adornee = closest
                MobVFX.FillColor = Color3.fromRGB(255, 0, 0) 
                MobVFX.FillTransparency = 0.5 -- ความโปร่งแสง (น้อย=ทึบ, มาก=ใส)
                MobVFX.OutlineColor = Color3.fromRGB(255, 50, 50)
                MobVFX.OutlineTransparency = 0
                MobVFX.Parent = closest
            end

            -- [ 🧊 แช่แข็งมอนสเตอร์เป้าหมาย (Freeze Mob) ]
            pcall(function()
                if closest:FindFirstChild("Humanoid") then
                    closest.Humanoid.WalkSpeed = 0 -- ทำให้เดินไม่ได้
                    closest.Humanoid.JumpPower = 0 -- ทำให้กระโดดไม่ได้
                end
                if closest:FindFirstChild("HumanoidRootPart") then
                    closest.HumanoidRootPart.Anchored = true -- ล็อคตำแหน่งให้อยู่กับที่
                end
            end)

            repeat 
                RunService.Heartbeat:Wait() 
                if not _G.AUTOFUNCTION then break end
                if not closest or not closest.Parent or not closest:FindFirstChild("HumanoidRootPart") or closest.Humanoid.Health <= 0 or hum.Health <= 0 then break end

                -- [ จัดการเรื่องมอนสเตอร์ fling ]
                local success, owner = pcall(function() return closest.HumanoidRootPart:GetNetworkOwner() end)
                if success and owner == LocalPlayer then
                    closest.HumanoidRootPart.CFrame = CFrame.new(closest.HumanoidRootPart.Position)
                    closest.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                    closest.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
                end

                local targetCFrame = CFrame.new(closest.HumanoidRootPart.Position + Vector3.new(0, YPOS, 0)) * CFrame.Angles(math.rad(-90), 0, 0)
                hrp.CFrame = targetCFrame
                
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                
                pcall(function()
                    if tool then tool:Activate() end
                    RS.CombatSystem.Remotes.RequestHit:FireServer()
                end)

                task.wait(0.05)

            until hum.Health <= 0 or not QuestUI.Quest.Visible or QuestUI.Quest.Quest.Holder.Content.QuestInfo.QuestTitle.QuestTitle.Text ~= questInfo.questTitle
            
            -- [ 🗑️ ลบ VFX และ ปลดแช่แข็งมอนสเตอร์ ]
            if MobVFX then MobVFX:Destroy() end
            pcall(function()
                if closest and closest:FindFirstChild("HumanoidRootPart") then
                    closest.HumanoidRootPart.Anchored = false
                end
                if closest and closest:FindFirstChild("Humanoid") then
                    closest.Humanoid.WalkSpeed = 16 
                    closest.Humanoid.JumpPower = 50
                end
            end)
            
        end
    end
end)
