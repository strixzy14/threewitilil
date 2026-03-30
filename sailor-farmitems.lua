repeat task.wait() until game:IsLoaded()

-------------------------------------------------
-- SERVICES
-------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LogService = game:GetService("LogService")
local ScriptContext = game:GetService("ScriptContext")

local player = Players.LocalPlayer

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local EquipRemote = Remotes:WaitForChild("EquipWeapon")
local PortalRemote = Remotes:WaitForChild("TeleportToPortal")
local HakiRemote = RemoteEvents:WaitForChild("HakiRemote")
local ObservationRemote = RemoteEvents:WaitForChild("ObservationHakiRemote")
local SettingsToggle = RemoteEvents:WaitForChild("SettingsToggle")

-------------------------------------------------
-- MOBILE OPTIMIZATION & ANTI RAM LEAK
-------------------------------------------------
pcall(function()
    LogService.MessageOut:Connect(function() end)
    ScriptContext.Error:Connect(function() end)
end)

task.spawn(function()
    while task.wait(30) do
        pcall(function()
            collectgarbage("step", 200)
            if workspace:FindFirstChild("Debris") then workspace.Debris:ClearAllChildren() end
            if workspace:FindFirstChild("Effects") then workspace.Effects:ClearAllChildren() end
        end)
    end
end)

-------------------------------------------------
-- GLOBAL TOGGLES
-------------------------------------------------
local _G_AutoFarm = true
if getgenv().AutoFarm ~= nil then _G_AutoFarm = getgenv().AutoFarm end

local _G_WhiteScreen = true
if getgenv().WhiteScreen ~= nil then _G_WhiteScreen = getgenv().WhiteScreen end

-------------------------------------------------
-- GUI SYSTEM
-------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FarmControlGUI"
ScreenGui.ResetOnSpawn = false 
ScreenGui.DisplayOrder = 999 

if pcall(function() ScreenGui.Parent = CoreGui end) then
else
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
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ZIndex = 2 
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

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
FarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FarmBtn.Font = Enum.Font.GothamBold
FarmBtn.TextSize = 14
FarmBtn.ZIndex = 3 
FarmBtn.Parent = MainFrame
Instance.new("UICorner", FarmBtn).CornerRadius = UDim.new(0, 6)

if _G_AutoFarm then
    FarmBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
    FarmBtn.Text = "Auto Farm: ON"
else
    FarmBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    FarmBtn.Text = "Auto Farm: OFF"
end

local WhiteScreenBtn = Instance.new("TextButton")
WhiteScreenBtn.Size = UDim2.new(0.9, 0, 0, 35)
WhiteScreenBtn.Position = UDim2.new(0.05, 0, 0, 75)
WhiteScreenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
WhiteScreenBtn.Font = Enum.Font.GothamBold
WhiteScreenBtn.TextSize = 14
WhiteScreenBtn.ZIndex = 3 
WhiteScreenBtn.Parent = MainFrame
Instance.new("UICorner", WhiteScreenBtn).CornerRadius = UDim.new(0, 6)

if _G_WhiteScreen then
    WhiteScreenBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
    WhiteScreenBtn.Text = "White Screen: ON"
    WhiteScreenFrame.Visible = true
    pcall(function() RunService:Set3dRenderingEnabled(false) end)
else
    WhiteScreenBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    WhiteScreenBtn.Text = "White Screen: OFF"
    WhiteScreenFrame.Visible = false
    pcall(function() RunService:Set3dRenderingEnabled(true) end)
end

local function MakeDraggable(gui)
    local dragging, dragInput, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
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
    if _G_AutoFarm then
        FarmBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
        FarmBtn.Text = "Auto Farm: ON"
    else
        FarmBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
        FarmBtn.Text = "Auto Farm: OFF"
    end
end)

WhiteScreenBtn.MouseButton1Click:Connect(function()
    _G_WhiteScreen = not _G_WhiteScreen
    if _G_WhiteScreen then
        WhiteScreenBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
        WhiteScreenBtn.Text = "White Screen: ON"
        WhiteScreenFrame.Visible = true
        pcall(function() RunService:Set3dRenderingEnabled(false) end)
    else
        WhiteScreenBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
        WhiteScreenBtn.Text = "White Screen: OFF"
        WhiteScreenFrame.Visible = false
        pcall(function() RunService:Set3dRenderingEnabled(true) end)
    end
end)

