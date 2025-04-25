local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
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
local seaMarkers = {
    FirstSea = {"MarineStart", "MiddleTown", "Jungle", "QuestGiver1"},
    SecondSea = {"Cafe", "FountainCity", "KingdomOfRose", "QuestGiver2"},
    ThirdSea = {"TikiOutpost", "Mansion", "HauntedCastle", "QuestGiver3"}
}

-- Blox Fruits Mob List per Sea (example, adjust as needed)
local seaMobs = {
    FirstSea = {"Bandit", "Monkey", "Gorilla", "Greybeard"},
    SecondSea = {"Fishman Warrior", "Raider", "Chief Warden", "Dark Master"},
    ThirdSea = {"God’s Guard", "Sea Soldier", "Tiki Warrior", "Leviathan"}
}

-- Function to generate random delay for anti-ban
local function randomDelay(min, max)
    return math.random(min * 100, max * 100) / 100
end

-- Sea Detection Function
local function detectSea()
    for sea, markers in pairs(seaMarkers) do
        for _, marker in pairs(markers) do
            if Workspace:FindFirstChild(marker) or Workspace.NPCs:FindFirstChild(marker) then
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
            -- Filter mobs by current sea
            for _, seaMob in pairs(seaMobs[currentSea] or {}) do
                if mob.Name:find(seaMob) then
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
    if    if #mobNames > 0 then
        Options.MobDropdown:SetValue(mobNames[1])
    else
        Options.MobDropdown:SetValue(nil)
    end
end

-- Function to accept quest for selected mob
local function acceptQuest(mobName)
    local questRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("CommF_")
    if questRemote and questRemote:IsA("RemoteFunction") then
        -- Map mob to quest (example, adjust based on game)
        local questMapping = {
            ["Bandit"] = "BanditQuest",
            ["Greybeard"] = "GreybeardQuest",
            ["Fishman Warrior"] = "FishmanQuest",
            ["God’s Guard"] = "GodsGuardQuest"
        }
        local questName = questMapping[mobName] or "DefaultQuest"
        questRemote:InvokeServer("StartQuest", questName)
    end
end

-- Function to enable god mode and NoClip
local function enableGodMode()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = 50
        LocalPlayer.Character.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            LocalPlayer.Character.Humanoid.Health = LocalPlayer.Character.Humanoid.MaxHealth
        end)
    end
    -- NoClip
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
        acceptQuest(selectedMob)

        -- Randomized teleport with offset
        local offset = Vector3.new(math.random(-5, 5), 5, math.random(-5, 5))
        LocalPlayer.Character.HumanoidRootPart.CFrame = mobInstance.HumanoidRootPart.CFrame * CFrame.new(offset)
        task.wait(randomDelay(0.5, 1.5))

        -- Auto attack
        while autoFarmEnabled and mobInstance and mobInstance:FindFirstChildOfClass("Humanoid") and mobInstance.Humanoid.Health > 0 do
            local combatRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("Combat")
            if combatRemote and combatRemote:IsA("RemoteEvent") then
                combatRemote:FireServer("Attack", mobInstance)
            else
                mobInstance.Humanoid:TakeDamage(100)
            end
            task.wait(randomDelay(0.3, 0.7))
        end
    end

    isFarming = false
end

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
        currentSea = detectSea()
        SeaLabel:Set({ Title = "Current Sea", Content = currentSea })
        if autoFarmEnabled then
            updateMobDropdown()
        end
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
