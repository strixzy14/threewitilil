repeat task.wait() until game:IsLoaded()

-------------------------------------------------
-- 1. MICRO-OPTIMIZATION (ย่อคำสั่งเพื่อลดภาระ RAM)
-------------------------------------------------
local tWait = task.wait
local pcall = pcall
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local sendKey = VirtualInputManager.SendKeyEvent -- ดึงคำสั่งกดปุ่มมารอไว้เลย

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local EquipRemote = Remotes:WaitForChild("EquipWeapon")
local PortalRemote = Remotes:WaitForChild("TeleportToPortal")
local HakiRemote = RemoteEvents:WaitForChild("HakiRemote")
local ObservationRemote = RemoteEvents:WaitForChild("ObservationHakiRemote")
local SettingsToggle = RemoteEvents:WaitForChild("SettingsToggle")

-------------------------------------------------
-- 2. EXTREME RAM SAVER (ปิดทุกอย่างที่แอบกินแรม)
-------------------------------------------------
-- ปิด UI พื้นฐานของ Roblox (ลด RAM จากคนแชท/คนเข้าออกเซิร์ฟ)
pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
end)

-- ตัดระบบเสียงของแอปแบบถอนรากถอนโคน
pcall(function()
    UserSettings():GetService("UserGameSettings").MasterVolume = 0
end)

-- ปรับกราฟิกต่ำสุด
settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

-- ปิด Effect จากระบบเกม
task.spawn(function()
    local settingsToToggle = {
        "DisableCutscene", "DisableVFX", "MuteSFX", 
        "MuteMusic", "DisableScreenShake", "RemoveTexture", "RemoveShadows"
    }
    for _, settingName in ipairs(settingsToToggle) do
        pcall(function() SettingsToggle:FireServer(settingName, true) end)
        tWait(0.1)
    end
end)

-- ปิดเรนเดอร์ 3D ขีดสุด
task.spawn(function()
    tWait(5)
    pcall(function()
        RunService:Set3dRenderingEnabled(false)
    end)
end)

-- ล้าง Cache แบบลึก (ทำทุกๆ 3 นาทีให้เครื่องไม่กระตุก)
task.spawn(function()
    while tWait(180) do
        collectgarbage("collect")
    end
end)

-------------------------------------------------
-- 3. UTILITIES & WEAPONS
-------------------------------------------------
local WEAPONS = {"Soul Reaper", "Strongest In History"}

local function fasttp(cf)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for i = 1, 3 do 
        hrp.CFrame = cf
        tWait() 
    end
end

local function portal(name)
    pcall(function() PortalRemote:FireServer(name) end)
end

-------------------------------------------------
-- 4. AUTO HAKI & OBSERVATION
-------------------------------------------------
local function enableBuso()
    tWait(1)
    pcall(function() HakiRemote:FireServer("Toggle") end)
end
if player.Character then enableBuso() end
player.CharacterAdded:Connect(enableBuso)

task.spawn(function()
    while tWait(30) do
        pcall(function() ObservationRemote:FireServer("Toggle") end)
    end
end)

-------------------------------------------------
-- 5. AUTO EQUIP (0.5 วิ - รีดคำสั่งให้เบาสุด)
-------------------------------------------------
task.spawn(function()
    local currentWeaponIndex = 1
    while tWait(0.5) do
        local char = player.Character
        if char then
            local backpack = player:FindFirstChild("Backpack")
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            if backpack and hum then
                local weaponName = WEAPONS[currentWeaponIndex]
                local toolInBackpack = backpack:FindFirstChild(weaponName)
                
                if toolInBackpack then 
                    hum:EquipTool(toolInBackpack) 
                end

                currentWeaponIndex = currentWeaponIndex + 1
                if currentWeaponIndex > #WEAPONS then currentWeaponIndex = 1 end
            end
        end
    end
end)

-------------------------------------------------
-- 6. AUTO SKILL (0.25 วิ - ใช้คำสั่งลัด ไม่หน่วงเครื่อง)
-------------------------------------------------
task.spawn(function()
    while tWait(0.25) do
        pcall(function()
            sendKey(VirtualInputManager, true, "X", false, game)
            tWait()
            sendKey(VirtualInputManager, false, "X", false, game)
        end)
    end
end)

-------------------------------------------------
-- 7. MAIN FARM ROUTE (วาร์ป 0.6 วิ, ยืน 3 วิ)
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
            tWait(0.6)
            fasttp(area.pos)
            tWait(3)
        end
    end
end)
