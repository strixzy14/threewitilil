repeat task.wait() until game:IsLoaded()

-------------------------------------------------
-- SERVICES
-------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local EquipRemote = Remotes:WaitForChild("EquipWeapon")
local PortalRemote = Remotes:WaitForChild("TeleportToPortal")
local HakiRemote = RemoteEvents:WaitForChild("HakiRemote")
local ObservationRemote = RemoteEvents:WaitForChild("ObservationHakiRemote")
local SettingsToggle = RemoteEvents:WaitForChild("SettingsToggle")

-------------------------------------------------
-- CLEAN OPTIMIZATION (รีดประสิทธิภาพ ลด RAM)
-------------------------------------------------
-- 1. ปรับกราฟิกต่ำสุด
settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

-- 2. ปิด Effect จากระบบเกม
task.spawn(function()
    local settingsToToggle = {
        "DisableCutscene", 
        "DisableVFX", 
        "MuteSFX", 
        "MuteMusic", 
        "DisableScreenShake", 
        "RemoveTexture", 
        "RemoveShadows"
    }
    for _, settingName in ipairs(settingsToToggle) do
        pcall(function()
            SettingsToggle:FireServer(settingName, true)
        end)
        task.wait(0.1)
    end
end)

-- 3. ปิดเรนเดอร์ 3D (ประหยัดแรมขีดสุด หน้าจอค้างแต่ฟาร์มปกติ)
task.spawn(function()
    task.wait(5)
    pcall(function()
        RunService:Set3dRenderingEnabled(false)
    end)
end)

-- 4. ระบบล้างแรมแบบเบา (ไม่กระชากเครื่อง)
task.spawn(function()
    while task.wait(60) do
        collectgarbage("step", 200)
    end
end)

-------------------------------------------------
-- UTILITIES & WEAPONS
-------------------------------------------------
local WEAPONS = {"Soul Reaper", "Strongest In History"}

local function fasttp(cf)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for i = 1, 3 do 
        hrp.CFrame = cf
        task.wait() 
    end
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
player.CharacterAdded:Connect(enableBuso)

task.spawn(function()
    while task.wait(30) do
        pcall(function() ObservationRemote:FireServer("Toggle") end)
    end
end)

-------------------------------------------------
-- AUTO EQUIP (เวลาเดิม: 0.5)
-------------------------------------------------
task.spawn(function()
    local currentWeaponIndex = 1
    while task.wait(0.5) do
        local char = player.Character
        local backpack = player:FindFirstChild("Backpack")
        if not char or not backpack then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then continue end

        local weaponName = WEAPONS[currentWeaponIndex]
        local toolInBackpack = backpack:FindFirstChild(weaponName)
        
        if toolInBackpack then 
            hum:EquipTool(toolInBackpack) 
        end

        currentWeaponIndex = currentWeaponIndex + 1
        if currentWeaponIndex > #WEAPONS then currentWeaponIndex = 1 end
    end
end)

-------------------------------------------------
-- AUTO SKILL (เวลาเดิม: 0.25)
-------------------------------------------------
task.spawn(function()
    while task.wait(0.25) do
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, "X", false, game)
            task.wait()
            VirtualInputManager:SendKeyEvent(false, "X", false, game)
        end)
    end
end)

-------------------------------------------------
-- MAIN FARM ROUTE (เวลาเดิม: วาร์ป 0.6, ยืน 3)
-------------------------------------------------
local FarmRoute = {
    {portal = "Snow", pos = CFrame.new(-407.5099, -1.1388, -990.4914)},
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

task.spawn(function()
    while true do
        for _, area in ipairs(FarmRoute) do
            portal(area.portal)
            task.wait(0.6)
            fasttp(area.pos)
            task.wait(3)
        end
    end
end)

