-- filesRead: Build a Zoo NEW UI - Final.lua
-- patch: fishing-bait-dropdown -- date: 2025-09-12
-- tools: repo-reader, regex-patch (scan structure, minimal-diff patching)
-- plan: เพิ่ม dropdown เหยื่อในแท็บ Fishing; ผูก State; คง logic เดิม
--========================================================
-- 1. CONFIGURATION & CONSTANTS
--========================================================
local CONFIG = {
    -- UI Settings
    WINDOW_NAME = "Xenitz Hub",
    LOADING_TITLE = "Xenitz Hub", 
    LOADING_SUBTITLE = "Loading",
    
    -- Timing Constants
    AUTO_COLLECT_DELAY = 2.5,
    BUY_DELAY = 0.15,
    LOOP_DELAY = 0.20,
    FOOD_FOCUS_DELAY = 0.35,
    FEED_GAP = 0.12,
    HOLD_STEP = 1.0,
    LOOP_IDLE_SLEEP = 0.50,
    
    -- Fishing Constants
    CAST_DISTANCE = 10,
    Y_OFFSET_FROM_ME = -2,
    EQUIP_HOLD_DELAY = 1.0,
    BITE_WAIT_LIMIT = 10,
    POLL_INTERVAL = 0.02,
    ICON_RESET_LIMIT = 6.0,
    LOOP_PAUSE = 1.0,
    
    -- URLs
    RAYFIELD_URLS = {
        "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",
        "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/source.lua",
    },
    
    -- Tab Configuration
    TABS = {
        {name = "Main", icon = "layout-list"},
        {name = "Fruit Shop", icon = "shopping-bag"},
        {name = "Big Pets", icon = "paw-print"},
		{name = "Egg", icon = "egg"},
		{name = "Give", icon = "gift"},
		{name = "Fishing", icon = "anchor"},
		{name = "Quest", icon = "flag"},
		{name = "All Egg", icon = "egg"}
    }
}

--========================================================
-- 2. SERVICES & GLOBAL REFERENCES
--========================================================
local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    Workspace = game:GetService("Workspace")
}

local LocalPlayer = Services.Players.LocalPlayer
local Remotes = {}
local RayfieldLibRef = nil

-- 3. GLOBAL STATE MANAGEMENT
local State = {
    -- Auto Collect
    autoCollect = {
        on = false,
        thread = nil
    },
    
    -- Fruit Shop
    fruitShop = {
        autoBuy = { on = false, thread = nil },
        autoBuyAll = { on = false, thread = nil },
        selectedFruits = {}
    },
    
    -- Big Pets
    bigPets = {
        autoFeed = { on = false, thread = nil },
        petLand1 = { on = false, id = nil },
        petLand2 = { on = false, id = nil }, 
        petWater1 = { on = false, id = nil },
        selectedFruits = {}
    },
    
    -- Egg
    egg = {
        autoBuy = { on = false },
        selectedEggs = {},
        selectedMutation = "None"
    },
    
    -- Give
    give = {
        autoGive = { on = false, thread = nil },
        selectedPlayer = nil,
        selectedPlayerName = nil,
        selectedEgg = "None",
        selectedMutation = "None",
        selectedFruits = {},
        eggLoop = { on = false, thread = nil },
        fruitHold = { on = false, thread = nil }
    },
    
    -- Fishing
    fishing = {
        autoFish = { on = false, thread = nil },
        selectedBait = "FishingBait1",
        cframeLock = { active = false, cf = nil, con = nil, hum = nil, savedStates = nil }
    }
}

-- Global state accessor
_G.Xenitz = State

-- 4. UTILITY FUNCTIONS
--========================================================
local Utils = {}

-- หยุด thread อย่างปลอดภัย
function Utils.stopThread(thread)
    if thread then
        pcall(task.cancel, thread)
    end
    return nil
end

-- ยิง RemoteEvent อย่างปลอดภัย
function Utils.safeFire(remote, ...)
    if not remote then return false end
    local ok, err = pcall(remote.FireServer, remote, ...)
    if not ok then warn("[Xenitz] Remote error:", err) end
    return ok
end

-- Normalize string
function Utils.normalize(s)
    if type(s) ~= "string" then return "" end
    return s:lower():gsub("[%s%p_]+", "")
end

-- แปลงค่าเป็น string list
function Utils.toStringList(v)
    local out, seen = {}, {}
    if type(v) == "string" then
        if v ~= "" then out[1] = v end
    elseif type(v) == "table" then
        for _, x in pairs(v) do
            if type(x) == "string" and x ~= "" and not seen[x] then
                seen[x] = true
                table.insert(out, x)
            end
        end
    end
    return out
end

-- เลือกค่า string จาก mixed input
function Utils.pickString(v)
    if type(v) == "string" then return v end
    if type(v) == "table" then
        if type(v.Name) == "string" then return v.Name end
        if type(v[1]) == "string" then return v[1] end
        for _, val in pairs(v) do 
            if type(val) == "string" then return val end 
        end
    end
    return ""
end

-- Normalize choice สำหรับ dropdown
function Utils.normalizeChoice(v)
    if type(v) == "table" then return v[1] end
    return v
end

--========================================================
-- 5. UI HELPER FUNCTIONS (UNIFIED)
--========================================================
local UI = {}

-- สร้าง Section (รองรับหลาย UI library)
function UI.createSection(tab, title)
    pcall(function()
        if typeof(tab.CreateSection) == "function" then 
            tab:CreateSection(title)
        elseif typeof(tab.AddSection) == "function" then 
            tab:AddSection(title)
        elseif typeof(tab.CreateParagraph) == "function" then 
            tab:CreateParagraph({ Title = title, Content = "" })
        end
    end)
end

-- สร้าง Toggle
function UI.createToggle(tab, options)
    if typeof(tab.CreateToggle) == "function" then 
        return tab:CreateToggle(options)
    elseif typeof(tab.AddToggle) == "function" then 
        return tab:AddToggle(options)
    end
end

-- สร้าง Dropdown
function UI.createDropdown(tab, options)
    if typeof(tab.CreateDropdown) == "function" then 
        return tab:CreateDropdown(options)
    elseif typeof(tab.AddDropdown) == "function" then 
        return tab:AddDropdown(options)
    end
end

-- สร้าง Button
function UI.createButton(tab, options)
    if typeof(tab.CreateButton) == "function" then 
        return tab:CreateButton(options)
    elseif typeof(tab.AddButton) == "function" then 
        return tab:AddButton(options)
    end
end

--========================================================
-- 6. DATA PROVIDERS (UNIFIED)
--========================================================
local DataProviders = {}

-- รับ ResourcePull reference
function DataProviders.getResourcePull()
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    return pg and pg:FindFirstChild("ResourcePull") or nil
end

-- รับรายชื่อผลไม้จาก ResourcePull
function DataProviders.getFruitsFromResourcePull()
    local rp = DataProviders.getResourcePull()
    local out, seen = {}, {}
    
    if not rp then return out end
    
    local function addFromString(s)
        if type(s) ~= "string" then return end
        local m = s:match("^PetFood/(.+)")
        if m and m ~= "" and not seen[m] then 
            seen[m] = true
            table.insert(out, m) 
        end
    end
    
    for _, d in ipairs(rp:GetDescendants()) do
        addFromString(d.Name)
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
            addFromString(d.Text)
        end
    end
    
    return out
end

-- รับ Shop UI reference
function DataProviders.getShopUI()
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    local scr = pg and pg:FindFirstChild("ScreenFoodStore")
    local root = scr and scr:FindFirstChild("Root")
    local frm = root and root:FindFirstChild("Frame")
    return frm and frm:FindFirstChild("ScrollingFrame")
end

-- รับลำดับจาก Shop UI
function DataProviders.getShopOrder()
    local sf = DataProviders.getShopUI()
    if not sf then return {}, {} end
    
    local rows, idx = {}, 0
    for _, ch in ipairs(sf:GetChildren()) do
        if ch:IsA("Frame") and ch.Name ~= "UIListLayout" and ch.Name ~= "LastSpace" and ch.Name ~= "ItemTemplate" then
            idx = idx + 1
            table.insert(rows, {
                name = ch.Name,
                order = tonumber(ch.LayoutOrder) or 0,
                y = (ch.AbsolutePosition and ch.AbsolutePosition.Y) or 0,
                idx = idx
            })
        end
    end
    
    table.sort(rows, function(a, b)
        if a.order ~= b.order then return a.order < b.order end
        if a.y ~= b.y then return a.y < b.y end
        return a.idx < b.idx
    end)
    
    local ordered, pos = {}, {}
    for i, r in ipairs(rows) do 
        ordered[i] = r.name
        pos[r.name] = i 
    end
    return ordered, pos
end

-- รับลำดับผลไม้จาก Shop UI
function DataProviders.getFruitsOrderedByShop()
    local rpList = DataProviders.getFruitsFromResourcePull()
    local shopList, shopPos = DataProviders.getShopOrder()
    
    if #shopList == 0 then return rpList end
    
    local items = {}
    for i, name in ipairs(rpList) do
        table.insert(items, {
            name = name, 
            sidx = shopPos[name] or 1e9, 
            ridx = i
        })
    end
    
    table.sort(items, function(a, b)
        if a.sidx ~= b.sidx then return a.sidx < b.sidx end
        return a.ridx < b.ridx
    end)
    
    local out = {}
    for _, it in ipairs(items) do 
        table.insert(out, it.name) 
    end
    return out
end

