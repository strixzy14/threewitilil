repeat task.wait() until game:IsLoaded()

-------------------------------------------------
-- SERVICES
-------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
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
-- OPTIMIZE RAM & ANTI LEAK
-------------------------------------------------
pcall(function()
    LogService.MessageOut:Connect(function() end)
    ScriptContext.Error:Connect(function() end)
end)

task.spawn(function()
    while task.wait(30) do
        pcall(function()
            [span_4](start_span)[span_5](start_span)collectgarbage("step", 200)[span_4](end_span)[span_5](end_span)
        end)
    end
end)

-------------------------------------------------
-- GLOBAL TOGGLES & GUI SYSTEM
-------------------------------------------------
local _G_AutoFarm = true
local _G_WhiteScreen = true

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FarmControlGUI"
ScreenGui.ResetOnSpawn = false 
ScreenGui.DisplayOrder = 999 
[span_6](start_span)if pcall(function() ScreenGui.Parent = CoreGui end) then else ScreenGui.Parent = player:WaitForChild("PlayerGui") end[span_6](end_span)

local WhiteScreenFrame = Instance.new("Frame")
WhiteScreenFrame.Size = UDim2.new(1.1, 0, 1.1, 0)
WhiteScreenFrame.Position = UDim2.new(-0.05, 0, -0.05, 0) 
WhiteScreenFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
WhiteScreenFrame.ZIndex = 1 
WhiteScreenFrame.Visible = _G_WhiteScreen 
[span_7](start_span)WhiteScreenFrame.Parent = ScreenGui[span_7](end_span)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 200, 0, 120)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -60)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ZIndex = 2 
[span_8](start_span)MainFrame.Parent = ScreenGui[span_8](end_span)
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundTransparency = 1
Title.Text = "Farm Controller"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.ZIndex = 3 
[span_9](start_span)Title.Parent = MainFrame[span_9](end_span)

local FarmBtn = Instance.new("TextButton")
FarmBtn.Size = UDim2.new(0.9, 0, 0, 35)
FarmBtn.Position = UDim2.new(0.05, 0, 0, 35)
FarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FarmBtn.Font = Enum.Font.GothamBold
FarmBtn.TextSize = 14
FarmBtn.ZIndex = 3 
[span_10](start_span)FarmBtn.Parent = MainFrame[span_10](end_span)
Instance.new("UICorner", FarmBtn).CornerRadius = UDim.new(0, 6)
FarmBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
[span_11](start_span)[span_12](start_span)FarmBtn.Text = "Auto Farm: ON"[span_11](end_span)[span_12](end_span)

local WhiteScreenBtn = Instance.new("TextButton")
WhiteScreenBtn.Size = UDim2.new(0.9, 0, 0, 35)
WhiteScreenBtn.Position = UDim2.new(0.05, 0, 0, 75)
WhiteScreenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
WhiteScreenBtn.Font = Enum.Font.GothamBold
WhiteScreenBtn.TextSize = 14
WhiteScreenBtn.ZIndex = 3 
[span_13](start_span)WhiteScreenBtn.Parent = MainFrame[span_13](end_span)
Instance.new("UICorner", WhiteScreenBtn).CornerRadius = UDim.new(0, 6)
WhiteScreenBtn.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
[span_14](start_span)WhiteScreenBtn.Text = "White Screen: ON"[span_14](end_span)
[span_15](start_span)[span_16](start_span)pcall(function() RunService:Set3dRenderingEnabled(false) end)[span_15](end_span)[span_16](end_span)

local function MakeDraggable(gui)
    local dragging, dragInput, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = gui.Position
            [span_17](start_span)input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)[span_17](end_span)
        end
    end)
    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    [span_18](start_span)game:GetService("UserInputService").InputChanged:Connect(function(input)[span_18](end_span)
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
    [span_19](start_span)FarmBtn.Text = _G_AutoFarm and "Auto Farm: ON" or "Auto Farm: OFF"[span_19](end_span)
end)

WhiteScreenBtn.MouseButton1Click:Connect(function()
    _G_WhiteScreen = not _G_WhiteScreen
    WhiteScreenBtn.BackgroundColor3 = _G_WhiteScreen and Color3.fromRGB(40, 200, 40) or Color3.fromRGB(200, 40, 40)
    [span_20](start_span)WhiteScreenBtn.Text = _G_WhiteScreen and "White Screen: ON" or "White Screen: OFF"[span_20](end_span)
    WhiteScreenFrame.Visible = _G_WhiteScreen
    [span_21](start_span)pcall(function() RunService:Set3dRenderingEnabled(not _G_WhiteScreen) end)[span_21](end_span)
end)

-------------------------------------------------
-- GAME SETTINGS
-------------------------------------------------
pcall(function()
    local settingsToToggle = {"DisableCutscene", "DisableVFX", "MuteSFX", "MuteMusic", "DisableScreenShake", "RemoveTexture", "RemoveShadows"}
    for _, name in ipairs(settingsToToggle) do
        [span_22](start_span)[span_23](start_span)SettingsToggle:FireServer(name, true)[span_22](end_span)[span_23](end_span)
    end
end)
[span_24](start_span)[span_25](start_span)settings().Rendering.QualityLevel = Enum.QualityLevel.Level01[span_24](end_span)[span_25](end_span)

