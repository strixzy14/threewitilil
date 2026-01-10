--==================================================
-- Services
--==================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

--==================================================
-- Anti AFK (Always ON)
--==================================================
RunService.Heartbeat:Connect(function()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:Move(Vector3.new(0,0,0), false)
    end
end)

--==================================================
-- Remote
--==================================================
local rf = ReplicatedStorage:WaitForChild("Msg"):WaitForChild("RemoteFunction")

local farmArgs = {
    "\231\130\185\229\135\187\230\176\180\230\158\156\230\156\186\229\153\168",
    1
}

local buyCmd = "\232\180\173\228\185\176\233\173\148\230\179\149\232\141\175\230\176\180"
local BuyItemIDs = {15000001,15000002,15000003}

local upgradeCmd = "\229\141\135\231\186\167\230\176\180\230\158\156\230\156\186\229\153\168"

--==================================================
-- Flags
--==================================================
_G.Flags = {
    AutoFarm = false,
    AutoBuyAll = false,
    AutoUpgrade1 = false,
    AutoUpgrade2 = false,
    AutoUpgrade3 = false,
    AutoUpgrade4 = false,
    AutoCollect = false
}


_G.CollectPrice = 10_000_000 -- 10M (เผื่อใช้ต่อ)
--==================================================
-- Auto Farm
--==================================================
task.spawn(function()
    while task.wait(0.25) do
        if _G.Flags.AutoFarm then
            pcall(function()
                rf:InvokeServer(unpack(farmArgs))
            end)
        end
    end
end)

--==================================================
-- Auto Buy
--==================================================
task.spawn(function()
    while task.wait(0.7) do
        if _G.Flags.AutoBuyAll then
            for _, id in ipairs(BuyItemIDs) do
                pcall(function()
                    rf:InvokeServer(buyCmd, {id,1})
                end)
                task.wait(0.25)
            end
        end
    end
end)

--==================================================
-- Auto Upgrade Board 1 (RAW)
--==================================================
task.spawn(function()
    while task.wait(0.8) do
        if _G.Flags.AutoUpgrade1 then
            pcall(function()
                rf:InvokeServer(upgradeCmd, 1)
            end)
        end
    end
end)

--==================================================
-- Auto Upgrade Board 2 (RAW)
--==================================================
task.spawn(function()
    while task.wait(0.9) do
        if _G.Flags.AutoUpgrade2 then
            pcall(function()
                rf:InvokeServer(upgradeCmd, 2)
            end)
        end
    end
end)

--==================================================
-- Auto Upgrade Board 3 (RAW)
--==================================================
task.spawn(function()
    while task.wait(1) do
        if _G.Flags.AutoUpgrade3 then
            pcall(function()
                rf:InvokeServer(upgradeCmd, 3)
            end)
        end
    end
end)

--==================================================
-- Auto Upgrade Board 4 (RAW)
--==================================================
task.spawn(function()
    while task.wait(1.1) do
        if _G.Flags.AutoUpgrade4 then
            pcall(function()
                rf:InvokeServer(upgradeCmd, 4)
            end)
        end
    end
end)

--==================================================
-- Auto Collect (RAW rspy)
--==================================================
local collectCmd = "\230\148\182\232\142\183\230\176\180\230\158\156"

local MAX_MACHINE = 15
local MAX_SLOT = 6

task.spawn(function()
    while task.wait(0.6) do
        if not _G.Flags.AutoCollect then continue end

        for machine = 1, MAX_MACHINE do
            for slot = 1, MAX_SLOT do
                pcall(function()
                    rf:InvokeServer(collectCmd, {machine, slot})
                end)
                task.wait(0.12)
            end
        end
    end
end)

--==================================================
-- GUI
--==================================================
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "SSS_GUI"
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.fromOffset(300, 320)
main.Position = UDim2.new(0,50,0.3,0)
main.BackgroundColor3 = Color3.fromRGB(20,20,20)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0,8)

-- Title
local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1,0,0,35)
title.BackgroundTransparency = 1
title.Text = "⚡ SSS"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(0,255,170)

