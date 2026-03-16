repeat task.wait() until game:IsLoaded()

-------------------------------------------------
-- FPS BOOST
-------------------------------------------------

pcall(function()

    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

    for _,v in pairs(game:GetDescendants()) do

        if v:IsA("ParticleEmitter")
        or v:IsA("Trail")
        or v:IsA("Smoke")
        or v:IsA("Fire")
        or v:IsA("Sparkles") then
            v:Destroy()
        end

        if v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        end

        if v:IsA("BasePart") then
            v.Material = Enum.Material.Plastic
            v.Reflectance = 0
        end

    end

    for _,v in pairs(game:GetService("Lighting"):GetChildren()) do
        if v:IsA("BlurEffect")
        or v:IsA("SunRaysEffect")
        or v:IsA("ColorCorrectionEffect")
        or v:IsA("BloomEffect")
        or v:IsA("DepthOfFieldEffect") then
            v:Destroy()
        end
    end

end)

-------------------------------------------------
-- SERVICES
-------------------------------------------------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EquipRemote = Remotes:WaitForChild("EquipWeapon")
local PortalRemote = Remotes:WaitForChild("TeleportToPortal")

local HakiRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("HakiRemote")
local ObservationRemote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ObservationHakiRemote")

-------------------------------------------------
-- WEAPONS
-------------------------------------------------

local WEAPONS = {
    "Strongest In History",
    "Ichigo"
}

local weaponIndex = 1

-------------------------------------------------
-- FAST TELEPORT
-------------------------------------------------

local function fasttp(cf)

    local char = player.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for i = 1,3 do
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
-- AUTO HAKI
-------------------------------------------------

task.spawn(function()
    while task.wait(6) do
        pcall(function()
            HakiRemote:FireServer("Toggle")
            ObservationRemote:FireServer("Toggle")
        end)
    end
end)

-------------------------------------------------
-- WEAPON SWITCH SYSTEM
-------------------------------------------------

task.spawn(function()

    while task.wait(2) do

        local char = player.Character
        local backpack = player:FindFirstChild("Backpack")

        if not char or not backpack then
            continue
        end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then
            continue
        end

        local weaponName = WEAPONS[weaponIndex]

        local weapon =
            char:FindFirstChild(weaponName) or
            backpack:FindFirstChild(weaponName)

        if weapon then

            if weapon.Parent ~= char then
                hum:EquipTool(weapon)
            end

        else

            pcall(function()
                EquipRemote:FireServer("Equip", weaponName)
            end)

        end

        weaponIndex += 1

        if weaponIndex > #WEAPONS then
            weaponIndex = 1
        end

    end

end)

-------------------------------------------------
-- AUTO SKILLS
-------------------------------------------------

task.spawn(function()

    while task.wait(0.25) do

        VirtualInputManager:SendKeyEvent(true,"X",false,game)
        task.wait()
        VirtualInputManager:SendKeyEvent(false,"X",false,game)

    end

end)

-------------------------------------------------
-- FARM ROUTE
-------------------------------------------------

local FarmRoute = {

    {portal = "Snow", pos = CFrame.new(-407.5099,-1.1388,-990.4914)},
    {portal = "Shibuya", pos = CFrame.new(1400.0594,8.4861,484.9847)},
    {portal = "HuecoMundo", pos = CFrame.new(-369.4567,-0.1593,1092.5155)},
    {portal = "Shinjuku", pos = CFrame.new(-17.3715,1.8984,-1842.6716)},
    {portal = "Shinjuku", pos = CFrame.new(666.2935,1.8831,-1692.1214)},
    {portal = "Slime", pos = CFrame.new(-1123.8552,13.9182,368.3176)},
    {portal = "Academy", pos = CFrame.new(1068.3764,1.7783,1277.8568)},
    {portal = "Judgement", pos = CFrame.new(-1270.6287,1.1774,-1192.4418)}

}

-------------------------------------------------
-- MAIN FARM
-------------------------------------------------

task.spawn(function()

    while true do

        for _,area in ipairs(FarmRoute) do

            portal(area.portal)

            task.wait(0.6)

            fasttp(area.pos)

            task.wait(3)

        end

    end

end)