-------------------------------------------------
-- MAIN FARM ROUTE
-------------------------------------------------
local FarmRoute = {
    [span_26](start_span){portal = "Shibuya", pos = CFrame.new(1400.0594, 8.4861, 484.9847)},[span_26](end_span)
    [span_27](start_span){portal = "HuecoMundo", pos = CFrame.new(-369.4567, -0.1593, 1092.5155)},[span_27](end_span)
    [span_28](start_span)[span_29](start_span){portal = "Shinjuku", pos = CFrame.new(-17.3715, 1.8984, -1842.6716)},[span_28](end_span)[span_29](end_span)
    [span_30](start_span){portal = "Shinjuku", pos = CFrame.new(666.2935, 1.8831, -1692.1214)},[span_30](end_span)
    [span_31](start_span){portal = "Slime", pos = CFrame.new(-1123.8552, 13.9182, 368.3176)},[span_31](end_span)
    [span_32](start_span){portal = "Academy", pos = CFrame.new(1068.3764, 1.7783, 1277.8568)},[span_32](end_span)
    [span_33](start_span){portal = "Judgement", pos = CFrame.new(-1270.6287, 1.1774, -1192.4418)},[span_33](end_span)
    [span_34](start_span){portal = "Ninja", pos = CFrame.new(-1878.8419, 8.5140, -739.5654)},[span_34](end_span)
    [span_35](start_span){portal = "Lawless", pos = CFrame.new(52.5574, 0.5787, 1815.9211)},[span_35](end_span)
    [span_36](start_span){portal = "Tower", pos = CFrame.new(-1270.6287, 1.1774, -1192.4418)}[span_36](end_span)
}

-------------------------------------------------
-- ☢️ OPTIMIZED NUKE MAP (ตามที่คุณสั่ง) ☢️
-------------------------------------------------
local PlatformFolder = workspace:FindFirstChild("FarmPlatforms") or Instance.new("Folder", workspace)
PlatformFolder.Name = "FarmPlatforms"

-- 1. สร้างพื้นล่องหนกันตก
for _, area in ipairs(FarmRoute) do
    local platform = Instance.new("Part")
    platform.Size = Vector3.new(200, 5, 200)
    platform.CFrame = area.pos * CFrame.new(0, -6, 0)
    platform.Anchored = true
    platform.Transparency = 1
    platform.CanCollide = true
    platform.Parent = PlatformFolder
end

-- 2. ฟังก์ชันทำลายแมพแบบไม่ลบตัวละคร/มอนสเตอร์
local function SuperNuke(v)
    local char = player.Character
    if v == char or v == PlatformFolder or v.Name == "FarmPlatforms" then return end
    if v:IsA("Camera") or v:IsA("Terrain") then return end
    
    -- เก็บ "มอนสเตอร์" ไว้ตี
    if v:FindFirstChildOfClass("Humanoid") then return end

    [span_37](start_span)pcall(function() v:Destroy() end)[span_37](end_span)
end

-- 3. ลบทีเดียวรวดเดียวตอนเริ่มเกม
task.spawn(function()
    task.wait(3)
    local Terrain = workspace:FindFirstChildOfClass("Terrain")
    if Terrain then Terrain:Clear() end
    for _, v in pairs(workspace:GetChildren()) do
        [span_38](start_span)SuperNuke(v)[span_38](end_span)
    end
end)

-- 4. ดักจับเกาะที่แอบโหลดใหม่ (Streaming)
workspace.ChildAdded:Connect(function(v)
    task.spawn(function()
        task.wait(0.1)
        [span_39](start_span)SuperNuke(v)[span_39](end_span)
    end)
end)

-------------------------------------------------
-- WEAPONS & UTILITIES
-------------------------------------------------
[span_40](start_span)local WEAPONS = {"Soul Reaper", "Strongest In History"}[span_40](end_span)

local function fasttp(cf)
    local char = player.Character
    [span_41](start_span)if not char then return end[span_41](end_span)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    [span_42](start_span)for i = 1, 3 do hrp.CFrame = cf; task.wait() end[span_42](end_span)
end

local function portal(name)
    [span_43](start_span)pcall(function() PortalRemote:FireServer(name) end)[span_43](end_span)
end

-------------------------------------------------
-- AUTO HAKI & OBSERVATION
-------------------------------------------------
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

-------------------------------------------------
-- AUTO EQUIP (เวลาเดิม: 0.5)
-------------------------------------------------
task.spawn(function()
    local currentWeaponIndex = 1
    while task.wait(0.5) do 
        if not _G_AutoFarm then continue end
        local char = player.Character
        local backpack = player:FindFirstChild("Backpack")
        [span_44](start_span)if not char or not backpack then continue end[span_44](end_span)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then continue end

        local weaponName = WEAPONS[currentWeaponIndex]
        [span_45](start_span)local toolInBackpack = backpack:FindFirstChild(weaponName)[span_45](end_span)
        if toolInBackpack then hum:EquipTool(toolInBackpack) end

        currentWeaponIndex = currentWeaponIndex + 1
        if currentWeaponIndex > #WEAPONS then currentWeaponIndex = 1 end
    end
end)

-------------------------------------------------
-- AUTO SKILL (เวลาเดิม: 0.25)
-------------------------------------------------
task.spawn(function()
    while task.wait(0.25) do 
        if _G_AutoFarm then
            pcall(function()
                [span_46](start_span)VirtualInputManager:SendKeyEvent(true, "X", false, game)[span_46](end_span)
                task.wait()
                VirtualInputManager:SendKeyEvent(false, "X", false, game)
            end)
        end
    end
end)

-------------------------------------------------
-- MAIN FARM (เวลาเดิม: วาร์ป 0.6, ยืน 3)
-------------------------------------------------
task.spawn(function()
    while true do
        if _G_AutoFarm then
            [span_47](start_span)for _, area in ipairs(FarmRoute) do[span_47](end_span)
                if not _G_AutoFarm then break end
                portal(area.portal)
                task.wait(0.6)
                fasttp(area.pos)
                [span_48](start_span)task.wait(3)[span_48](end_span)
            end
        else
            task.wait(1)
        end
    end
end)
