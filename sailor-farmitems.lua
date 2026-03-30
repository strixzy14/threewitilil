repeat task.wait() until game:IsLoaded()

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
-- GLOBAL TOGGLES & CONFIG (เพิ่มระบบตั้งค่าอาวุธ)
-------------------------------------------------
local _G_AutoFarm = true
if getgenv().AutoFarm ~= nil then 
    _G_AutoFarm = getgenv().AutoFarm 
end

local _G_WhiteScreen = true
if getgenv().WhiteScreen ~= nil then 
    _G_WhiteScreen = getgenv().WhiteScreen 
end

-- ตั้งค่าอาวุธ: ถ้ามีใน getgenv ให้ใช้ตามนั้น ถ้าไม่มีให้ใช้ค่า Default
local WEAPONS = {"Soul Reaper", "Strongest In History"} 
if getgenv().Weapons ~= nil and type(getgenv().Weapons) == "table" then
    WEAPONS = getgenv().Weapons
end

-------------------------------------------------
-- 💎 ULTRA MINIMAL GUI (ดีไซน์แคปซูล ไม่มีขอบดำ)
-------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "XDFlex_CompactUI"
ScreenGui.ResetOnSpawn = false 
ScreenGui.DisplayOrder = 9999
ScreenGui.IgnoreGuiInset = true -- 🌟 โค้ดนี้คือตัวแก้ปัญหา "ขอบดำ" (บังมิดทั้งจอ 100%)

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = player:WaitForChild("PlayerGui") end

-- เฟรมจอขาว (ตอนนี้จะบังเนียน 100% ไม่มีขอบ)
local WhiteScreenFrame = Instance.new("Frame")
WhiteScreenFrame.Size = UDim2.new(1, 0, 1, 0)
WhiteScreenFrame.Position = UDim2.new(0, 0, 0, 0) 
WhiteScreenFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
WhiteScreenFrame.BorderSizePixel = 0
WhiteScreenFrame.ZIndex = 1 
WhiteScreenFrame.Visible = _G_WhiteScreen 
WhiteScreenFrame.Parent = ScreenGui

-- กล่องรวมปุ่มแบบแคปซูล (Pill Design) เล็ก กระทัดรัด
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 45)
MainFrame.Position = UDim2.new(0.5, -125, 0, 20) -- ลอยอยู่ตรงกลางด้านบน
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.3 -- โปร่งแสงนิดๆ ให้ดูหรู
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ZIndex = 2 
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(1, 0) -- ขอบมนแบบแคปซูล

-- จัดเรียงปุ่มซ้ายขวาอัตโนมัติ
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Horizontal
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = MainFrame

-- ปุ่ม Auto Farm
local FarmBtn = Instance.new("TextButton")
FarmBtn.Size = UDim2.new(0, 105, 0, 32)
FarmBtn.BackgroundColor3 = _G_AutoFarm and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
FarmBtn.Text = _G_AutoFarm and "⚔️ Farm: ON" or "⚔️ Farm: OFF"
FarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FarmBtn.Font = Enum.Font.GothamBold
FarmBtn.TextSize = 12
FarmBtn.ZIndex = 3 
FarmBtn.Parent = MainFrame
Instance.new("UICorner", FarmBtn).CornerRadius = UDim.new(1, 0)

-- ปุ่ม White Screen
local WhiteScreenBtn = Instance.new("TextButton")
WhiteScreenBtn.Size = UDim2.new(0, 105, 0, 32)
WhiteScreenBtn.BackgroundColor3 = _G_WhiteScreen and Color3.fromRGB(236, 240, 241) or Color3.fromRGB(52, 73, 94)
WhiteScreenBtn.Text = _G_WhiteScreen and "⚪ Screen: ON" or "⚫ Screen: OFF"
WhiteScreenBtn.TextColor3 = _G_WhiteScreen and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
WhiteScreenBtn.Font = Enum.Font.GothamBold
WhiteScreenBtn.TextSize = 12
WhiteScreenBtn.ZIndex = 3 
WhiteScreenBtn.Parent = MainFrame
Instance.new("UICorner", WhiteScreenBtn).CornerRadius = UDim.new(1, 0)

-- อ่านค่า Config เพื่อเปิด/ปิด 3D
if _G_WhiteScreen then 
    pcall(function() RunService:Set3dRenderingEnabled(false) end) 
else
    pcall(function() RunService:Set3dRenderingEnabled(true) end) 
end

-- ระบบลาก GUI (ลากตรงช่องว่างระหว่างปุ่มได้เลย)
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
    FarmBtn.Text = _G_AutoFarm and "⚔️ Farm: ON" or "⚔️ Farm: OFF"
end)

WhiteScreenBtn.MouseButton1Click:Connect(function()
    _G_WhiteScreen = not _G_WhiteScreen
    WhiteScreenBtn.BackgroundColor3 = _G_WhiteScreen and Color3.fromRGB(236, 240, 241) or Color3.fromRGB(52, 73, 94)
    WhiteScreenBtn.Text = _G_WhiteScreen and "⚪ Screen: ON" or "⚫ Screen: OFF"
    WhiteScreenBtn.TextColor3 = _G_WhiteScreen and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
    WhiteScreenFrame.Visible = _G_WhiteScreen
    pcall(function() RunService:Set3dRenderingEnabled(not _G_WhiteScreen) end)
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
    {portal = "Shibuya", pos = CFrame.new(1563.0409, 72.7205, -31.2679)},
    {portal = "Shibuya", pos = CFrame.new(1854.0795, 8.4861, 342.6972)},
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

-- Auto Equip (0.5s)
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

-- Auto Skill X (0.25s)
task.spawn(function()
    while task.wait(0.25) do 
        if _G_AutoFarm then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, "X", false, game)
                task.wait()
                VirtualInputManager:SendKeyEvent(false, "X", false, game)
            end)
        end
    end
end)

-- Main Farm Loop (0.6s Portal / 3s Farm)
task.spawn(function()
    while true do
        if _G_AutoFarm then
            for _, area in ipairs(FarmRoute) do
                if not _G_AutoFarm then break end
                pcall(function() PortalRemote:FireServer(area.portal) end)
                task.wait(0.6)
                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for i = 1, 3 do hrp.CFrame = area.pos; task.wait() end
                end
                task.wait(3)
            end
        else
            task.wait(1)
        end
    end
end)

-- Anti-RAM Leak (ล้าง Log ป้องกันกระตุก)
local LogService = game:GetService("LogService")
local ScriptContext = game:GetService("ScriptContext")
pcall(function()
    LogService.MessageOut:Connect(function() end)
    ScriptContext.Error:Connect(function() end)
end)
task.spawn(function()
    while task.wait(60) do collectgarbage("step", 200) end
end)