-- ตรวจสอบสต็อกผลไม้
function DataProviders.isFruitInStock(fruitName)
    local sf = DataProviders.getShopUI()
    if not sf then return false end
    
    local item = sf:FindFirstChild(fruitName)
    if not item then return false end
    
    local stockLabel = nil
    local btn = item:FindFirstChild("ItemButton")
    if btn then stockLabel = btn:FindFirstChild("StockLabel") end
    if not stockLabel then stockLabel = item:FindFirstChild("StockLabel", true) end
    
    if stockLabel and stockLabel:IsA("TextLabel") then
        local t = tostring(stockLabel.Text or ""):lower()
        if t:find("no stock") then return false end
        local n = tonumber(t:match("(%d+)"))
        if n ~= nil then return n > 0 end
        return true
    end
    
    return true
end

-- รับรายชื่อผู้เล่นอื่น
function DataProviders.getOtherPlayers()
    local players = {}
    for _, plr in ipairs(Services.Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(players, plr.Name)
        end
    end
    table.sort(players)
    if #players == 0 then players = {"<no players>"} end
    return players
end

-- รับ Pets folder
function DataProviders.getPetsFolder()
    local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    local data = pg and pg:FindFirstChild("Data")
    return data and data:FindFirstChild("Pets") or nil
end

-- ตรวจสอบว่าเป็นสัตว์น้ำ
function DataProviders.isWaterPet(inst)
    if not inst then return false end
    if (inst.GetAttribute and inst:GetAttribute("BPT")) ~= nil then return true end
    return inst:FindFirstChild("BPT", true) ~= nil
end

-- ตรวจสอบ attribute
function DataProviders.hasAttribute(inst, key) 
    return (inst and inst.GetAttribute and inst:GetAttribute(key)) ~= nil 
end

-- รายชื่อสัตว์ดินและน้ำ
function DataProviders.listLandAndWaterPets()
    local land, water = {}, {}
    local folder = DataProviders.getPetsFolder()
    if folder then
        local seen = {}
        for _, ch in ipairs(folder:GetChildren()) do
            if not seen[ch.Name] then
                seen[ch.Name] = true
                if DataProviders.isWaterPet(ch) then 
                    table.insert(water, ch.Name)
                elseif DataProviders.hasAttribute(ch, "BPSK") then 
                    table.insert(land, ch.Name) 
                end
            end
        end
    end
    table.sort(land)
    table.sort(water)
    return land, water
end

-- หา EggPools
function DataProviders.findEggPools()
    local direct = Services.ReplicatedStorage:FindFirstChild("EggPools")
    if direct then return direct end
    for _, inst in ipairs(Services.ReplicatedStorage:GetDescendants()) do
        if inst:IsA("Folder") and inst.Name == "EggPools" then return inst end
    end
    return nil
end

-- รวบรวมชื่อไข่จาก EggPools ทั้งหมด
function DataProviders.collectAllEggNames()
    local set, out = {}, {}
    local function add(name)
        if not name or name == "" then return end
        if name:match("_W$") then return end
        local key = Utils.normalize(name)
        if not set[key] then 
            set[key] = true
            table.insert(out, name) 
        end
    end
    
    local pools = {}
    if Services.ReplicatedStorage:FindFirstChild("EggPools") then 
        table.insert(pools, Services.ReplicatedStorage.EggPools) 
    end
    for _, inst in ipairs(Services.ReplicatedStorage:GetDescendants()) do
        if inst:IsA("Folder") and inst.Name == "EggPools" then
            table.insert(pools, inst)
        end
    end
    
    for _, pool in ipairs(pools) do
        for _, ch in ipairs(pool:GetChildren()) do
            add(ch.Name)
        end
    end
    
    table.sort(out)
    if #out == 0 then out = {"(no eggs)"} end
    return out
end

-- รวบรวม Mutations/FX
function DataProviders.collectMutations()
    local set, out = {["None"] = true}, {"None"}
    local function add(x)
        if not x or x == "Money" or x == "EatFruit" or x == "DinoEgg" or x == "Dino Egg" or x == "Electric" or x == "SnowEgg" or x == "Snow Egg" then return end
        if x == "Dino" then x = "Jurassic" end
        if not set[x] then 
            set[x] = true
            table.insert(out, x) 
        end
    end
    
    local rp = DataProviders.getResourcePull()
    if rp then
        for _, d in ipairs(rp:GetDescendants()) do
            local function try(val)
                if type(val) == "string" and val:find("^FX/FX_") then 
                    add(val:match("^FX/FX_(.+)")) 
                end
            end
            try(d.Name)
            if (d:IsA("TextLabel") or d:IsA("TextButton")) then 
                try(d.Text) 
            end
        end
    end
    
    for _, k in ipairs({"Golden", "Fire", "Diamond", "Jurassic"}) do 
        add(k) 
    end
    table.sort(out, function(a, b) 
        if a == "None" then return true 
        elseif b == "None" then return false 
        else return a < b end 
    end)
    return out
end

-- รวบรวมเหยื่อตกปลาจาก ResourcePull
function DataProviders.collectFishingBaits()
    local out, seen = {}, {}
    local function add(name)
        if type(name) ~= "string" then return end
        local trimmed = name:gsub("^%s+", ""):gsub("%s+$", "")
        if #trimmed == 0 then return end
        if not seen[trimmed] then 
            seen[trimmed] = true
            table.insert(out, trimmed) 
        end
    end

    local rp = DataProviders.getResourcePull()
    if not rp then
        return {"FishingBait1"} -- fallback ถ้ายังไม่โหลด
    end

    for _, d in ipairs(rp:GetDescendants()) do
        -- ลองทั้ง Name และ Text
        local raw1 = d.Name
        local raw2 = (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text or nil
        for _, raw in ipairs({raw1, raw2}) do
            if type(raw) == "string" and raw:find("/") then
                local after = raw:match(".*/(.+)")
                if after and (after:lower():find("bait") or after:match("^FishingBait%d+$")) then
                    add(after)
                end
            end
        end
    end

    table.sort(out)
    if #out == 0 then out = {"FishingBait1"} end
    return out
end

--========================================================
-- 7. SYSTEM INITIALIZATION
--========================================================

-- เริ่มต้น Fruit Shop Primer
local function initializeFruitShopPrimer()
    task.defer(function()
        local ok = pcall(function()
            local pg = LocalPlayer and (LocalPlayer.PlayerGui or LocalPlayer:WaitForChild("PlayerGui", 5))
            if not pg then return end
            local gui = pg:FindFirstChild("ScreenFoodStore")
            if not gui then return end

            local prev = gui.Enabled
            gui.Enabled = true
            Services.RunService.Heartbeat:Wait()
            Services.RunService.Heartbeat:Wait()
            task.wait(0.05)
            gui.Enabled = prev
        end)
        if not ok then warn("[Xenitz] Fruit Shop primer skipped (safe).") end
    end)
end

-- เริ่มต้น Remotes
local function initializeRemotes()
    local remote = Services.ReplicatedStorage:FindFirstChild("Remote")
    if remote then
        Remotes.CharacterRE = remote:FindFirstChild("CharacterRE")
        Remotes.PetRE = remote:FindFirstChild("PetRE") 
        Remotes.FoodStoreRE = remote:FindFirstChild("FoodStoreRE")
        Remotes.GiftRE = remote:FindFirstChild("GiftRE")
        Remotes.FishingRE = remote:FindFirstChild("FishingRE")
    end
end

-- เริ่มต้น Rayfield
local function initializeRayfield()
    local RF, _err
    for _, url in ipairs(CONFIG.RAYFIELD_URLS) do
        local ok, lib = pcall(function() 
            return loadstring(game:HttpGet(url))() 
        end)
        if ok and type(lib) == "table" and type(lib.CreateWindow) == "function" then 
            RF = lib
            break 
        end
        _err = lib
    end
    assert(RF, "Rayfield load failed: " .. tostring(_err))
    
    local window = RF:CreateWindow({
        Name = CONFIG.WINDOW_NAME,
        LoadingTitle = CONFIG.LOADING_TITLE,
        LoadingSubtitle = CONFIG.LOADING_SUBTITLE,
        DisableRayfieldPrompts = false,
        ConfigurationSaving = { Enabled = true, FileName = "XenitzConfig", FolderName = "Xenitz" }
    })
    RayfieldLibRef = RF
    return window
end

-- 8. FEATURE MODULES
-- Main Module
local MainModule = {}
function MainModule.initialize(tab)
    MainModule.initializeAutoCollect(tab)
    MainModule.initializeAntiAFK(tab)
    MainModule.initializeTeleport(tab)
    MainModule.initializeRecycle(tab)
end

function MainModule.initializeAutoCollect(tab)
    UI.createSection(tab, "Money")
    
    local function stopLoop()
        State.autoCollect.on = false
        State.autoCollect.thread = Utils.stopThread(State.autoCollect.thread)
    end
    
    local function runLoop()
        while State.autoCollect.on do
            pcall(function()
                local petsFolder = Services.Workspace:FindFirstChild("Pets")
                if not petsFolder then return end
                
                for _, item in ipairs(petsFolder:GetChildren()) do
                    local rp = item:FindFirstChild("RootPart")
                    if not rp then continue end
                    
                    local re = rp:FindFirstChild("RE") or rp:FindFirstChildWhichIsA("RemoteEvent")
                    if re and re.FireServer then
                        pcall(function() re:FireServer("Claim") end)
                        task.wait(0.05)
                    end
                end
            end)
            task.wait(CONFIG.AUTO_COLLECT_DELAY)
        end
    end
    
    UI.createToggle(tab, {
        Name = "Auto Collect",
        CurrentValue = false,
        Default = false,
        Flag = "_AutoCollect_Live",
        Callback = function(state)
            if state then
                stopLoop()
                State.autoCollect.on = true
                State.autoCollect.thread = task.spawn(runLoop)
            else
                stopLoop()
            end
        end
    })
end

function MainModule.initializeAntiAFK(tab)
    UI.createSection(tab, "AFK")

    local antiOn = false
    local keeperThread

    local function stopKeeper()
        if keeperThread then
            pcall(task.cancel, keeperThread)
            keeperThread = nil
        end
    end

local function jumpOnce()
    -- ส่ง Spacebar + สำรองสั่ง Humanoid กระโดด (อิงวิธีในไฟล์เดิมที่เวิร์กทุกเครื่อง)
    local vim = game:GetService("VirtualInputManager")
    pcall(function()
        vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.06)
        vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end)
    pcall(function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Jump = true
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

    UI.createToggle(tab, {
        Name = "Anti AFK",
        CurrentValue = false,
        Flag = "Xenitz_AntiAFK",
        Callback = function(v)
            antiOn = v
            stopKeeper()

            if v then
                keeperThread = task.spawn(function()
                    while antiOn do
                        jumpOnce()
                        -- ดีเลย์ 15 นาที
                        for i = 1, 900 do
                            if not antiOn then break end
                            task.wait(1)
                        end
                    end
                end)
            end
        end
    })
end

function MainModule.initializeTeleport(tab)
    UI.createSection(tab, "Teleport")
    
    local labelToId = {}
    local selectedUserId = nil
    
    local function buildOptions()
        table.clear(labelToId)
        local opts = {}
        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local label = plr.Name
                labelToId[label] = plr.UserId
                table.insert(opts, label)
            end
        end
        table.sort(opts)
        if #opts == 0 then
            opts = {"<no players>"}
            selectedUserId = nil
        end
        return opts
    end
    
    local options = buildOptions()
    local currentLabel = (options[1] ~= "<no players>") and options[1] or nil
    if currentLabel then selectedUserId = labelToId[currentLabel] end
    
    local tpDropdown = UI.createDropdown(tab, {
        Name = "Select Player",
        Options = options,
        CurrentOption = currentLabel or options[1],
        Callback = function(v)
            local lbl = Utils.normalizeChoice(v)
            if lbl and labelToId[lbl] then
                selectedUserId = labelToId[lbl]
            else
                selectedUserId = nil
            end
        end
    })
    
    local function refreshDropdown()
        local oldId = selectedUserId
        local opts = buildOptions()
        
        if tpDropdown and tpDropdown.Refresh then
            tpDropdown:Refresh(opts, true)
        end
        
        if oldId then
            local keepLabel = nil
            for lbl, uid in pairs(labelToId) do
                if uid == oldId then keepLabel = lbl break end
            end
            if keepLabel and tpDropdown and tpDropdown.Set then
                pcall(function() tpDropdown:Set(keepLabel) end)
                selectedUserId = oldId
                return
            end
        end
        
        local first = opts[1]
        if first and first ~= "<no players>" then
            selectedUserId = labelToId[first]
            if tpDropdown and tpDropdown.Set then 
                pcall(function() tpDropdown:Set(first) end) 
            end
        else
            selectedUserId = nil
        end
    end
    
    UI.createButton(tab, {
        Name = "Refresh Players",
        Callback = refreshDropdown
    })
    
    UI.createButton(tab, {
        Name = "Teleport To Player",
        Callback = function()
            local uid = selectedUserId
            if not uid then return end
            
            local target = Services.Players:GetPlayerByUserId(uid)
            if not target then refreshDropdown(); return end
            
            local myChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local tgtChar = target.Character or target.CharacterAdded:Wait()
            if not (myChar and tgtChar) then return end
            
            local myHRP = myChar:FindFirstChild("HumanoidRootPart")
            local tgtHRP = tgtChar:FindFirstChild("HumanoidRootPart")
            if not (myHRP and tgtHRP) then return end
            
            local pos = tgtHRP.Position + Vector3.new(0, 3, 0)
            local look = tgtHRP.CFrame.LookVector
            local cf = CFrame.new(pos, pos + look)
            
            pcall(function()
                myChar:PivotTo(cf)
                myHRP.AssemblyLinearVelocity = Vector3.zero
                myHRP.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    })
    
    Services.Players.PlayerAdded:Connect(refreshDropdown)
    Services.Players.PlayerRemoving:Connect(refreshDropdown)
end

function MainModule.initializeRecycle(tab)
    UI.createSection(tab, "Recycle")

	local function listCollectablePetIds()
		local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
		local data = pg and pg:FindFirstChild("Data")
		local pets = data and data:FindFirstChild("Pets")
		local out = {}
		if not pets then return out end
		for _, ch in ipairs(pets:GetChildren()) do
			local hasBUNQ = (ch:FindFirstChild("BUNQ", true) ~= nil)
			if not hasBUNQ then
				table.insert(out, ch.Name)
			end
		end
		return out
	end

	UI.createButton(tab, {
		Name = "Collect All Pets",
		Callback = function()
			local ids = listCollectablePetIds()
			for _, pid in ipairs(ids) do
				-- ส่งรูปแบบตามที่ระบุ: {"Del", pid} → FireServer(unpack(args))
				local args = {"Del", pid}
				local ok = pcall(function()
					Remotes.CharacterRE:FireServer(unpack(args))
				end)
				if not ok then
					-- fallback ใช้ Utils.safeFire ตามสไตล์โค้ดหลัก
					Utils.safeFire(Remotes.CharacterRE, "Del", pid)
				end
				task.wait(0.05)
			end
		end
	})
end

-- Fruit Shop Module
local FruitShopModule = {}
function FruitShopModule.initialize(tab)
    FruitShopModule.initializeBuy(tab)
    FruitShopModule.initializeFruitSelection(tab)
end

function FruitShopModule.initializeBuy(tab)
    UI.createSection(tab, "Buy")
    
    local function stopAutoBuy()
        State.fruitShop.autoBuy.on = false
        State.fruitShop.autoBuy.thread = Utils.stopThread(State.fruitShop.autoBuy.thread)
    end
    
    local function stopAutoBuyAll()
        State.fruitShop.autoBuyAll.on = false
        State.fruitShop.autoBuyAll.thread = Utils.stopThread(State.fruitShop.autoBuyAll.thread)
    end
    
    local function loopAutoBuy()
        while State.fruitShop.autoBuy.on do
            if Remotes.FoodStoreRE then
                for name, on in pairs(State.fruitShop.selectedFruits) do
                    if on and DataProviders.isFruitInStock(name) then
                        Utils.safeFire(Remotes.FoodStoreRE, name)
                        task.wait(CONFIG.BUY_DELAY)
                    else
                        task.wait(0.05)
                    end
                end
            end
            task.wait(CONFIG.LOOP_DELAY)
        end
    end
    
    local function loopAutoBuyAll()
        while State.fruitShop.autoBuyAll.on do
            local ordered = DataProviders.getFruitsOrderedByShop()
            if Remotes.FoodStoreRE and #ordered > 0 then
                for _, n in ipairs(ordered) do
                    if DataProviders.isFruitInStock(n) then
                        Utils.safeFire(Remotes.FoodStoreRE, n)
                        task.wait(CONFIG.BUY_DELAY)
                    else
                        task.wait(0.05)
                    end
                end
            end
            task.wait(CONFIG.LOOP_DELAY)
        end
    end
    
    UI.createToggle(tab, {
        Name = "Auto Buy",
        CurrentValue = false,
        Flag = "Xenitz_AutoBuy",
        Callback = function(on)
            if on then
                if State.fruitShop.autoBuyAll.on then stopAutoBuyAll() end
                stopAutoBuy()
                State.fruitShop.autoBuy.on = true
                State.fruitShop.autoBuy.thread = task.spawn(loopAutoBuy)
            else
                stopAutoBuy()
            end
        end
    })
    
    UI.createToggle(tab, {
        Name = "Auto Buy All",
        CurrentValue = false,
        Flag = "Xenitz_AutoBuyAll",
        Callback = function(on)
            if on then
                if State.fruitShop.autoBuy.on then stopAutoBuy() end
                stopAutoBuyAll()
                State.fruitShop.autoBuyAll.on = true
                State.fruitShop.autoBuyAll.thread = task.spawn(loopAutoBuyAll)
            else
                stopAutoBuyAll()
            end
        end
    })
end

function FruitShopModule.initializeFruitSelection(tab)
    UI.createSection(tab, "Fruit")
    
    local PLACEHOLDER = "(open the shop to load fruits)"
    local dd
    
    local function selectedList()
        local t = {}
        for n, on in pairs(State.fruitShop.selectedFruits) do 
            if on then table.insert(t, n) end 
        end
        return t
    end
    
    local function refreshFruitsDropdown()
        local opts = DataProviders.getFruitsOrderedByShop()
        if #opts == 0 then opts = {PLACEHOLDER} end
        
        if dd and dd.Refresh then
            pcall(function() dd:Refresh(opts, true) end)
            local keep = {}
            for _, n in ipairs(opts) do 
                if State.fruitShop.selectedFruits[n] then 
                    keep[n] = true 
                end 
            end
            State.fruitShop.selectedFruits = keep
        else
            dd = UI.createDropdown(tab, {
                Name = "Select Fruit",
                Options = opts,
                CurrentOption = selectedList(),
                MultipleOptions = true,
                MultiSelect = true,
                MultiSelection = true,
                Flag = "Xenitz_FruitMulti",
                Callback = function(v)
                    local picked = {}
                    if type(v) == "table" then
                        for _, n in ipairs(v) do 
                            if n ~= PLACEHOLDER then 
                                picked[n] = true 
                            end 
                        end
                    elseif type(v) == "string" and v ~= "" and v ~= PLACEHOLDER then
                        picked[v] = true
                    end
                    State.fruitShop.selectedFruits = picked
                end
            })
        end
    end
    
    refreshFruitsDropdown()
end

-- Big Pets Module
local BigPetsModule = {}
function BigPetsModule.initialize(tab)
    BigPetsModule.initializeAutoFeed(tab)
    BigPetsModule.initializeSelectPets(tab)
    BigPetsModule.initializeFruitSelection(tab)
end

function BigPetsModule.initializeAutoFeed(tab)
    UI.createSection(tab, "Auto Feed")
    
    local function selectedPetIDs()
        local ids = {}
        if State.bigPets.petLand1.on and State.bigPets.petLand1.id then 
            table.insert(ids, State.bigPets.petLand1.id) 
        end
        if State.bigPets.petLand2.on and State.bigPets.petLand2.id then 
            table.insert(ids, State.bigPets.petLand2.id) 
        end
        if State.bigPets.petWater1.on and State.bigPets.petWater1.id then 
            table.insert(ids, State.bigPets.petWater1.id) 
        end
        return ids
    end
    
    local function fruitsToFeedList()
        local t = {}
        for n, on in pairs(State.bigPets.selectedFruits) do 
            if on then table.insert(t, n) end 
        end
        table.sort(t)
        return t
    end
    
    local function loopAutoFeed()
        while State.bigPets.autoFeed.on do
            local pets = selectedPetIDs()
            local foods = fruitsToFeedList()
            if #pets == 0 or #foods == 0 then
                task.wait(CONFIG.LOOP_IDLE_SLEEP)
            else
                for _, petId in ipairs(pets) do
                    for _, foodName in ipairs(foods) do
                        Utils.safeFire(Remotes.CharacterRE, "Focus", foodName)
                        task.wait(CONFIG.FOOD_FOCUS_DELAY)
                        Utils.safeFire(Remotes.PetRE, "Feed", petId)
                        task.wait(CONFIG.FEED_GAP)
                    end
                end
            end
        end
    end
    
    UI.createToggle(tab, {
        Name = "Auto Feed",
        CurrentValue = State.bigPets.autoFeed.on,
        Flag = "Xenitz_AutoFeed",
        Callback = function(on)
            if on then
                State.bigPets.autoFeed.thread = Utils.stopThread(State.bigPets.autoFeed.thread)
                State.bigPets.autoFeed.on = true
                State.bigPets.autoFeed.thread = task.spawn(loopAutoFeed)
            else
                State.bigPets.autoFeed.on = false
                State.bigPets.autoFeed.thread = Utils.stopThread(State.bigPets.autoFeed.thread)
            end
        end
    })
end

function BigPetsModule.initializeSelectPets(tab)
    UI.createSection(tab, "Select Pets")
    
    local function pickLand1Land2()
        local land = select(1, DataProviders.listLandAndWaterPets())
        return land[1], land[2]
    end
    
    local function pickWater1()
        local _, water = DataProviders.listLandAndWaterPets()
        return water[1]
    end
    
    UI.createToggle(tab, {
        Name = "Pet Land 1",
        CurrentValue = State.bigPets.petLand1.on,
        Flag = "Xenitz_PetLand1",
        Callback = function(on)
            State.bigPets.petLand1.on = on
            if on then
                local p1 = pickLand1Land2()
                State.bigPets.petLand1.id = p1
            else
                State.bigPets.petLand1.id = nil
            end
        end
    })
    
    UI.createToggle(tab, {
        Name = "Pet Land 2",
        CurrentValue = State.bigPets.petLand2.on,
        Flag = "Xenitz_PetLand2",
        Callback = function(on)
            State.bigPets.petLand2.on = on
            if on then
                local _, p2 = pickLand1Land2()
                if p2 == State.bigPets.petLand1.id then
                    local land = select(1, DataProviders.listLandAndWaterPets())
                    for _, id in ipairs(land) do 
                        if id ~= State.bigPets.petLand1.id then 
                            p2 = id 
                            break 
                        end 
                    end
                end
                State.bigPets.petLand2.id = p2
            else
                State.bigPets.petLand2.id = nil
            end
        end
    })
    
    UI.createToggle(tab, {
        Name = "Pet Water 1",
        CurrentValue = State.bigPets.petWater1.on,
        Flag = "Xenitz_PetWater1",
        Callback = function(on)
            State.bigPets.petWater1.on = on
            if on then 
                State.bigPets.petWater1.id = pickWater1() 
            else 
                State.bigPets.petWater1.id = nil 
            end
        end
    })
end

function BigPetsModule.initializeFruitSelection(tab)
    UI.createSection(tab, "Fruit")
    
    local function selectedFruitList()
        local t = {}
        for n, on in pairs(State.bigPets.selectedFruits) do 
            if on then table.insert(t, n) end 
        end
        return t
    end
    
    local function buildFruitOptions()
        local opts = DataProviders.getFruitsOrderedByShop()
        if #opts == 0 then opts = {"(open the shop to load fruits)"} end
        return opts
    end
    
    local ddFruit = UI.createDropdown(tab, {
        Name = "Select Fruit",
        Options = buildFruitOptions(),
        CurrentOption = selectedFruitList(),
        MultipleOptions = true,
        MultiSelect = true,
        MultiSelection = true,
        Flag = "Xenitz_BigPets_Fruits",
        Callback = function(v)
            local picked = {}
            if type(v) == "table" then
                for _, n in ipairs(v) do 
                    if n and n ~= "" and n ~= "(open the shop to load fruits)" then 
                        picked[n] = true 
                    end 
                end
            elseif type(v) == "string" and v ~= "" and v ~= "(open the shop to load fruits)" then
                picked[v] = true
            end
            State.bigPets.selectedFruits = picked
        end
    })
end

-- Egg Module
local EggModule = {}
function EggModule.initialize(tab)
    EggModule.initializeBuy(tab)
    EggModule.initializeSelectEgg(tab)
    EggModule.initializeHatch(tab)
	EggModule.initializePlace(tab)
end

function EggModule.initializeBuy(tab)
    UI.createSection(tab, "Buy")
    
    UI.createToggle(tab, {
        Name = "Auto Buy",
        CurrentValue = false,
        Flag = "Xenitz_Egg_AutoBuy",
        Callback = function(v) 
            State.egg.autoBuy.on = v 
        end
    })
    
    -- Auto buy loop
    task.spawn(function()
        local lastAtByUID = {}
        while true do
            if State.egg.autoBuy.on then
                local list = EggModule.getSelectedEggsInOrder()
                if #list == 0 then
                    task.wait(0.25)
                else
                    for _, eggName in ipairs(list) do
                        local uid = EggModule.scanUID(eggName, State.egg.selectedMutation)
                        if uid then
                            local now = os.clock()
                            local last = lastAtByUID[uid] or 0
                            if (now - last) > 0.9 then
                                if EggModule.fireBuy(uid) then
                                    lastAtByUID[uid] = now
                                    task.wait(0.35)
                                end
                            end
                        end
                        task.wait(0.10)
                    end
                end
            end
            task.wait(0.20)
        end
    end)
end

function EggModule.initializeHatch(tab)
    UI.createSection(tab, "Hatch")

    EggModule._hatchOn, EggModule._hatchThread = false, nil

    local function stop()
        EggModule._hatchOn = false
        EggModule._hatchThread = Utils.stopThread(EggModule._hatchThread)
    end

    UI.createToggle(tab, {
        Name = "Auto Hatch",
        CurrentValue = false,
        Callback = function(on)
            EggModule._hatchOn = on
            EggModule._hatchThread = Utils.stopThread(EggModule._hatchThread)
            if on then
                EggModule._hatchThread = task.spawn(function()
                    while EggModule._hatchOn do
                        local list = EggModule.hatch_findReady()
                        if #list == 0 then
                            task.wait(0.20)
                        else
                            for _, f in ipairs(list) do
                                if not EggModule._hatchOn then break end
                                pcall(EggModule.hatch_hatchOne, f)
                            end
                        end
                    end
                end)
            end
        end
    })
end

-- Hatch helpers (scoped under EggModule)
function EggModule.hatch_promptsIn(folder)
    local t = {}
    for _, d in ipairs(folder:GetDescendants()) do
        if d:IsA("ProximityPrompt") then table.insert(t, d) end
    end
    return t
end

-- Place Section (Auto Place Eggs)
function EggModule.initializePlace(tab)
	UI.createSection(tab, "Place")

	EggModule._placeOn, EggModule._placeThread = false, nil

	local function stop()
		EggModule._placeOn = false
		EggModule._placeThread = Utils.stopThread(EggModule._placeThread)
	end

	UI.createToggle(tab, {
		Name = "Auto Place",
		CurrentValue = false,
		Callback = function(on)
			if on then
				stop()
				EggModule._placeOn = true
				EggModule._placeThread = task.spawn(function()
					while EggModule._placeOn do
						local id = EggModule.place_pickOneToPlace()
						if id then
							EggModule.place_placeID(id)
							task.wait(0.20)
						else
							task.wait(0.50)
						end
					end
				end)
			else
				stop()
			end
		end
	})
end

-- Helpers for Place
function EggModule.place_getEggRoot()
	local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
	local data = pg and pg:FindFirstChild("Data")
	return data and data:FindFirstChild("Egg") or nil
end

function EggModule.place_readAttrDeep(inst, key)
	local v = inst and inst.GetAttribute and inst:GetAttribute(key)
	if v ~= nil then return tostring(v) end
	for _, d in ipairs(inst:GetDescendants()) do
		if d.GetAttribute then
			local a = d:GetAttribute(key)
			if a ~= nil then return tostring(a) end
		end
	end
	return ""
end

function EggModule.place_collectEggs()
	local root = EggModule.place_getEggRoot()
	local list = {}
	if not root then return list end
	for _, ch in ipairs(root:GetChildren()) do
		local placed = (ch:FindFirstChild("DI", true) ~= nil)
		local T = EggModule.place_readAttrDeep(ch, "T"); if T == "" then T = "Unknown" end
		local M = EggModule.place_readAttrDeep(ch, "M"); if M == "" then M = "Base" end
		table.insert(list, { id = ch.Name, inst = ch, placed = placed, T = T, M = M })
	end
	return list
end

local function place_mapMutationUIToData(m)
	if not m or m == "None" then return "Base" end
	if m == "Jurassic" then return "Dino" end
	return m
end

function EggModule.place_pickOneToPlace()
	local selectedMutationUI = State and State.egg and State.egg.selectedMutation or "None"
	local needM = place_mapMutationUIToData(selectedMutationUI)
	local selectedEggs = EggModule.getSelectedEggsInOrder and EggModule.getSelectedEggsInOrder() or {}
	if #selectedEggs == 0 then return nil end

	local list = EggModule.place_collectEggs()
	for _, wantedT in ipairs(selectedEggs) do
		for _, e in ipairs(list) do
			if (not e.placed) and e.T == wantedT and (e.M == needM) then
				return e.id
			end
		end
	end
	return nil
end

function EggModule.place_computeDST()
	local WS = Services.Workspace
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local base = (hrp and hrp.Position) or Vector3.new(0, 16, 0)
	local look = (hrp and hrp.CFrame.LookVector) or Vector3.new(0, 0, -1)
	local right = (hrp and hrp.CFrame.RightVector) or Vector3.new(1, 0, 0)

	local GROUND_UP_OFFSET = 0.15
	local SIDE_OFFSET = 1.0
	local RAY_UP, RAY_DOWN = 12, 60

	local rayParams
	local function mk()
		if rayParams then return rayParams end
		rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = {char}
		return rayParams
	end

	local function groundAt(pos)
		local start = pos + Vector3.new(0, RAY_UP, 0)
		local dir = Vector3.new(0, - (RAY_UP + RAY_DOWN), 0)
		local hit = WS:Raycast(start, dir, mk())
		if hit then return hit.Position + Vector3.new(0, GROUND_UP_OFFSET, 0) end
		return pos
	end

	local candidates = {
		base,
		base + look * SIDE_OFFSET,
		base - look * SIDE_OFFSET,
		base + right * SIDE_OFFSET,
		base - right * SIDE_OFFSET,
	}
	local g = groundAt(candidates[1])
	local vc = (FishingModule and FishingModule.getVectorCreate and FishingModule.getVectorCreate()) or nil
	if vc then return vc(g.X, g.Y, g.Z) end
	return Vector3.new(g.X, g.Y, g.Z)
end

function EggModule.place_placeID(id)
	if not Remotes.CharacterRE then return false end
	Remotes.CharacterRE:FireServer("Focus", id)
	task.wait(0.20)
	pcall(function()
		Remotes.CharacterRE:FireServer("Place", { DST = EggModule.place_computeDST(), ID = id })
	end)
	task.wait(0.15)
	Remotes.CharacterRE:FireServer("Focus")
	return true
end

function EggModule.hatch_firePromptFar(p)
    if not p then return false end
    if typeof(fireproximityprompt) == "function" then
        local ok = pcall(function() fireproximityprompt(p, 1) end)
        if ok then return true end
    end
    local old = {Enabled = p.Enabled, Hold = p.HoldDuration, Dist = p.MaxActivationDistance, Sight = p.RequiresLineOfSight}
    p.Enabled = true
    p.HoldDuration = 0
    p.MaxActivationDistance = math.huge
    p.RequiresLineOfSight = false
    local ok2 = pcall(function() p:InputHoldBegin(); task.wait(0.05); p:InputHoldEnd() end)
    p.Enabled = old.Enabled; p.HoldDuration = old.Hold; p.MaxActivationDistance = old.Dist; p.RequiresLineOfSight = old.Sight
    return ok2
end

function EggModule.hatch_findReady()
    local root = Services.Workspace:FindFirstChild("PlayerBuiltBlocks")
    local out = {}
    if not root then return out end

    local myId = (LocalPlayer and LocalPlayer.UserId) or 0

    for _, f in ipairs(root:GetChildren()) do
        -- อ่าน UserId จากแปลง (รองรับอยู่บนโหนดลูกหลาน)
        local ownerId = nil
        if f.GetAttribute then
            local v = f:GetAttribute("UserId")
            if v ~= nil then ownerId = tonumber(v) end
        end
        if ownerId == nil then
            for _, d in ipairs(f:GetDescendants()) do
                if d.GetAttribute then
                    local v = d:GetAttribute("UserId")
                    if v ~= nil then ownerId = tonumber(v); break end
                end
            end
        end

        if ownerId == myId then
            local ex = f:FindFirstChild("ExclamationMark", true)
            if ex then table.insert(out, f) end
        end
    end
    return out
end

function EggModule.hatch_hatchOne(folder)
    for _, p in ipairs(EggModule.hatch_promptsIn(folder)) do
        if EggModule.hatch_firePromptFar(p) then
            task.wait(0.25)
            return true
        end
    end
    -- Fallback: press E briefly
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.06)
        vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
    task.wait(0.15)
    return true
end

function EggModule.initializeSelectEgg(tab)
    UI.createSection(tab, "Select Egg")
    
    local eggList = DataProviders.collectAllEggNames()
    local fxList = DataProviders.collectMutations()
    
    State.egg.selectedMutation = fxList[1]
    
    function EggModule.getSelectedEggsInOrder()
        local out = {}
        for _, name in ipairs(eggList) do
            if State.egg.selectedEggs[name] then 
                table.insert(out, name) 
            end
        end
        return out
    end
    
    local ddEgg = UI.createDropdown(tab, {
        Name = "Select Egg",
        Options = eggList,
        CurrentOption = {},
        MultipleOptions = true,
        MultiSelect = true,
        MultiSelection = true,
        Flag = "Xenitz_Egg_SelectEgg",
        Callback = function(v)
            State.egg.selectedEggs = {}
            for _, name in ipairs(Utils.toStringList(v)) do
                if name ~= "(no eggs)" then 
                    State.egg.selectedEggs[name] = true 
                end
            end
        end
    })
    
    UI.createDropdown(tab, {
        Name = "Select Mutation",
        Options = fxList,
        CurrentOption = State.egg.selectedMutation,
        MultipleOptions = false,
        Flag = "Xenitz_Egg_SelectMutation",
        Callback = function(v) 
            State.egg.selectedMutation = Utils.pickString(v) 
        end
    })
    
    -- Auto-refresh for initial loading
    task.spawn(function()
        for i = 1, 3 do
            task.wait(1.0)
            local prev = {}
            for n, on in pairs(State.egg.selectedEggs) do 
                if on then prev[n] = true end 
            end
            local newList = DataProviders.collectAllEggNames()
            local changed = (#newList ~= #eggList)
            if not changed then
                for i2 = 1, #newList do 
                    if newList[i2] ~= eggList[i2] then 
                        changed = true 
                        break 
                    end 
                end
            end
            if changed and ddEgg and ddEgg.Refresh then
                eggList = newList
                ddEgg:Refresh(newList, true)
                local reselect = {}
                for _, n in ipairs(newList) do 
                    if prev[n] then table.insert(reselect, n) end 
                end
                State.egg.selectedEggs = {}
                for _, n in ipairs(reselect) do 
                    State.egg.selectedEggs[n] = true 
                end
                if ddEgg.Set then 
                    pcall(function() ddEgg:Set(reselect) end) 
                end
            end
        end
    end)
end

-- Egg helper functions
function EggModule.scanUID(targetEgg, targetFX)
    local function normStr(s) 
        return s:lower():gsub("[%s%p_]+", "") 
    end
    local wantT = normStr(Utils.pickString(targetEgg))
    local fxUi = Utils.pickString(targetFX)
    local FX_ALIAS = { jurassic = "dino", dino = "dino" }
    local wantM = normStr((fxUi == "" or fxUi == "None") and "base" or (FX_ALIAS[normStr(fxUi)] or fxUi))
    
    local function roots()
        local t = {}
        local function add(r, tag) 
            if r then table.insert(t, {root = r, tag = tag}) end 
        end
        add(Services.ReplicatedStorage:FindFirstChild("Eggs"), "RS.Eggs")
        add(Services.ReplicatedStorage:FindFirstChild("Drops") and Services.ReplicatedStorage.Drops:FindFirstChild("Eggs"), "RS.Drops.Eggs")
        add(Services.Workspace:FindFirstChild("Eggs"), "WS.Eggs")
        add(Services.Workspace:FindFirstChild("Drops") and Services.Workspace.Drops:FindFirstChild("Eggs"), "WS.Drops.Eggs")
        return t
    end
    
    local bestUID, bestST, where, cnt = nil, math.huge, "(none)", 0
    for _, rr in ipairs(roots()) do
        for _, island in ipairs(rr.root:GetChildren()) do
            for _, ch in ipairs(island:GetChildren()) do
                local T = ch:GetAttribute("T")
                local M = ch:GetAttribute("M") or "Base"
                local UID = ch:GetAttribute("UID") or ch.Name
                local ST = tonumber(ch:GetAttribute("ST")) or math.huge
                if T and normStr(tostring(T)) == wantT then
                    if wantM == "base" or normStr(M) == wantM then
                        cnt = cnt + 1
                        if ST < bestST then 
                            bestUID, bestST, where = UID, ST, rr.tag .. "/" .. island.Name 
                        end
                    end
                end
            end
        end
        if cnt > 0 then break end
    end
    return bestUID, bestST, cnt, where
end

function EggModule.fireBuy(uid)
    local ok = pcall(function() 
        Remotes.CharacterRE:FireServer("BuyEgg", uid) 
    end)
    if not ok then 
        ok = pcall(function() 
            Remotes.CharacterRE:FireServer("BuyEgg", {UID = uid}) 
        end) 
    end
    return ok
end

-- Give Module
local GiveModule = {}
function GiveModule.initialize(tab)
    GiveModule.initializeGiveTo(tab)
    GiveModule.initializeSelectEgg(tab)
    GiveModule.initializeSelectFruit(tab)
    GiveModule.initializeWatchdog()
end

function GiveModule.initializeGiveTo(tab)
    UI.createSection(tab, "Give To")
    
    local function applySelection(v)
        if type(v) == "table" then v = v[1] end
        if v and v ~= "<no players>" and v ~= "" then
            State.give.selectedPlayerName = tostring(v)
            State.give.selectedPlayer = Services.Players:FindFirstChild(State.give.selectedPlayerName)
        else
            State.give.selectedPlayerName, State.give.selectedPlayer = nil, nil
        end
    end
    
    local opts = DataProviders.getOtherPlayers()
    applySelection(opts[1])
    
    UI.createToggle(tab, {
        Name = "Auto Give",
        CurrentValue = State.give.autoGive.on,
        Callback = function(on)
            State.give.autoGive.on = on
            
            if on then
                -- Start fruit holding if fruits are selected
                local anyFruit = false
                if type(State.give.selectedFruits) == "table" then
                    for _, v in pairs(State.give.selectedFruits) do 
                        if v then anyFruit = true break end 
                    end
                end
                if anyFruit then
                    pcall(GiveModule.ensureFruitHold)
                end
                
                -- Start egg holding if egg is selected
                if State.give.selectedEgg and State.give.selectedEgg ~= "None" then
                    pcall(GiveModule.startEggLoop)
                end
                
                -- Auto Give loop
                State.give.autoGive.thread = task.spawn(function()
                    while State.give.autoGive.on do
                        if State.give.selectedPlayer and State.give.selectedPlayer.Parent == Services.Players then
                            Utils.safeFire(Remotes.GiftRE, State.give.selectedPlayer)
                        end
                        task.wait(1.0)
                    end
                end)
            else
                -- Stop all holding loops when Auto Give is turned off
                pcall(GiveModule.stopFruitHold)
                pcall(GiveModule.stopEggLoop)
                State.give.autoGive.thread = Utils.stopThread(State.give.autoGive.thread)
            end
        end
    })
    
    local dd = UI.createDropdown(tab, {
        Name = "Select Player",
        Options = opts,
        CurrentOption = opts[1],
        Default = opts[1],
        Callback = applySelection
    })
    
    UI.createButton(tab, {
        Name = "Refresh Players",
        Callback = function()
            local newOpts = DataProviders.getOtherPlayers()
            if dd and dd.Refresh then dd:Refresh(newOpts, true) end
            if State.give.selectedPlayerName and table.find(newOpts, State.give.selectedPlayerName) then
                if dd and dd.Set then 
                    pcall(function() dd:Set(State.give.selectedPlayerName) end) 
                end
                State.give.selectedPlayer = Services.Players:FindFirstChild(State.give.selectedPlayerName)
            else
                if dd and dd.Set then 
                    pcall(function() dd:Set(newOpts[1]) end) 
                end
                applySelection(newOpts[1])
            end
        end
    })
end

function GiveModule.initializeSelectEgg(tab)
    UI.createSection(tab, "Select Egg")
    
    local function eggsFromPools()
        local pool = DataProviders.findEggPools()
        local set, out = {}, {}
        if pool then
            for _, ch in ipairs(pool:GetChildren()) do
                local n = ch.Name
                if n and not n:match("_W$") and not set[n] then 
                    set[n] = true
                    table.insert(out, n) 
                end
            end
        end
        table.sort(out)
        table.insert(out, 1, "None")
        return out
    end
    
    local ddEgg = UI.createDropdown(tab, {
        Name = "Select Egg",
        Options = {"None"},
        CurrentOption = "None",
        Callback = function(v)
            if type(v) == "table" then v = v[1] end
            State.give.selectedEgg = v or "None"
            if State.give.autoGive.on and State.give.selectedEgg ~= "None" then
                GiveModule.startEggLoop()
            end
            if State.give.selectedEgg == "None" then 
                GiveModule.stopEggLoop() 
            end
        end
    })
    
    local ddMut = UI.createDropdown(tab, {
        Name = "Select Mutation",
        Options = DataProviders.collectMutations(),
        CurrentOption = "None",
        Callback = function(v)
            if type(v) == "table" then v = v[1] end
            State.give.selectedMutation = v or "None"
            if State.give.autoGive.on and State.give.selectedEgg ~= "None" then
                GiveModule.startEggLoop()
            end
        end
    })
    
    -- Fill egg list once found
    task.spawn(function()
        for _ = 1, 15 do
            local opts = eggsFromPools()
            if #opts > 1 then 
                if ddEgg and ddEgg.Refresh then 
                    ddEgg:Refresh(opts, true) 
                end
                break 
            end
            task.wait(1)
        end
    end)
end

function GiveModule.initializeSelectFruit(tab)
    UI.createSection(tab, "Select Fruit")
    
    local PLACEHOLDER = "(open the shop to load fruits)"
    local dd
    
    local function selectedList()
        local t = {}
        for n, on in pairs(State.give.selectedFruits) do 
            if on then table.insert(t, n) end 
        end
        return t
    end
    
    local function refreshFruitsDropdown()
        local opts = DataProviders.getFruitsOrderedByShop()
        if #opts == 0 then opts = {PLACEHOLDER} end
        
        if dd and dd.Refresh then
            pcall(function() dd:Refresh(opts, true) end)
            local keep, any = {}, false
            for _, n in ipairs(opts) do
                if State.give.selectedFruits[n] then 
                    keep[n] = true
                    any = true 
                end
            end
            State.give.selectedFruits = keep
            if any then 
                GiveModule.ensureFruitHold() 
            else 
                GiveModule.stopFruitHold() 
            end
        else
            dd = UI.createDropdown(tab, {
                Name = "Select Fruit",
                Options = opts,
                CurrentOption = selectedList(),
                MultipleOptions = true,
                MultiSelect = true,
                MultiSelection = true,
                Flag = "Xenitz_Give_FruitMulti",
                Callback = function(v)
                    local picked, any, first = {}, false, nil
                    if type(v) == "table" then
                        for _, n in ipairs(v) do
                            if n and n ~= PLACEHOLDER then
                                picked[n] = true
                                any = true
                                if not first then first = n end
                            end
                        end
                    elseif type(v) == "string" and v ~= "" and v ~= PLACEHOLDER then
                        picked[v] = true
                        any = true
                        first = v
                    end
                    State.give.selectedFruits = picked
                    
                    if any then
                        if State.give.autoGive.on then
                            GiveModule.focusFruit(first)
                            GiveModule.ensureFruitHold()
                        end
                    else
                        GiveModule.focusFruit(nil)
                        GiveModule.stopFruitHold()
                    end
                end
            })
        end
    end
    
    refreshFruitsDropdown()
end

-- Give helper functions
function GiveModule.focusFruit(name)
    if not Remotes.CharacterRE then return end
    pcall(function()
        if name and name ~= "" then
            Remotes.CharacterRE:FireServer("Focus", name)
        else
            Remotes.CharacterRE:FireServer("Focus")
        end
    end)
end

function GiveModule.startEggLoop()
    if State.give.eggLoop.on then return end
    State.give.eggLoop.on = true
    State.give.eggLoop.thread = task.spawn(function()
        while State.give.eggLoop.on do
            if State.give.autoGive.on and State.give.selectedEgg ~= "None" then
                local id = GiveModule.pickOwnedEggID(State.give.selectedEgg, State.give.selectedMutation)
                if id then 
                    pcall(function() 
                        Remotes.CharacterRE:FireServer("Focus", id) 
                    end) 
                end
                task.wait(CONFIG.HOLD_STEP)
            else
                task.wait(0.3)
            end
        end
    end)
end

function GiveModule.stopEggLoop()
    State.give.eggLoop.on = false
    State.give.eggLoop.thread = Utils.stopThread(State.give.eggLoop.thread)
end

function GiveModule.ensureFruitHold()
    if State.give.fruitHold.on and State.give.fruitHold.thread then return end
    State.give.fruitHold.on = true
    State.give.fruitHold.thread = task.spawn(function()
        while State.give.fruitHold.on do
            if not State.give.autoGive.on then
                task.wait(0.3)
            else
                local list = GiveModule.selectedMapToListOrdered()
                if #list == 0 then
                    GiveModule.focusFruit(nil)
                    task.wait(0.6)
                else
                    for _, name in ipairs(list) do
                        if not State.give.fruitHold.on or not State.give.autoGive.on then break end
                        GiveModule.focusFruit(name)
                        task.wait(CONFIG.HOLD_STEP)
                    end
                end
            end
        end
    end)
end

function GiveModule.stopFruitHold()
    State.give.fruitHold.on = false
    State.give.fruitHold.thread = Utils.stopThread(State.give.fruitHold.thread)
end

function GiveModule.selectedMapToListOrdered()
    local sel = {}
    for n, on in pairs(State.give.selectedFruits) do 
        if on then table.insert(sel, n) end 
    end
    if #sel == 0 then return sel end
    local order, pos = DataProviders.getFruitsOrderedByShop(), {}
    for i, n in ipairs(order) do pos[n] = i end
    table.sort(sel, function(a, b) 
        return (pos[a] or 1e9) < (pos[b] or 1e9) 
    end)
    return sel
end

-- เลือก UID/Name ของไข่ในตัวผู้เล่นที่ตรงชนิดและมิวเทชัน
function GiveModule.pickOwnedEggID(Twant, MwantedUI)
    if not Twant or Twant == "None" then return nil end
    local function mapMutationUItoData(m)
        if not m or m == "None" then return "Base" end
        if m == "Jurassic" then return "Dino" end
        return m
    end
    local needM = mapMutationUItoData(MwantedUI)
    
    local function getEggRoot()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local data = pg and pg:FindFirstChild("Data")
        return data and data:FindFirstChild("Egg") or nil
    end
    
    local function readAttrDeep(inst, key)
        local v = inst:GetAttribute(key)
        if v ~= nil then return tostring(v) end
        for _, d in ipairs(inst:GetDescendants()) do
            if d.GetAttribute then 
                local a = d:GetAttribute(key)
                if a ~= nil then return tostring(a) end 
            end
        end
        return ""
    end
    
    local root = getEggRoot()
    if not root then return nil end
    local bestID, bestST = nil, math.huge
    for _, ch in ipairs(root:GetChildren()) do
        if not ch:FindFirstChild("DI", true) then
            local T = readAttrDeep(ch, "T")
            if T == "" then T = "Unknown" end
            local M = readAttrDeep(ch, "M")
            if M == "" then M = "Base" end
            if T == Twant and M == needM then
                local ST = tonumber(readAttrDeep(ch, "ST")) or math.huge
                if bestID == nil or ST < bestST then 
                    bestST, bestID = ST, ch.Name 
                end
            end
        end
    end
    return bestID
end

-- Watchdog system to monitor Auto Give state changes
function GiveModule.initializeWatchdog()
    -- ป้องกันการสร้าง watchdog ซ้ำ
    if _G.__Xenitz_give_watchdog_initialized then return end
    _G.__Xenitz_give_watchdog_initialized = true
    
    task.spawn(function()
        local prevAutoGive = State.give.autoGive.on
        while true do
            local nowAutoGive = State.give.autoGive.on
            if nowAutoGive and not prevAutoGive then
                -- Auto Give เพิ่งเปิด - เริ่มลูปถือไข่ถ้ามีไข่เลือกไว้
                if State.give.selectedEgg and State.give.selectedEgg ~= "None" then
                    pcall(GiveModule.startEggLoop)
                end
            elseif not nowAutoGive and prevAutoGive then
                -- Auto Give เพิ่งปิด - หยุดลูปถือไข่
                pcall(GiveModule.stopEggLoop)
            end
            prevAutoGive = nowAutoGive
            task.wait(0.25)
        end
    end)
end

-- Fishing Module
local FishingModule = {}
function FishingModule.initialize(tab)
    FishingModule.initializeFishing(tab)
end

-- ฟังก์ชันนี้สร้าง UI ตกปลาและเพิ่ม dropdown เลือกเหยื่อ
function FishingModule.initializeFishing(tab)
    UI.createSection(tab, "Fishing")
    
    -- Dropdown สำหรับเลือกเหยื่อตกปลา
    local baitOptions = DataProviders.collectFishingBaits()
    local currentBait = State.fishing.selectedBait or baitOptions[1] or "FishingBait1"
    State.fishing.selectedBait = currentBait
    UI.createDropdown(tab, {
        Name = "Select Bait",
        Options = baitOptions,
        CurrentOption = currentBait,
        MultipleOptions = false,
        Flag = "Xenitz_Bait",
        Callback = function(v)
            -- อัปเดตเหยื่อที่เลือกสำหรับระบบตกปลาอัตโนมัติ
            local picked = Utils.pickString(v)
            if picked and picked ~= "" then
                State.fishing.selectedBait = picked
            end
        end
    })
    
    -- Auto Fishing Toggle
    UI.createToggle(tab, {
        Name = "Auto Fishing",
        CurrentValue = State.fishing.autoFish.on,
        Callback = function(on)
            State.fishing.autoFish.on = on
            
            if on then
                FishingModule.startCFrameLock()
                State.fishing.autoFish.thread = task.spawn(function()
                    while State.fishing.autoFish.on do
                        FishingModule.singleFishingCycle()
                        if not State.fishing.autoFish.on then break end
                        task.wait(CONFIG.LOOP_PAUSE)
                    end
                end)
            else
                State.fishing.autoFish.thread = Utils.stopThread(State.fishing.autoFish.thread)
                FishingModule.stopCFrameLock()
            end
        end
    })
end

-- Fishing Helper Functions
function FishingModule.getVectorCreate()
    local ok, vec = pcall(function()
        return (getgenv and getgenv().vector)
            or (getrenv and getrenv().vector)
            or rawget(_G, "vector")
            or _G.vector
            or vector
    end)
    if ok and type(vec) == "table" and type(vec.create) == "function" then
        return vec.create
    end
    return nil
end

function FishingModule.computeForwardXYZ()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0, 10, 0 end
    local p = hrp.Position + hrp.CFrame.LookVector * CONFIG.CAST_DISTANCE
    return p.X, p.Y + CONFIG.Y_OFFSET_FROM_ME, p.Z
end

function FishingModule.throwRodForward()
    if not Remotes.FishingRE then return end
    
    local vc = FishingModule.getVectorCreate()
    local x, y, z = FishingModule.computeForwardXYZ()
    local bait = State.fishing.selectedBait or "FishingBait1"
    
    if vc then
        Utils.safeFire(Remotes.FishingRE, "Throw", { Bait = bait, Pos = vc(x, y, z) })
    else
        Utils.safeFire(Remotes.FishingRE, "Throw", { Bait = bait, Pos = Vector3.new(x, y, z) })
    end
end

function FishingModule.reelNow()
    if not Remotes.FishingRE then return end
    Utils.safeFire(Remotes.FishingRE, "POUT", { SUC = 1 })
end

function FishingModule.getFishingIcon()
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	local screen = pg and pg:FindFirstChild("ScreenFishing")
	-- เปลี่ยนไปใช้อ้างอิง PBar ตาม UI ใหม่; เผื่อไว้หากไม่มี ให้ fallback เป็น FishingIcon
	local pbar = screen and screen:FindFirstChild("PBar")
	if pbar then return pbar end
	return screen and screen:FindFirstChild("FishingIcon") or nil
end

function FishingModule.waitForFishingIconVisible(limitSeconds)
    local limit, t0 = limitSeconds or CONFIG.BITE_WAIT_LIMIT, os.clock()
    local icon
    while os.clock() - t0 < limit do
        icon = FishingModule.getFishingIcon()
        if icon then break end
        task.wait(CONFIG.POLL_INTERVAL)
    end
    if not icon then return false end
    while os.clock() - t0 < limit do
        if icon.Visible == true then return true end
        task.wait(CONFIG.POLL_INTERVAL)
    end
    return false
end

function FishingModule.waitForFishingIconHidden(limitSeconds)
    local limit, t0 = limitSeconds or CONFIG.ICON_RESET_LIMIT, os.clock()
    local icon = FishingModule.getFishingIcon()
    while os.clock() - t0 < limit do
        icon = icon or FishingModule.getFishingIcon()
        if icon and icon.Visible == false then return true end
        task.wait(0.05)
    end
    return false
end

function FishingModule.focusItem(itemName)
    if not Remotes.CharacterRE then return end
    Utils.safeFire(Remotes.CharacterRE, "Focus", itemName)
end

function FishingModule.unfocusItem()
    if not Remotes.CharacterRE then return end
    Utils.safeFire(Remotes.CharacterRE, "Focus")
end

function FishingModule.resetRodTwice()
    for i = 1, 2 do
        FishingModule.focusItem("FishRob")
        task.wait(0.2)
        FishingModule.unfocusItem()
        task.wait(0.2)
    end
end

function FishingModule.startCFrameLock()
    FishingModule.stopCFrameLock()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not (hrp and hum) then return end
    
    local lock = State.fishing.cframeLock
    lock.active, lock.hum, lock.cf = true, hum, hrp.CFrame
    
    local states = {
        Enum.HumanoidStateType.Ragdoll, 
        Enum.HumanoidStateType.FallingDown, 
        Enum.HumanoidStateType.GettingUp, 
        Enum.HumanoidStateType.Climbing, 
        Enum.HumanoidStateType.Jumping
    }
    lock.savedStates = {}
    for _, st in ipairs(states) do 
        lock.savedStates[st] = hum:GetStateEnabled(st)
        pcall(function() hum:SetStateEnabled(st, false) end) 
    end
    hum.AutoRotate = false
    hum.PlatformStand = true
    
    lock.con = Services.RunService.Heartbeat:Connect(function()
        if not lock.active then return end
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = lock.cf
        end)
    end)
end

function FishingModule.stopCFrameLock()
    local lock = State.fishing.cframeLock
    lock.active = false
    if lock.con then 
        lock.con:Disconnect() 
        lock.con = nil 
    end
    
    local hum = lock.hum
    if hum and hum.Parent then
        if lock.savedStates then
            for state, enabled in pairs(lock.savedStates) do 
                pcall(function() hum:SetStateEnabled(state, enabled) end) 
            end
        end
        hum.PlatformStand = false
        hum.AutoRotate = true
    end
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    
    lock.hum, lock.cf, lock.savedStates = nil, nil, nil
end

function FishingModule.singleFishingCycle()
    FishingModule.focusItem("FishRob")
    task.wait(CONFIG.EQUIP_HOLD_DELAY)
    
    FishingModule.throwRodForward()
    
    local gotBite = FishingModule.waitForFishingIconVisible(CONFIG.BITE_WAIT_LIMIT)
    if gotBite then
        FishingModule.reelNow()
        FishingModule.waitForFishingIconHidden(CONFIG.ICON_RESET_LIMIT)
    else
        FishingModule.resetRodTwice()
    end
end

-- Quest Module
local QuestModule = {}
function QuestModule.initialize(tab)
	QuestModule.initializeEvent(tab)
	QuestModule.initializeLikeSystem(tab)
end

function QuestModule.initializeLikeSystem(tab)
    UI.createSection(tab, "Like")
    
    -- ส่ง Like ให้ผู้เล่นคนอื่นทั้งหมดครั้งเดียว
    local function likeAllPlayersOnce()
        local remote = Remotes.CharacterRE
        if not remote then
            local r = Services.ReplicatedStorage:FindFirstChild("Remote")
            if r then remote = r:FindFirstChild("CharacterRE") end
        end
        if not remote then return end
        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local targetId = tonumber(plr.CharacterAppearanceId) or 0
                if targetId > 0 then
                    Utils.safeFire(remote, "GiveLike", targetId)
                    task.wait(0.05)
                end
            end
        end
    end
    
    UI.createButton(tab, {
        Name = "All Like",
        Callback = function()
            likeAllPlayersOnce()
        end
    })
end

function QuestModule.initializeEvent(tab)
	UI.createSection(tab, "Event")

    UI.createButton(tab, {
        Name = "Open Snow Quest",
		Callback = function()
			local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
			local scr = pg and pg:FindFirstChild("ScreenDinoEvent")
			if scr then
				pcall(function()
					scr.Enabled = true
				end)
			else
				warn("[Quest/Event] ScreenDinoEvent not found.")
			end
		end
	})

	UI.createButton(tab, {
		Name = "Open Snow Store",
		Callback = function()
			local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
			local scr = pg and pg:FindFirstChild("ScreenDinoStore")
			if scr then
				pcall(function()
					scr.Enabled = true
				end)
			else
				warn("[Quest/Event] ScreenDinoStore not found.")
			end
		end
	})
end

-- AllEgg Module
local AllEggModule = {}
function AllEggModule.initialize(tab)
    AllEggModule.initializeList(tab)
end

function AllEggModule.initializeList(tab)
    UI.createSection(tab, "List")
    
    -- Store tab reference for UI updates
    AllEggModule._currentTab = tab
    
    -- Create UI components
    AllEggModule.createRefreshButton(tab)
    
    -- Initial render
    task.defer(AllEggModule.refreshList)
end

-- UI Creation Functions
function AllEggModule.createRefreshButton(tab)
    UI.createButton(tab, {
        Name = "Refresh List",
        Callback = function()
            AllEggModule.refreshList()
        end
    })
end

-- Data Access Functions
function AllEggModule.getEggRoot()
    local pg = LocalPlayer and (LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 2))
    local data = pg and pg:FindFirstChild("Data")
    return data and data:FindFirstChild("Egg") or nil
end

function AllEggModule.readAttributeDeep(inst, key)
    if not inst then return "" end
    local v = inst:GetAttribute(key)
    if v ~= nil then return tostring(v) end
    for _, d in ipairs(inst:GetDescendants()) do
        if d.GetAttribute then
            local a = d:GetAttribute(key)
            if a ~= nil then return tostring(a) end
        end
    end
    return ""
end

function AllEggModule.formatMutationName(mutationName)
    if not mutationName or mutationName == "" or mutationName == "Base" then return nil end
    if mutationName == "Dino" then return "Jurassic" end
    return mutationName
end

-- Data Collection and Processing
function AllEggModule.collectEggData()
    local root = AllEggModule.getEggRoot()
    if not root then return {}, 0 end
    
    local counts = {}
    local totalCount = 0
    
    for _, eggInstance in ipairs(root:GetChildren()) do
        -- Skip eggs with DI (following GiveModule.pickOwnedEggID pattern)
        if not eggInstance:FindFirstChild("DI", true) then
            local eggType = AllEggModule.readAttributeDeep(eggInstance, "T")
            if eggType == "" then eggType = "Unknown" end
            
            local mutation = AllEggModule.readAttributeDeep(eggInstance, "M")
            if mutation == "" then mutation = "Base" end
            
            local key = eggType .. "\0" .. mutation
            counts[key] = (counts[key] or 0) + 1
            totalCount = totalCount + 1
        end
    end
    
    return counts, totalCount
end

function AllEggModule.formatEggLines(counts, totalCount)
    if totalCount == 0 then
        return {"(no eggs)", "", "All Egg 0"}
    end
    
    -- Sort by egg type, then by mutation
    local keys = {}
    for k in pairs(counts) do table.insert(keys, k) end
    table.sort(keys, function(a, b)
        local typeA, mutationA = a:match("^(.-)\0(.*)$")
        local typeB, mutationB = b:match("^(.-)\0(.*)$")
        if typeA ~= typeB then return typeA < typeB end
        return mutationA < mutationB
    end)
    
    local lines = {}
    for _, key in ipairs(keys) do
        local eggType, mutation = key:match("^(.-)\0(.*)$")
        local displayMutation = AllEggModule.formatMutationName(mutation)
        local count = counts[key]
        
        if displayMutation then
            table.insert(lines, string.format("%s [%s] %d", eggType, displayMutation, count))
        else
            table.insert(lines, string.format("%s %d", eggType, count))
        end
    end
    
    -- Add summary line
    table.insert(lines, "")
    table.insert(lines, string.format("All Egg %d", totalCount))
    
    return lines
end

-- UI Update Functions
function AllEggModule.refreshList()
    local counts, totalCount = AllEggModule.collectEggData()
    local lines = AllEggModule.formatEggLines(counts, totalCount)
    local displayText = table.concat(lines, "\n")
    
    AllEggModule.updateListDisplay(displayText)
end

function AllEggModule.updateListDisplay(text)
    if not AllEggModule._listParagraph then
        AllEggModule.createListParagraph(text)
    else
        AllEggModule.updateListParagraph(text)
    end
end

function AllEggModule.createListParagraph(text)
    pcall(function()
        if typeof(AllEggModule._currentTab.CreateParagraph) == "function" then
            AllEggModule._listParagraph = AllEggModule._currentTab:CreateParagraph({ Title = "All Egg", Content = text })
        elseif typeof(AllEggModule._currentTab.AddParagraph) == "function" then
            AllEggModule._listParagraph = AllEggModule._currentTab:AddParagraph({ Title = "All Egg", Content = text })
        end
    end)
end

function AllEggModule.updateListParagraph(text)
    pcall(function()
        if AllEggModule._listParagraph.Set then
            AllEggModule._listParagraph:Set({ Title = "All Egg", Content = text })
        else
            AllEggModule._listParagraph.Content = text
        end
    end)
end

--========================================================
-- 9. MAIN INITIALIZATION SYSTEM
--========================================================
local function main()
    -- 1. Initialize Fruit Shop Primer
    initializeFruitShopPrimer()
    
    -- 2. Initialize Services and Remotes
    initializeRemotes()
    
    -- 3. Initialize Rayfield
    local Window = initializeRayfield()
    
    -- 4. Create Tabs dynamically
    local Tabs = {} 
    for _, tabConfig in ipairs(CONFIG.TABS) do
        Tabs[tabConfig.name:gsub("%s+", "")] = Window:CreateTab(tabConfig.name, tabConfig.icon)
    end
    
    -- 5. Initialize Feature Modules
    MainModule.initialize(Tabs.Main)
    FruitShopModule.initialize(Tabs.FruitShop)
    BigPetsModule.initialize(Tabs.BigPets)
    EggModule.initialize(Tabs.Egg)
    GiveModule.initialize(Tabs.Give)
    FishingModule.initialize(Tabs.Fishing)
    QuestModule.initialize(Tabs.Quest)
	AllEggModule.initialize(Tabs.AllEgg)
    
    -- 6. Load saved configuration (restore Flags)
    pcall(function()
        if RayfieldLibRef and RayfieldLibRef.LoadConfiguration then
            RayfieldLibRef:LoadConfiguration()
        elseif Window and Window.LoadConfiguration then
            Window:LoadConfiguration()
        end
    end)
    
    print("Ready")
end


main()