-------------------------------------------------
-- GAME SETTINGS & FPS BOOST 
-------------------------------------------------
pcall(function()
    local settingsToToggle = {"DisableCutscene", "DisableVFX", "MuteSFX", "MuteMusic", "DisableScreenShake", "RemoveTexture", "RemoveShadows"}
    for _, settingName in ipairs(settingsToToggle) do
        SettingsToggle:FireServer(settingName, true)
        task.wait(0.1)
    end
end)
settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

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
-- ☢️ NUKE MAP & INVISIBLE PLATFORMS ☢️
-------------------------------------------------
local PlatformFolder = workspace:FindFirstChild("FarmPlatforms")
if not PlatformFolder then
    PlatformFolder = Instance.new("Folder")
    PlatformFolder.Name = "FarmPlatforms"
    PlatformFolder.Parent = workspace
end

-- 1. สร้างพื้นล่องหนมารองรับใต้ CFrame ทุกจุดที่วาร์ปไป
for _, area in ipairs(FarmRoute) do
    local platform = Instance.new("Part")
    platform.Size = Vector3.new(200, 5, 200) -- กว้าง 200x200 กันตกเวลาใช้สกิลแล้วพุ่ง
    platform.CFrame = area.pos * CFrame.new(0, -6, 0) -- วางไว้ใต้เท้า
    platform.Anchored = true
    platform.Transparency = 1 -- ล่องหน
    platform.CanCollide = true
    platform.Parent = PlatformFolder
end

-- 2. ระบบสแกนและทำลายแมพ (ทำงานตลอดเวลาเพื่อรับมือแมพที่เพิ่งโหลดใหม่)
task.spawn(function()
    while task.wait(3) do -- เช็คทุกๆ 3 วินาที
        pcall(function()
            -- ลบ Terrain ทิ้งก่อนเลย
            local Terrain = workspace:FindFirstChildOfClass("Terrain")
            if Terrain then Terrain:Clear() end

            -- กวาดล้างทุกอย่างใน Workspace ยกเว้นผู้เล่นและพื้นล่องหน
            for _, v in pairs(workspace:GetChildren()) do
                -- ข้ามโฟลเดอร์ที่เราสร้าง และข้ามกล้อง
                if v.Name == "FarmPlatforms" or v:IsA("Camera") or v:IsA("Terrain") then continue end
                
                -- ข้าม Script เผื่อระบบเกมต้องใช้
                if v:IsA("Script") or v:IsA("LocalScript") then continue end

                -- ข้ามตัวละคร (ทั้งเรา ทั้งผู้เล่นอื่น ทั้งมอนสเตอร์)
                if v:FindFirstChildOfClass("Humanoid") then continue end

                -- นอกนั้นลบทิ้งให้เกลี้ยง!
                if v:IsA("Folder") or v:IsA("Model") or v:IsA("BasePart") then
                    v:Destroy()
                end
            end
        end)
    end
end)

-------------------------------------------------
-- WEAPONS & UTILITIES
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

-------------------------------------------------
-- AUTO HAKI & OBSERVATION
-------------------------------------------------
local function enableBuso()
    task.wait(1)
    pcall(function() HakiRemote:FireServer("Toggle") end)
end
if player.Character then enableBuso() end
player.CharacterAdded:Connect(function() enableBuso() end)

task.spawn(function()
    while task.wait(30) do
        if _G_AutoFarm then
            pcall(function() ObservationRemote:FireServer("Toggle") end)
        end
    end
end)

-------------------------------------------------
-- AUTO EQUIP
-------------------------------------------------
task.spawn(function()
    local currentWeaponIndex = 1
    while task.wait(0.5) do 
        if not _G_AutoFarm then continue end

        local char = player.Character
        local backpack = player:FindFirstChild("Backpack")
        if not char or not backpack then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then continue end

        local weaponName = WEAPONS[currentWeaponIndex]
        local toolInBackpack = backpack:FindFirstChild(weaponName)
        
        if toolInBackpack then hum:EquipTool(toolInBackpack) end

        currentWeaponIndex = currentWeaponIndex + 1
        if currentWeaponIndex > #WEAPONS then currentWeaponIndex = 1 end
    end
end)

-------------------------------------------------
-- AUTO SKILL 
-------------------------------------------------
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

-------------------------------------------------
-- MAIN FARM
-------------------------------------------------
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

