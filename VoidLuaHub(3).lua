-- VoidLua Hub para Blox Fruits
-- Script funcional com funcionalidades inspiradas no RedzHub, otimizado para dispositivos móveis

-- Serviços
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

-- Jogador Local
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 10)
local Humanoid = Character:WaitForChild("Humanoid", 10)

-- Função de Atraso Aleatório para Reduzir Detecção
local function RandomDelay(min, max)
    return wait(math.random(min * 100, max * 100) / 100)
end

-- Carregar Biblioteca Fluent e Addons
local Fluent = nil
local SaveManager = nil
local InterfaceManager = nil

local success, result = pcall(function()
    return loadstring(HttpService:GetAsync("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)
if success then
    Fluent = result
else
    error("Falha ao carregar a biblioteca Fluent. Verifique sua conexão ou executor.")
end

success, result = pcall(function()
    return loadstring(HttpService:GetAsync("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
end)
if success then
    SaveManager = result
else
    error("Falha ao carregar SaveManager.")
end

success, result = pcall(function()
    return loadstring(HttpService:GetAsync("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)
if success then
    InterfaceManager = result
else
    error("Falha ao carregar InterfaceManager.")
end

-- Configuração da Janela Fluent
local Window = Fluent:CreateWindow({
    Title = "VoidLua Hub v4",
    SubTitle = "by RodoMax",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false, -- Desativado para desempenho móvel
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Abas
local Tabs = {
    Main = Window:AddTab({ Title = "Principal", Icon = "home" }),
    Farm = Window:AddTab({ Title = "Auto Farm", Icon = "tractor" }),
    Esp = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Teleport = Window:AddTab({ Title = "Teleporte", Icon = "map" }),
    Misc = Window:AddTab({ Title = "Diversos", Icon = "tool" }),
    Settings = Window:AddTab({ Title = "Configurações", Icon = "settings" })
}

local Options = Fluent.Options

-- Notificação ao Carregar
Fluent:Notify({
    Title = "VoidLua Hub",
    Content = "Script carregado com sucesso! Use com cautela para evitar banimentos.",
    Duration = 5
})

-- Detecção de Mar
local function GetCurrentSea()
    local success, islands = pcall(function()
        return Workspace:WaitForChild("_WorldOrigin", 10):WaitForChild("Locations", 10)
    end)
    local level = 0
    pcall(function()
        level = LocalPlayer:WaitForChild("Data", 10):WaitForChild("Level", 10).Value
    end)
    if success and (islands:FindFirstChild("Port Town") or level >= 1500) then
        return "Third Sea"
    elseif success and (islands:FindFirstChild("Fountain City") or level >= 700) then
        return "Second Sea"
    else
        return "First Sea"
    end
end

-- Listas de Mobs, Chefes e Ilhas
local Locations = {
    ["First Sea"] = {
        Mobs = {"Bandit", "Monkey", "Gorilla", "Pirate", "Brute"},
        Bosses = {"Saber Expert", "The Gorilla King", "Yeti", "Vice Admiral"},
        Islands = {"Windmill Village", "Marine Fortress", "Middle Island", "Jungle"},
        Quests = {"BanditQuest", "MonkeyQuest", "GorillaQuest"}
    },
    ["Second Sea"] = {
        Mobs = {"Raider", "Mercenary", "Swan Pirate", "Factory Staff", "Marine Lieutenant"},
        Bosses = {"Diamond", "Jeremy", "Fajita", "Smoke Admiral"},
        Islands = {"Fountain City", "Kingdom of Rose", "Usoap's Island", "Factory"},
        Quests = {"RaiderQuest", "MercenaryQuest", "SwanPirateQuest"}
    },
    ["Third Sea"] = {
        Mobs = {"Pirate Millionaire", "Pistol Billionaire", "Dragon Crew Warrior", "Toga Warrior"},
        Bosses = {"Stone", "Island Empress", "Kilo Admiral", "Captain Elephant"},
        Islands = {"Port Town", "Hydra Island", "Great Tree", "Floating Turtle"},
        Quests = {"PirateMillionaireQuest", "DragonCrewQuest"}
    }
}

-- Sistema ESP
local ESP = {}
local function CreateESP(target, color, text)
    if not target or not target:IsDescendantOf(Workspace) then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = target
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = PlayerGui

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 0.5, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = color
    textLabel.TextScaled = true
    textLabel.Text = text
    textLabel.Parent = billboard

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = color
    distanceLabel.TextScaled = true
    distanceLabel.Text = "0 studs"
    distanceLabel.Parent = billboard

    ESP[target] = billboard
    return billboard
end

local function UpdateESPDistance()
    while true do
        for target, billboard in pairs(ESP) do
            if HumanoidRootPart and target:IsDescendantOf(Workspace) then
                local distance = (target.Position - HumanoidRootPart.Position).Magnitude
                local distanceLabel = billboard:FindFirstChildOfClass("TextLabel", true)
                if distanceLabel then
                    distanceLabel.Text = tostring(math.floor(distance)) .. " studs"
                end
            else
                RemoveESP(target)
            end
        end
        RandomDelay(0.5, 1)
    end
end

local function RemoveESP(target)
    if ESP[target] then
        ESP[target]:Destroy()
        ESP[target] = nil
    end
end

-- Equipar Arma
local function EquipWeapon()
    local success, backpack = pcall(function()
        return LocalPlayer:WaitForChild("Backpack", 10)
    end)
    if success and backpack then
        local tool = backpack:FindFirstChildOfClass("Tool")
        if tool and Humanoid then
            Humanoid:EquipTool(tool)
            RandomDelay(0.1, 0.3)
            return tool
        end
    end
    return nil
end

-- Auto Farm
local AutoFarmEnabled = false
local AutoFarmBossEnabled = false
local AutoQuestEnabled = false
local function AutoFarm(targetType)
    while (AutoFarmEnabled and targetType == "Mobs") or (AutoFarmBossEnabled and targetType == "Bosses") do
        local success, err = pcall(function()
            if not Character or not HumanoidRootPart or not Humanoid or Humanoid.Health <= 0 then
                Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 10)
                Humanoid = Character:WaitForChild("Humanoid", 10)
                return
            end

            EquipWeapon()
            local currentSea = GetCurrentSea()
            local targets = Locations[currentSea][targetType]
            local nearestTarget = nil
            local nearestDistance = math.huge

            -- Encontrar Alvo Mais Próximo
            for _, targetName in ipairs(targets) do
                for _, npc in ipairs(Workspace.NPCs:GetChildren()) do
                    if npc.Name == targetName and npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") and npc.Humanoid.Health > 0 then
                        local distance = (npc.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
                        if distance < nearestDistance then
                            nearestDistance = distance
                            nearestTarget = npc
                        end
                    end
                end
            end

            if nearestTarget then
                -- Aceitar Missão se Auto Quest Estiver Ativado
                if AutoQuestEnabled and targetType == "Mobs" then
                    local questName = Locations[currentSea].Quests[1]
                    pcall(function()
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", questName, 1)
                    end)
                    RandomDelay(0.5, 1)
                end

                -- Teleportar para o Alvo
                if nearestDistance < 500 then
                    local tweenInfo = TweenInfo.new(math.min(nearestDistance / 500, 3), Enum.EasingStyle.Linear)
                    local tween = TweenService:Create(HumanoidRootPart, tweenInfo, {CFrame = nearestTarget.HumanoidRootPart.CFrame * CFrame.new(0, 5, -10)})
                    tween:Play()
                    tween.Completed:Wait()
                end

                -- Atacar Alvo
                while nearestTarget and nearestTarget.Parent and nearestTarget.Humanoid.Health > 0 and ((AutoFarmEnabled and targetType == "Mobs") or (AutoFarmBossEnabled and targetType == "Bosses")) do
                    pcall(function()
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton1(Vector2.new(0, 0))
                    end)
                    RandomDelay(0.1, 0.3)
                end
            else
                RandomDelay(1, 2)
            end
        end)
        if not success then
            RandomDelay(1, 2)
        end
    end
end

-- Auto Collect Fruits
local AutoCollectFruitsEnabled = false
local function AutoCollectFruits()
    while AutoCollectFruitsEnabled do
        local success, err = pcall(function()
            if not Character or not HumanoidRootPart or not Humanoid or Humanoid.Health <= 0 then
                Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 10)
                Humanoid = Character:WaitForChild("Humanoid", 10)
                return
            end

            for _, fruit in ipairs(Workspace:GetChildren()) do
                if fruit.Name:match("Fruit") and fruit:IsA("Model") and fruit:FindFirstChild("Handle") then
                    local distance = (fruit.Handle.Position - HumanoidRootPart.Position).Magnitude
                    if distance < 500 then
                        local tweenInfo = TweenInfo.new(math.min(distance / 500, 3), Enum.EasingStyle.Linear)
                        local tween = TweenService:Create(HumanoidRootPart, tweenInfo, {CFrame = fruit.Handle.CFrame})
                        tween:Play()
                        tween.Completed:Wait()
                        pcall(function()
                            firetouchinterest(HumanoidRootPart, fruit.Handle, 0)
                            firetouchinterest(HumanoidRootPart, fruit.Handle, 1)
                        end)
                        RandomDelay(0.5, 1)
                    end
                end
            end
        end)
        if not success then
            RandomDelay(1, 2)
        end
        RandomDelay(0.5, 1)
    end
end

-- Funções ESP
local ESPFruitsEnabled = false
local ESPMobsEnabled = false
local ESPBossesEnabled = false
local function UpdateESP(category, enabled, color, name)
    while enabled() do
        local success, err = pcall(function()
            local targets = category == "Fruits" and Workspace:GetChildren() or Workspace.NPCs:GetChildren()
            for _, target in ipairs(targets) do
                local isValid = category == "Fruits" and target.Name:match("Fruit") and target:IsA("Model") and target:FindFirstChild("Handle")
                    or (category == "Mobs" or category == "Bosses") and target:FindFirstChild("Humanoid") and target:FindFirstChild("HumanoidRootPart") and target.Humanoid.Health > 0
                if isValid then
                    if not ESP[target] then
                        CreateESP(category == "Fruits" and target.Handle or target.HumanoidRootPart, color, name)
                    end
                else
                    RemoveESP(target)
                end
            end
        end)
        if not success then
            RandomDelay(1, 2)
        end
        RandomDelay(1, 1.5)
    end
    for target in pairs(ESP) do
        RemoveESP(target)
    end
end

-- Auto Raid
local AutoRaidEnabled = false
local function AutoRaid()
    while AutoRaidEnabled do
        local success, err = pcall(function()
            if not Character or not HumanoidRootPart or not Humanoid or Humanoid.Health <= 0 then
                Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 10)
                Humanoid = Character:WaitForChild("Humanoid", 10)
                return
            end

            pcall(function()
                ReplicatedStorage.Remotes.CommF_:InvokeServer("RaidsNpc", "Select", "Flame")
            end)
            RandomDelay(2, 3)
            local raidIsland = Workspace._WorldOrigin.Locations:FindFirstChild("Raid Island")
            if raidIsland then
                local distance = (raidIsland.Position - HumanoidRootPart.Position).Magnitude
                if distance < 500 then
                    HumanoidRootPart.CFrame = raidIsland.CFrame * CFrame.new(0, 10, 0)
                end
            end
            for _, enemy in ipairs(Workspace.Enemies:GetChildren()) do
                if enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") and enemy.Humanoid.Health > 0 then
                    local distance = (enemy.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
                    if distance < 500 then
                        HumanoidRootPart.CFrame = enemy.HumanoidRootPart.CFrame * CFrame.new(0, 5, -10)
                        pcall(function()
                            VirtualUser:CaptureController()
                            VirtualUser:ClickButton1(Vector2.new(0, 0))
                        end)
                        RandomDelay(0.2, 0.4)
                    end
                end
            end
        end)
        if not success then
            RandomDelay(1, 2)
        end
        RandomDelay(5, 7)
    end
end

-- Auto Stats
local AutoStatsEnabled = false
local function AutoStats(stat)
    while AutoStatsEnabled do
        local success, err = pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("AddPoint", stat, 3)
        end)
        if not success then
            RandomDelay(1, 2)
        end
        RandomDelay(1, 1.5)
    end
end

-- Auto Skills
local AutoSkillsEnabled = false
local function AutoSkills()
    while AutoSkillsEnabled do
        local success, err = pcall(function()
            if not Character or not HumanoidRootPart or not Humanoid or Humanoid.Health <= 0 then
                Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 10)
                Humanoid = Character:WaitForChild("Humanoid", 10)
                return
            end

            local tool = Character:FindFirstChildOfClass("Tool")
            if tool then
                for _, skill in ipairs({"Z", "X", "C", "V"}) do
                    pcall(function()
                        UserInputService:SendKeyEvent(true, Enum.KeyCode[skill], false, game)
                        RandomDelay(1, 1.5)
                        UserInputService:SendKeyEvent(false, Enum.KeyCode[skill], false, game)
                    end)
                end
            end
        end)
        if not success then
            RandomDelay(1, 2)
        end
        RandomDelay(2, 3)
    end
end

-- Kill Aura
local KillAuraEnabled = false
local function KillAura()
    while KillAuraEnabled do
        local success, err = pcall(function()
            if not Character or not HumanoidRootPart or not Humanoid or Humanoid.Health <= 0 then
                Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 10)
                Humanoid = Character:WaitForChild("Humanoid", 10)
                return
            end

            for _, enemy in ipairs(Workspace.NPCs:GetChildren()) do
                if enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") and enemy.Humanoid.Health > 0 then
                    local distance = (enemy.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
                    if distance < 15 then
                        pcall(function()
                            VirtualUser:CaptureController()
                            VirtualUser:ClickButton1(Vector2.new(0, 0))
                        end)
                    end
                end
            end
        end)
        if not success then
            RandomDelay(1, 2)
        end
        RandomDelay(0.1, 0.2)
    end
end

-- Anti-AFK
local AntiAFKEnabled = false
local function AntiAFK()
    while AntiAFKEnabled do
        local success, err = pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:Button1Down(Vector2.new(0, 0))
            RandomDelay(0.1, 0.3)
            VirtualUser:Button1Up(Vector2.new(0, 0))
        end)
        if not success then
            RandomDelay(1, 2)
        end
        RandomDelay(60, 65)
    end
end

-- Interface Principal
Tabs.Main:AddParagraph({
    Title = "Funcionalidades Principais",
    Content = "Controle as funcionalidades principais para Blox Fruits."
})

-- Interface de Farm
local AutoFarmToggle = Tabs.Farm:AddToggle("AutoFarmMobs", { Title = "Auto Farm Mobs", Default = false })
AutoFarmToggle:OnChanged(function(value)
    AutoFarmEnabled = value
    if value then task.spawn(function() AutoFarm("Mobs") end) end
end)

local AutoFarmBossToggle = Tabs.Farm:AddToggle("AutoFarmBosses", { Title = "Auto Farm Chefes", Default = false })
AutoFarmBossToggle:OnChanged(function(value)
    AutoFarmBossEnabled = value
    if value then task.spawn(function() AutoFarm("Bosses") end) end
end)

local AutoQuestToggle = Tabs.Farm:AddToggle("AutoQuest", { Title = "Auto Missão", Default = false })
AutoQuestToggle:OnChanged(function(value)
    AutoQuestEnabled = value
end)

local AutoCollectFruitsToggle = Tabs.Farm:AddToggle("AutoCollectFruits", { Title = "Coletar Frutas Automaticamente", Default = false })
AutoCollectFruitsToggle:OnChanged(function(value)
    AutoCollectFruitsEnabled = value
    if value then task.spawn(AutoCollectFruits) end
end)

-- Interface ESP
local ESPFruitsToggle = Tabs.Esp:AddToggle("ESPFruits", { Title = "ESP Frutas", Default = false })
ESPFruitsToggle:OnChanged(function(value)
    ESPFruitsEnabled = value
    if value then task.spawn(function() UpdateESP("Fruits", function() return ESPFruitsEnabled end, Color3.fromRGB(255, 0, 0), "Fruta") end) end
end)

local ESPMobsToggle = Tabs.Esp:AddToggle("ESPMobs", { Title = "ESP Mobs", Default = false })
ESPMobsToggle:OnChanged(function(value)
    ESPMobsEnabled = value
    if value then task.spawn(function() UpdateESP("Mobs", function() return ESPMobsEnabled end, Color3.fromRGB(0, 255, 0), "Mob") end) end
end)

local ESPBossesToggle = Tabs.Esp:AddToggle("ESPBosses", { Title = "ESP Chefes", Default = false })
ESPBossesToggle:OnChanged(function(value)
    ESPBossesEnabled = value
    if value then task.spawn(function() UpdateESP("Bosses", function() return ESPBossesEnabled end, Color3.fromRGB(0, 0, 255), "Chefe") end) end
end)

task.spawn(UpdateESPDistance)

-- Interface de Teleporte
local function UpdateTeleportDropdowns()
    local currentSea = GetCurrentSea()
    local mobDropdown = Tabs.Teleport:AddDropdown("MobTeleport", {
        Title = "Teleportar para Mob",
        Values = Locations[currentSea].Mobs,
        Multi = false,
        Default = Locations[currentSea].Mobs[1]
    })
    mobDropdown:OnChanged(function(value)
        local success, err = pcall(function()
            for _, npc in ipairs(Workspace.NPCs:GetChildren()) do
                if npc.Name == value and npc:FindFirstChild("HumanoidRootPart") then
                    local distance = (npc.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
                    if distance < 500 then
                        HumanoidRootPart.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0)
                    end
                    break
                end
            end
        end)
        if not success then
            RandomDelay(1, 2)
        end
    end)

    local bossDropdown = Tabs.Teleport:AddDropdown("BossTeleport", {
        Title = "Teleportar para Chefe",
        Values = Locations[currentSea].Bosses,
        Multi = false,
        Default = Locations[currentSea].Bosses[1]
    })
    bossDropdown:OnChanged(function(value)
        local success, err = pcall(function()
            for _, npc in ipairs(Workspace.NPCs:GetChildren()) do
                if npc.Name == value and npc:FindFirstChild("HumanoidRootPart") then
                    local distance = (npc.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
                    if distance < 500 then
                        HumanoidRootPart.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0)
                    end
                    break
                end
            end
        end)
        if not success then
            RandomDelay(1, 2)
        end
    end)

    local islandDropdown = Tabs.Teleport:AddDropdown("IslandTeleport", {
        Title = "Teleportar para Ilha",
        Values = Locations[currentSea].Islands,
        Multi = false,
        Default = Locations[currentSea].Islands[1]
    })
    islandDropdown:OnChanged(function(value)
        local success, err = pcall(function()
            local island = Workspace._WorldOrigin.Locations:FindFirstChild(value)
            if island then
                local distance = (island.Position - HumanoidRootPart.Position).Magnitude
                if distance < 500 then
                    HumanoidRootPart.CFrame = island.CFrame * CFrame.new(0, 50, 0)
                end
            end
        end)
        if not success then
            RandomDelay(1, 2)
        end
    end)
end
UpdateTeleportDropdowns()

-- Interface Diversos
local AutoRaidToggle = Tabs.Misc:AddToggle("AutoRaid", { Title = "Auto Raid", Default = false })
AutoRaidToggle:OnChanged(function(value)
    AutoRaidEnabled = value
    if value then task.spawn(AutoRaid) end
end)

local AutoStatsDropdown = Tabs.Misc:AddDropdown("AutoStats", {
    Title = "Auto Stats",
    Values = {"Melee", "Defense", "Sword", "Gun", "Fruit"},
    Multi = false,
    Default = "Melee"
})
local AutoStatsToggle = Tabs.Misc:AddToggle("AutoStatsToggle", { Title = "Ativar Auto Stats", Default = false })
AutoStatsToggle:On
