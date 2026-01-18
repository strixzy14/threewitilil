-- SERVICES
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- GUI ROOT
local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotInventoryGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- MAIN FRAME
local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(300, 350)
frame.Position = UDim2.new(0, 20, 0.5, -175)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderSizePixel = 0
frame.Parent = gui

-- UI CORNER
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- TITLE
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 40)
title.Position = UDim2.fromOffset(10, 10)
title.BackgroundTransparency = 1
title.Text = "🧠 BRAINROT INVENTORY"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Left
title.Parent = frame

-- INFO
local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 0, 40)
info.Position = UDim2.fromOffset(10, 55)
info.BackgroundTransparency = 1
info.TextColor3 = Color3.fromRGB(200, 200, 200)
info.Font = Enum.Font.Gotham
info.TextSize = 13
info.TextWrapped = true
info.TextXAlignment = Left
info.TextYAlignment = Top
info.Parent = frame

-- SCROLL LIST
local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -20, 1, -150)
list.Position = UDim2.fromOffset(10, 100)
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.ScrollBarImageTransparency = 0.3
list.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
list.BorderSizePixel = 0
list.Parent = frame
Instance.new("UICorner", list).CornerRadius = UDim.new(0, 8)

local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0, 6)

-- REFRESH BUTTON
local refresh = Instance.new("TextButton")
refresh.Size = UDim2.new(1, -20, 0, 35)
refresh.Position = UDim2.new(0, 10, 1, -45)
refresh.Text = "🔄 Refresh"
refresh.Font = Enum.Font.GothamBold
refresh.TextSize = 14
refresh.TextColor3 = Color3.new(1, 1, 1)
refresh.BackgroundColor3 = Color3.fromRGB(60, 120, 255)
refresh.BorderSizePixel = 0
refresh.Parent = frame
Instance.new("UICorner", refresh).CornerRadius = UDim.new(0, 8)

--------------------------------------------------
-- FUNCTION
--------------------------------------------------

local function clearList()
	for _, v in ipairs(list:GetChildren()) do
		if v:IsA("TextLabel") then
			v:Destroy()
		end
	end
end

local function refreshInventory()
	clearList()

	local backpack = player:WaitForChild("Backpack")
	local items = {}
	local total = 0

	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			items[tool.Name] = (items[tool.Name] or 0) + 1
			total += 1
		end
	end

	info.Text = string.format("👤 Player : %s\n📦 Total : %d", player.Name, total)

	for name, count in pairs(items) do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -10, 0, 28)
		label.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Font = Enum.Font.Gotham
		label.TextSize = 13
		label.TextXAlignment = Left
		label.Text = string.format("  • %-20s x%02d", name, count)
		label.Parent = list
		Instance.new("UICorner", label).CornerRadius = UDim.new(0, 6)
	end

	task.wait()
	list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end

refresh.MouseButton1Click:Connect(refreshInventory)

refreshInventory()