--==================================================
-- Tabs
--==================================================
local tabs = {"Farm","Buy","Upgrade"}
local pages = {}

for i, name in ipairs(tabs) do
    local btn = Instance.new("TextButton", main)
    btn.Size = UDim2.new(0,90,0,28)
    btn.Position = UDim2.new(0,(i-1)*100+10,0,40)
    btn.Text = name
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    local page = Instance.new("Frame", main)
    page.Position = UDim2.new(0,10,0,80)
    page.Size = UDim2.new(1,-20,1,-90)
    page.Visible = i == 1
    page.BackgroundTransparency = 1
    pages[name] = page

    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(pages) do p.Visible = false end
        page.Visible = true
    end)
end

--==================================================
-- Toggle Maker
--==================================================
local function makeToggle(parent, text, y, flag)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1,0,0,32)
    btn.Position = UDim2.new(0,0,0,y)
    btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    btn.Text = text.." : OFF"
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

    btn.MouseButton1Click:Connect(function()
        _G.Flags[flag] = not _G.Flags[flag]
        btn.Text = text.." : "..(_G.Flags[flag] and "ON" or "OFF")
        btn.BackgroundColor3 = _G.Flags[flag]
            and Color3.fromRGB(0,170,100)
            or Color3.fromRGB(35,35,35)
    end)
end

-- Farm Tab
makeToggle(pages.Farm, "Auto Click Pot", 0, "AutoFarm")
makeToggle(pages.Farm, "Auto Collect Fruit", 40, "AutoCollect")

-- Buy Tab
makeToggle(pages.Buy, "Auto Buy All Potion", 0, "AutoBuyAll")

-- Upgrade Tab
makeToggle(pages.Upgrade, "Auto Upgrade Planting Pot", 0, "AutoUpgrade1")
makeToggle(pages.Upgrade, "Auto Upgrade Planter", 40, "AutoUpgrade2")
makeToggle(pages.Upgrade, "Auto Upgrade Farm", 80, "AutoUpgrade3")
makeToggle(pages.Upgrade, "Auto Upgrade Green House", 120, "AutoUpgrade4")

--==================================================
-- Hide GUI
--==================================================
UIS.InputBegan:Connect(function(i,g)
    if g then return end
    if i.KeyCode == Enum.KeyCode.RightControl then
        main.Visible = not main.Visible
    end
end)

--==================================================
-- Mobile Toggle UI Button (PRO)
--==================================================
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

if UserInputService.TouchEnabled then
    -- Shadow
    local shadow = Instance.new("Frame")
    shadow.Parent = gui
    shadow.Size = UDim2.fromOffset(54, 54)
    shadow.Position = UDim2.new(0.5, -27, 0.05, 2)
    shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
    shadow.BackgroundTransparency = 0.6
    shadow.ZIndex = 9
    Instance.new("UICorner", shadow).CornerRadius = UDim.new(1,0)

    -- Button
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Parent = gui
    toggleBtn.Size = UDim2.fromOffset(50, 50)
    toggleBtn.Position = UDim2.new(0.5, -25, 0.05, 0)
    toggleBtn.Text = "X"
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 18
    toggleBtn.TextColor3 = Color3.fromRGB(255,255,255)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(0,170,100)
    toggleBtn.AutoButtonColor = false
    toggleBtn.ZIndex = 10
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1,0)

    -- Gradient
    local gradient = Instance.new("UIGradient", toggleBtn)
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 180)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 90))
    }
    gradient.Rotation = 45

    -- Click animation
    local pressTween = TweenService:Create(
        toggleBtn,
        TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.fromOffset(44, 44), Position = UDim2.new(0.5, -22, 0.05, 3)}
    )

    local releaseTween = TweenService:Create(
        toggleBtn,
        TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.fromOffset(50, 50), Position = UDim2.new(0.5, -25, 0.05, 0)}
    )

    toggleBtn.MouseButton1Down:Connect(function()
        pressTween:Play()
    end)

    toggleBtn.MouseButton1Up:Connect(function()
        releaseTween:Play()
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        main.Visible = not main.Visible
    end)
end
