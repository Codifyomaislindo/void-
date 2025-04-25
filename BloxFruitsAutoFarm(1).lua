local success, Fluent = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)
if not success then
    warn("Failed to load Fluent library")
    return
end

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "VoidLua " .. Fluent.Version,
    SubTitle = "by RodoMax",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    Esp = Window:AddTab({ Title = "Esp", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

Fluent:Notify({
    Title = "Notification",
    Content = "Muito obrigado por usarem nosso script!",
    SubContent = "♥️",
    Duration = 5
})

-- Auto Farm and Sea Detection Variables
local autoFarmEnabled = false
local selectedMob = nil
local mobList = {}
local isFarming = false
local currentSea = "Unknown"
local lastTeleportTime = 0
local seaMarkers = {
    FirstSea = {"MarineStart", "MiddleTown", "Jungle", "PirateVillage"},
    SecondSea = {"Cafe", "FountainCity", "KingdomOfRose", "GreenZone"},
    ThirdSea = {"TikiOutpost", "Mansion", "HauntedCastle", "SeaOfTreats"}
}
local seaMobs = {
    FirstSea = {"Bandit", "Monkey", "Gorilla", "Greybeard"},
    SecondSea = {"Swan Pirate", "Raider", "Factory Staff", "Dark Master"},
    ThirdSea = {"God’s Guard", "Sea Soldier", "Tiki Warrior", "Leviathan"}
}
local questMapping = {
    ["Bandit"] = {"BanditQuest1", 1},
    ["Monkey"] = {"JungleQuest1", 1},
    ["Gorilla"] = {"JungleQuest2", 1},
    ["Greybeard"] = {"MarineBossQuest", 1},
    ["Swan Pirate"] = {"SwanQuest1", 1},
    ["Raider"] = {"RaiderQuest1", 1},
    ["Factory Staff"] = {"FactoryQuest1", 1},
    ["Dark Master"] = {"DarkMasterQuest", 1},
    ["God’s Guard"] = {"SkyQuest1", 1},
    ["Sea Soldier"] = {"SeaSoldierQuest1", 1},
    ["Tiki Warrior"] = {"TikiQuest1", 1},
    ["Leviathan"] = {"LeviathanQuest", 1}
}

-- Function to generate random delay for anti-ban
local function randomDelay(min, max)
    return math.random(min * 100, max * 100) / 100
end

-- Sea Detection Function
local function detectSea()
    for sea, markers in pairs(seaMarkers) do
        for _, marker in pairs(markers) do
            if Workspace:FindFirstChild(marker) then
                return sea
            end
            local npcs = Workspace:FindFirstChild("NPCs")
            if npcs and npcs:FindFirstChild(marker) then
                return sea
            end
        end
    end
    return "Unknown"
end

-- Function to get nearby mobs sorted by distance
local function getNearbyMobs()
    local mobs = {}
    local playerPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
    if not playerPos then return mobs end

    local mobFolder = Workspace:FindFirstChild("Enemies") or Workspace
    for _, mob in pairs(mobFolder:GetChildren()) do
        local humanoid = mob:FindFirstChildOfClass("Humanoid")
        local rootPart = mob:FindFirstChild("HumanoidRootPart")
        if humanoid and rootPart and humanoid.Health > 0 then
            local distance = (playerPos - rootPart.Position).Magnitude
            for _, seaMob in pairs(seaMobs[currentSea] or {}) do
                if mob.Name == seaMob then
                    table.insert(mobs, { Name = mob.Name, Distance = distance, Instance = mob })
                    break
                end
            end
        end
    end

    table.sort(mobs, function(a, b) return a.Distance < b.Distance end)
    return mobs
end

-- Function to update mob dropdown
local function updateMobDropdown()
    mobList = getNearbyMobs()
    local mobNames = {}
    for _, mob in pairs(mobList) do
        table.insert(mobNames, string.format("%s (%.1f studs)", mob.Name, mob.Distance))
    end
    Options.MobDropdown:SetValues(mobNames)
    if #mobNames > 0 then
        Options.MobDropdown:SetValue(mobNames[1])
        selectedMob = mobNames[1]:match("^(.+) %(")
    else
        Options.MobDropdown:SetValue(nil)
        selectedMob = nil
    end
end

-- Function to accept quest for selected mob
local function acceptQuest(mobName)
    local questData = questMapping[mobName]
    if questData then
        local questRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
        if questRemote and questRemote:IsA("RemoteFunction") then
            pcall(function()
                questRemote:InvokeServer("StartQuest", questData[1], questData[2])
            end)
        end
    end
end

-- Function to equip melee weapon
local function equipMelee()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local character = LocalPlayer.Character
    if backpack and character then
        local combat = backpack:FindFirstChild("Combat")
        if combat then
            combat.Parent = character
        end
    end
end

-- Function to enable god mode and NoClip
local function enableGodMode()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = 50
        character.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            character.Humanoid.Health = character.Humanoid.MaxHealth
        end)
    end
end

-- NoClip Function
local function enableNoClip()
    RunService:BindToRenderStep("NoClip", Enum.RenderPriority.Character.Value, function()
        if autoFarmEnabled and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

-- Auto Farm Loop
local function autoFarmLoop()
    if not autoFarmEnabled or isFarming or not selectedMob or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    isFarming = true

    local mobInstance = nil
    for _, mob in pairs(mobList) do
        if mob.Name == selectedMob then
            mobInstance = mob.Instance
            break
        end
    end

    if mobInstance and mobInstance:FindFirstChild("HumanoidRootPart") and mobInstance:FindFirstChildOfClass("Humanoid") then
        pcall(function()
            acceptQuest(selectedMob)
            equipMelee()

            local currentTime = tick()
            local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
            local mobPos = mobInstance.HumanoidRootPart.Position
            local distance = (playerPos - mobPos).Magnitude
            if distance <= 100 and currentTime - lastTeleportTime >= 1 then
                local offset = Vector3.new(math.random(-5, 5), 5, math.random(-5, 5))
                LocalPlayer.Character.HumanoidRootPart.CFrame = mobInstance.HumanoidRootPart.CFrame * CFrame.new(offset)
                lastTeleportTime = currentTime
                task.wait(randomDelay(0.5, 1.5))
            end

            while autoFarmEnabled and mobInstance and mobInstance:FindFirstChildOfClass("Humanoid") and mobInstance.Humanoid.Health > 0 do
                UserInputService.InputBegan:Fire({ KeyCode = Enum.UserInputType.MouseButton1 }, false)
                task.wait(randomDelay(0.3, 0.7))
            end
        end)
    end

    isFarming = false
end

-- Handle character respawn
LocalPlayer.CharacterAdded:Connect(function(character)
    if autoFarmEnabled then
        enableGodMode()
        enableNoClip()
    end
end)

-- UI Elements
Tabs.Main:AddParagraph({
    Title = "Auto Farm - Blox Fruits",
    Content = "Farm mobs or bosses in the current sea!"
})

local SeaLabel = Tabs.Main:AddParagraph({
    Title = "Current Sea",
    Content = "Detecting..."
})

local AutoFarmToggle = Tabs.Main:AddToggle("AutoFarmToggle", {
    Title = "Enable Auto Farm",
    Default = false
})

AutoFarmToggle:OnChanged(function(value)
    autoFarmEnabled = value
    if autoFarmEnabled then
        enableGodMode()
        enableNoClip()
        updateMobDropdown()
        RunService:BindToRenderStep("AutoFarm", Enum.RenderPriority.Camera.Value, autoFarmLoop)
    else
        RunService:UnbindFromRenderStep("AutoFarm")
        RunService:UnbindFromRenderStep("NoClip")
    end
end)

local MobDropdown = Tabs.Main:AddDropdown("MobDropdown", {
    Title = "Select Mob/Boss",
    Values = {},
    Multi = false,
    Default = nil
})

MobDropdown:OnChanged(function(value)
    if value then
        selectedMob = value:match("^(.+) %(")
    else
        selectedMob = nil
    end
end)

-- Update sea and mob list periodically
task.spawn(function()
    while true do
        pcall(function()
            currentSea = detectSea()
            SeaLabel:Set({ Title = "Current Sea", Content = currentSea })
            if autoFarmEnabled then
                updateMobDropdown()
            end
        end)
        task.wait(5)
    end
end)

-- ESP for Fruits (Placeholder)
Tabs.Main:AddButton({
    Title = "ESP FRUTAS",
    Callback = function()
        Fluent:Notify({
            Title = "ESP Frutas",
            Content = "ESP for fruits enabled (placeholder).",
            Duration = 3
        })
    end
})

-- SaveManager and InterfaceManager Setup
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("FluentScriptHub")
SaveManager:SetFolder("FluentScriptHub/blox-fruits")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Fluent",
    Content = "Blox Fruits script loaded successfully!",
    Duration = 8
})

SaveManager:LoadAutoloadConfig()
