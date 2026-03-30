--[[ 
    DEBUG MODE: ถ้าค้างให้กด F9 ดูใน Console ว่าติดที่ตรงไหน
]]
print("--- Starting Sailor Script ---")

repeat task.wait() until game:IsLoaded()
print("Game Loaded!")

-------------------------------------------------
-- SERVICES & SAFETY WAIT
-------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- ใช้ Timeout 10 วินาที เพื่อไม่ให้สคริปต์ค้างตายถ้าหา Remote ไม่เจอ
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

if not RemoteEvents or not Remotes then
    warn("!!! Error: ไม่พบ RemoteEvents หรือ Remotes ใน ReplicatedStorage !!!")
    return
end
print("Remotes Found!")

local EquipRemote = Remotes:WaitForChild("EquipWeapon", 5)
local PortalRemote = Remotes:WaitForChild("TeleportToPortal", 5)
local HakiRemote = RemoteEvents:WaitForChild("HakiRemote", 5)
local ObservationRemote = RemoteEvents:WaitForChild("ObservationHakiRemote", 5)
local SettingsToggle = RemoteEvents:WaitForChild("SettingsToggle", 5)

-------------------------------------------------
-- GLOBAL TOGGLES
-------------------------------------------------
local _G_AutoFarm = true
local _G_WhiteScreen = true

-------------------------------------------------
-- GUI SYSTEM
-------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FarmControlGUI"
ScreenGui.ResetOnSpawn = false 
ScreenGui.DisplayOrder = 999 

pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = player:WaitForChild("PlayerGui")
end

local WhiteScreenFrame = Instance.new("Frame")
WhiteScreenFrame.Size = UDim2.new(1.1, 0, 1.1, 0)
WhiteScreenFrame.Position = UDim2.new(-0.05, 0, -0.05, 0) 
WhiteScreenFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
WhiteScreenFrame.ZIndex = 1 
WhiteScreenFrame.Visible = _G_WhiteScreen 
WhiteScreenFrame.Parent = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 120)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -60)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.Active = true
MainFrame.ZIndex = 2 
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "Farm Controller"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.ZIndex = 3 
Title.Parent = MainFrame

local FarmBtn = Instance.new("TextButton")
FarmBtn.Size = UDim2.new(0.9, 0, 0, 35)
FarmBtn.Position = UDim2.new(0.05, 0, 0, 35)
FarmBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
FarmBtn.Text = "Auto Farm: ON"
FarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FarmBtn.ZIndex = 3 
FarmBtn.Parent = MainFrame
Instance.new("UICorner", FarmBtn).CornerRadius = UDim.new(0, 6)

local WhiteScreenBtn = Instance.new("TextButton")
WhiteScreenBtn.Size = UDim2.new(0.9, 0, 0, 35)
WhiteScreenBtn.Position = UDim2.new(0.05, 0, 0, 75)
WhiteScreenBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
WhiteScreenBtn.Text = "White Screen: ON"
WhiteScreenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
WhiteScreenBtn.ZIndex = 3 
WhiteScreenBtn.Parent = MainFrame
Instance.new("UICorner", WhiteScreenBtn).CornerRadius = UDim.new(0, 6)

-- Initial White Screen State
if _G_WhiteScreen then
    pcall(function() RunService:Set3dRenderingEnabled(false) end)
end

-------------------------------------------------
-- INTERACTION & DRAG
-------------------------------------------------
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
    FarmBtn.BackgroundColor3 = _G_AutoFarm and Color3.fromRGB(40, 200, 40) or Color3.fromRGB(200, 40, 40)
    FarmBtn.Text = _G_AutoFarm and "Auto Farm: ON" or "Auto Farm: OFF"
end)

WhiteScreenBtn.MouseButton1Click:Connect(function()
    _G_WhiteScreen = not _G_WhiteScreen
    WhiteScreenBtn.BackgroundColor3 = _G_WhiteScreen and Color3.fromRGB(40, 200, 40) or Color3.fromRGB(200, 40, 40)
    WhiteScreenBtn.Text = _G_WhiteScreen and "White Screen: ON" or "White Screen: OFF"
    WhiteScreenFrame.Visible = _G_WhiteScreen
    pcall(function() RunService:Set3dRenderingEnabled(not _G_WhiteScreen) end)
end)

-------------------------------------------------
-- AUTO SETTINGS
-------------------------------------------------
pcall(function()
    local settingsToToggle = {"DisableCutscene", "DisableVFX", "MuteSFX", "MuteMusic", "DisableScreenShake", "RemoveTexture", "RemoveShadows"}
    for _, name in ipairs(settingsToToggle) do
        SettingsToggle:FireServer(name, true)
        task.wait(0.1)
    end
end)
print("Game Settings Applied!")

-------------------------------------------------
-- MAIN FARM ROUTE
-------------------------------------------------
local FarmRoute = {
    {portal = "Shibuya", pos = CFrame.new(1400.0594, 8.4861, 484.9847)},
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
-- OPTIMIZED NUKE MAP SYSTEM
-------------------------------------------------
local PlatformFolder = workspace:FindFirstChild("FarmPlatforms") or Instance.new("Folder", workspace)
PlatformFolder.Name = "FarmPlatforms"

-- สร้างพื้นล่องหน
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
    
    -- ข้ามมอนสเตอร์และคนอื่น
    if v:FindFirstChildOfClass("Humanoid") then return end

    pcall(function() v:Destroy() end)
end

-- ลบครั้งแรก
task.spawn(function()
    task.wait(3)
    local Terrain = workspace:FindFirstChildOfClass("Terrain")
    if Terrain then Terrain:Clear() end
    for _, v in pairs(workspace:GetChildren()) do
        SuperNuke(v)
    end
    print("Initial Map Deletion Done!")
end)

-- ดักลบสิ่งที่จะเกิดใหม่
workspace.ChildAdded:Connect(function(v)
    task.spawn(function()
        task.wait(0.1)
        SuperNuke(v)
    end)
end)

-------------------------------------------------
-- AUTO SYSTEMS
-------------------------------------------------
local WEAPONS = {"Soul Reaper", "Strongest In History"}

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

-- Auto Skill (0.25s)
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

-- Main Farm Loop
task.spawn(function()
    while true do
        if _G_AutoFarm then
            for _, area in ipairs(FarmRoute) do
                if not _G_AutoFarm then break end
                portal(area.portal)
                task.wait(0.6)
                fasttp(area.pos)
                task.wait(3)
            end
        else
            task.wait(1)
        end
    end
end)

print("--- Sailor Script fully loaded! ---")
