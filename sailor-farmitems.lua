repeat task.wait() until game:IsLoaded()

-------------------------------------------------
-- SERVICES
-------------------------------------------------
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local EquipRemote = Remotes:WaitForChild("EquipWeapon")
local PortalRemote = Remotes:WaitForChild("TeleportToPortal")
local HakiRemote = RemoteEvents:WaitForChild("HakiRemote")
local ObservationRemote = RemoteEvents:WaitForChild("ObservationHakiRemote")
local SettingsToggle = RemoteEvents:WaitForChild("SettingsToggle")

-------------------------------------------------
-- GAME SETTINGS (รันก่อนเริ่มฟาร์ม)
-------------------------------------------------
pcall(function()
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
        SettingsToggle:FireServer(settingName, true)
        task.wait(0.1)
    end
end)

-------------------------------------------------
-- FPS BOOST (ลบ Texture, ปิดเงา, ลดแสง กินสเปคน้อยลง)
-------------------------------------------------
pcall(function()
    -- ปรับระดับกราฟิกของตัวเกม
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    
    -- ปิดเงาและแสงสะท้อนของแมพ
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.ShadowSoftness = 0
    
    -- ลดกราฟิกของ Terrain (น้ำและพื้นผิว)
    local Terrain = workspace:FindFirstChildOfClass("Terrain")
    if Terrain then
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0
    end

    for _, v in pairs(game:GetDescendants()) do
        -- ลบเอฟเฟกต์อนุภาคต่างๆ
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
            v.Enabled = false
            v:Destroy()
        end

        -- ลบ Texture และ Decal คืนพื้นที่ RAM
        if v:IsA("Decal") or v:IsA("Texture") then
            v:Destroy()
        end

        -- ปรับชิ้นส่วนโมเดลให้ไม่มีเงาและเป็นพลาสติกเรียบๆ
        if v:IsA("BasePart") or v:IsA("MeshPart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
            v.CastShadow = false
        end
    end

    -- ลบเอฟเฟกต์แสงโพสต์โพรเซส
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("PostEffect") then
            v:Destroy()
        end
    end
end)

-------------------------------------------------
-- WEAPONS
-------------------------------------------------
local WEAPONS = {
    "Soul Reaper",
    "Strongest In History"
}

-------------------------------------------------
-- FAST TELEPORT
-------------------------------------------------
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

-------------------------------------------------
-- PORTAL
-------------------------------------------------
local function portal(name)
    pcall(function()
        PortalRemote:FireServer(name)
    end)
end

-------------------------------------------------
-- AUTO HAKI SYSTEM
-------------------------------------------------
local function enableBuso()
    task.wait(1)
    pcall(function()
        HakiRemote:FireServer("Toggle")
    end)
end

-- เปิดตอนเริ่ม
if player.Character then
    enableBuso()
end

-- เปิดใหม่ตอนตาย
player.CharacterAdded:Connect(function()
    enableBuso()
end)

-------------------------------------------------
-- OBSERVATION HAKI (EVERY 30s)
-------------------------------------------------
task.spawn(function()
    while true do
        task.wait(30)
        pcall(function()
            ObservationRemote:FireServer("Toggle")
        end)
    end
end)

-------------------------------------------------
-- AUTO EQUIP MULTI WEAPON (ดึงจากของที่มีอยู่ ไม่ยุ่งกับคลังเกม)
-------------------------------------------------
task.spawn(function()
    local currentWeaponIndex = 1

    while task.wait(0.5) do -- สลับอาวุธทุกๆ 5 วินาที (ปรับเวลาได้)
        local char = player.Character
        local backpack = player:FindFirstChild("Backpack")

        if not char or not backpack then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then continue end

        local weaponName = WEAPONS[currentWeaponIndex]
        
        -- หาอาวุธในตัว หรือ ในกระเป๋า
        local toolInBackpack = backpack:FindFirstChild(weaponName)
        local toolInChar = char:FindFirstChild(weaponName)

        -- ถ้าอาวุธอยู่ในกระเป๋า (ยังไม่ได้ถือ) ให้หยิบขึ้นมา
        if toolInBackpack then
            hum:EquipTool(toolInBackpack)
        end
        -- (ถ้า toolInChar มีค่าแปลว่าถืออยู่แล้ว ก็ไม่ต้องทำอะไร ปล่อยฟันต่อไป)

        -- สลับไปยังอาวุธชิ้นถัดไป
        currentWeaponIndex = currentWeaponIndex + 1
        if currentWeaponIndex > #WEAPONS then
            currentWeaponIndex = 1
        end
    end
end)

-------------------------------------------------
-- AUTO SKILL (X & V)
-------------------------------------------------
task.spawn(function()
    while task.wait(0.25) do
        VirtualInputManager:SendKeyEvent(true, "X", false, game)
        task.wait()
        VirtualInputManager:SendKeyEvent(false, "X", false, game)
    end
end)

-------------------------------------------------
-- FARM ROUTE
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

-------------------------------------------------
-- MAIN FARM
-------------------------------------------------
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
