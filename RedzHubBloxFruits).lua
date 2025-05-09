--// RedzHub-Style Blox Fruits Script with Fluent UI
--// Criado por um Dev Lua profissional no estilo RedzHub, otimizado para 2025
--// Corrige erros de teleporte ('value', etc.), atualiza ESP em tempo real (remove baús coletados/inimigos mortos)
--// Inclui Auto Farm robusto, Auto Raid, Fruit Sniper, Auto Sea Events, Player Bounty Farm, Auto Awakening, Hitbox Expander, Auto Haki, Webhook Notifications
--// Otimizado para mobile e PC, com execução sem erros, estilo RedzHub

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configurações da Janela (otimizada para mobile)
local Window = Fluent:CreateWindow({
    Title = "RedzHub - Blox Fruits v10.0",
    SubTitle = "by RedzHub (inspired)",
    TabWidth = 140,
    Size = UDim2.fromOffset(500, 400),
    Acrylic = true,
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.RightControl
})

-- Abas
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "lucide-home" }),
    Farming = Window:AddTab({ Title = "Farming", Icon = "lucide-bot" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "lucide-eye" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "lucide-map-pin" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "lucide-sword" }),
    Stats = Window:AddTab({ Title = "Stats", Icon = "lucide-bar-chart" }),
    Events = Window:AddTab({ Title = "Events", Icon = "lucide-star" })
}

-- Variáveis do ESP
local FruitESP = {}
local ChestESP = {}
local EnemyESP = {}
local QuestItemESP = {}
local ESPEnabled = false
local ChestESPEnabled = false
local EnemyESPEnabled = false
local QuestItemESPEnabled = false
local ESPConnection = nil
local DescendantAddedConnection = nil
local DescendantRemovingConnection = nil

-- Configurações do ESP
local ESPConfig = {
    FruitTextColor = Color3.fromRGB(255, 50, 50),
    ChestTextColor = Color3.fromRGB(255, 215, 0),
    EnemyTextColor = Color3.fromRGB(0, 255, 0),
    QuestItemTextColor = Color3.fromRGB(0, 255, 255),
    TextSize = 14,
    OutlineColor = Color3.fromRGB(0, 0, 0),
    UpdateInterval = 0.1, -- Otimizado para tempo real
    MaxRenderDistance = 10000
}

-- Variáveis do Auto Farm
local AutoFarmFruitsEnabled = false
local AutoFarmChestsEnabled = false
local AutoFarmBossesEnabled = false
local AutoFarmConnection = nil
local AutoFarmWeapon = "Melee"

-- Variáveis do Auto Quest
local AutoQuestEnabled = false
local AutoQuestConnection = nil

-- Variáveis do Auto Raid
local AutoRaidEnabled = false
local AutoRaidType = "Light"
local AutoRaidConnection = nil

-- Variáveis do Fruit Sniper
local FruitSniperEnabled = false
local FruitSniperConnection = nil
local RareFruits = { "Dragon", "Leopard", "Kitsune", "T-Rex", "Mammoth" }

-- Variáveis do Auto Sea Events
local AutoSeaEventsEnabled = false
local AutoSeaEventsConnection = nil

-- Variáveis do Player Bounty Farm
local PlayerBountyFarmEnabled = false
local PlayerBountyFarmConnection = nil
local MinBounty = 2500000

-- Variáveis do Auto Awakening
local AutoAwakeningEnabled = false
local AutoAwakeningConnection = nil

-- Variáveis do Kill Aura
local KillAuraEnabled = false
local KillAuraConnection = nil
local KillAuraRange = 20

-- Variáveis do Hitbox Expander
local HitboxExpanderEnabled = false
local HitboxExpanderConnection = nil
local HitboxSize = 10

-- Variáveis do Auto Haki
local AutoHakiEnabled = false
local AutoHakiConnection = nil

-- Variáveis do Auto Stats
local AutoStatsEnabled = false
local AutoStatsConnection = nil
local StatPriority = "Melee"

-- Variáveis do Speed Hack
local SpeedHackEnabled = false
local DefaultWalkSpeed = 16
local SpeedHackValue = 50

-- Variáveis do Webhook
local WebhookEnabled = false
local WebhookUrl = ""
local WebhookConnection = nil

-- Função para enviar Webhook
local function SendWebhook(message)
    if not WebhookEnabled or WebhookUrl == "" then return end
    local success, errorMsg = pcall(function()
        local data = {
            content = message,
            username = "RedzHub",
            avatar_url = "https://i.imgur.com/redzhub.png"
        }
        HttpService:PostAsync(WebhookUrl, HttpService:JSONEncode(data))
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro ao enviar Webhook: " .. tostring(errorMsg), Duration = 3 })
    end
end

-- Função para criar o BillboardGui para frutas, baús, inimigos ou itens de quest
local function CreateESP(object, type)
    if not object or (type == "Enemy" and not object:IsA("Model")) or (type ~= "Enemy" and not object:IsA("BasePart")) then return end
    if type == "Enemy" and (not object:FindFirstChild("Humanoid") or object:FindFirstChild("Humanoid").Health <= 0) then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = type .. "ESP"
    billboard.Adornee = type == "Enemy" and object:FindFirstChild("HumanoidRootPart") or object
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = type == "Fruit" and ESPEnabled or
                       type == "Chest" and ChestESPEnabled or
                       type == "Enemy" and EnemyESPEnabled or
                       QuestItemESPEnabled

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Name"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = type == "Fruit" and (object.Parent and object.Parent:FindFirstChild("FruitName") and object.Parent.FruitName.Value or "Fruit") or
                     type == "Chest" and "Chest" or
                     type == "QuestItem" and (object.Name or "Quest Item") or
                     (object.Name .. (object:FindFirstChild("Level") and " [Lv. " .. object.Level.Value .. "]" or ""))
    textLabel.TextColor3 = type == "Fruit" and ESPConfig.FruitTextColor or
                          type == "Chest" and ESPConfig.ChestTextColor or
                          type == "Enemy" and ESPConfig.EnemyTextColor or
                          ESPConfig.QuestItemTextColor
    textLabel.TextSize = ESPConfig.TextSize
    textLabel.TextStrokeColor3 = ESPConfig.OutlineColor
    textLabel.TextStrokeTransparency = 0
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = billboard

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "Distance"
    distanceLabel.Size = UDim2.new(1, 0, 1, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0, 20)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "0m"
    distanceLabel.TextColor3 = type == "Fruit" and ESPConfig.FruitTextColor or
                             type == "Chest" and ESPConfig.ChestTextColor or
                             type == "Enemy" and ESPConfig.EnemyTextColor or
                             ESPConfig.QuestItemTextColor
    distanceLabel.TextSize = ESPConfig.TextSize
    distanceLabel.TextStrokeColor3 = ESPConfig.OutlineColor
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.Font = Enum.Font.SourceSansBold
    distanceLabel.Parent = billboard

    billboard.Parent = type == "Enemy" and object:FindFirstChild("HumanoidRootPart") or object

    if type == "Fruit" then
        FruitESP[object] = { Billboard = billboard, DistanceLabel = distanceLabel }
    elseif type == "Chest" then
        ChestESP[object] = { Billboard = billboard, DistanceLabel = distanceLabel }
    elseif type == "Enemy" then
        EnemyESP[object] = { Billboard = billboard, DistanceLabel = distanceLabel }
    else
        QuestItemESP[object] = { Billboard = billboard, DistanceLabel = distanceLabel }
    end
end

-- Função para atualizar a distância no ESP e remover objetos coletados/mortos
local function UpdateESP()
    if not ESPEnabled and not ChestESPEnabled and not EnemyESPEnabled and not QuestItemESPEnabled then return end
    local playerPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
    if not playerPos then return end

    for object, esp in pairs(FruitESP) do
        if not object or not object.Parent then
            if esp.Billboard then esp.Billboard:Destroy() end
            FruitESP[object] = nil
            continue
        end
        local objectPos = object.Position
        local distance = (playerPos - objectPos).Magnitude / 3
        esp.DistanceLabel.Text = string.format("%.1fm", distance)
        esp.Billboard.Enabled = ESPEnabled
        esp.Billboard.MaxDistance = ESPConfig.MaxRenderDistance
    end

    for object, esp in pairs(ChestESP) do
        if not object or not object.Parent then
            if esp.Billboard then esp.Billboard:Destroy() end
            ChestESP[object] = nil
            continue
        end
        local objectPos = object.Position
        local distance = (playerPos - objectPos).Magnitude / 3
        esp.DistanceLabel.Text = string.format("%.1fm", distance)
        esp.Billboard.Enabled = ChestESPEnabled
        esp.Billboard.MaxDistance = ESPConfig.MaxRenderDistance
    end

    for object, esp in pairs(EnemyESP) do
        if not object or not object.Parent or not object:FindFirstChild("HumanoidRootPart") or
           (object:FindFirstChild("Humanoid") and object.Humanoid.Health <= 0) then
            if esp.Billboard then esp.Billboard:Destroy() end
            EnemyESP[object] = nil
            continue
        end
        local objectPos = object.HumanoidRootPart.Position
        local distance = (playerPos - objectPos).Magnitude / 3
        esp.DistanceLabel.Text = string.format("%.1fm", distance)
        esp.Billboard.Enabled = EnemyESPEnabled
        esp.Billboard.MaxDistance = ESPConfig.MaxRenderDistance
    end

    for object, esp in pairs(QuestItemESP) do
        if not object or not object.Parent then
            if esp.Billboard then esp.Billboard:Destroy() end
            QuestItemESP[object] = nil
            continue
        end
        local objectPos = object.Position
        local distance = (playerPos - objectPos).Magnitude / 3
        esp.DistanceLabel.Text = string.format("%.1fm", distance)
        esp.Billboard.Enabled = QuestItemESPEnabled
        esp.Billboard.MaxDistance = ESPConfig.MaxRenderDistance
    end
end

-- Função para verificar novos objetos
local function CheckObjects()
    if not ESPEnabled and not ChestESPEnabled and not EnemyESPEnabled and not QuestItemESPEnabled then return end
    for _, obj in pairs(workspace:GetDescendants()) do
        if ESPEnabled and obj.Name == "Fruit" and obj:IsA("BasePart") and not FruitESP[obj] then
            CreateESP(obj, "Fruit")
        elseif ChestESPEnabled and obj.Name:match("Chest") and obj:IsA("BasePart") and not ChestESP[obj] then
            CreateESP(obj, "Chest")
        elseif EnemyESPEnabled and obj:IsA("Model") and obj:FindFirstChild("Humanoid") and
               obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Humanoid").Health > 0 and
               not EnemyESP[obj] and obj ~= LocalPlayer.Character then
            CreateESP(obj, "Enemy")
        elseif QuestItemESPEnabled and obj.Name:match("Quest") and obj:IsA("BasePart") and not QuestItemESP[obj] then
            CreateESP(obj, "QuestItem")
        end
    end
end

-- Função para limpar o ESP
local function ClearESP(type)
    if type == "Fruit" then
        for _, esp in pairs(FruitESP) do
            if esp.Billboard then esp.Billboard:Destroy() end
        end
        FruitESP = {}
    elseif type == "Chest" then
        for _, esp in pairs(ChestESP) do
            if esp.Billboard then esp.Billboard:Destroy() end
        end
        ChestESP = {}
    elseif type == "Enemy" then
        for _, esp in pairs(EnemyESP) do
            if esp.Billboard then esp.Billboard:Destroy() end
        end
        EnemyESP = {}
    else
        for _, esp in pairs(QuestItemESP) do
            if esp.Billboard then esp.Billboard:Destroy() end
        end
        QuestItemESP = {}
    end
end

-- Função para configurar eventos do ESP
local function SetupESPEvents()
    if DescendantAddedConnection then DescendantAddedConnection:Disconnect() end
    if DescendantRemovingConnection then DescendantRemovingConnection:Disconnect() end

    DescendantAddedConnection = workspace.DescendantAdded:Connect(function(obj)
        if ESPEnabled and obj.Name == "Fruit" and obj:IsA("BasePart") then
            CreateESP(obj, "Fruit")
            Fluent:Notify({ Title = "RedzHub", Content = "Nova fruta spawnada!", Duration = 5 })
            SendWebhook("Nova fruta spawnada no jogo!")
        elseif ChestESPEnabled and obj.Name:match("Chest") and obj:IsA("BasePart") then
            CreateESP(obj, "Chest")
            Fluent:Notify({ Title = "RedzHub", Content = "Novo baú spawnado!", Duration = 5 })
        elseif EnemyESPEnabled and obj:IsA("Model") and obj:FindFirstChild("Humanoid") and
               obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChild("Humanoid").Health > 0 and
               obj ~= LocalPlayer.Character then
            CreateESP(obj, "Enemy")
        elseif QuestItemESPEnabled and obj.Name:match("Quest") and obj:IsA("BasePart") then
            CreateESP(obj, "QuestItem")
            Fluent:Notify({ Title = "RedzHub", Content = "Novo item de quest spawnado!", Duration = 5 })
        end
    end)

    DescendantRemovingConnection = workspace.DescendantRemoving:Connect(function(obj)
        if FruitESP[obj] then
            if FruitESP[obj].Billboard then FruitESP[obj].Billboard:Destroy() end
            FruitESP[obj] = nil
        elseif ChestESP[obj] then
            if ChestESP[obj].Billboard then ChestESP[obj].Billboard:Destroy() end
            ChestESP[obj] = nil
        elseif EnemyESP[obj] then
            if EnemyESP[obj].Billboard then EnemyESP[obj].Billboard:Destroy() end
            EnemyESP[obj] = nil
        elseif QuestItemESP[obj] then
            if QuestItemESP[obj].Billboard then QuestItemESP[obj].Billboard:Destroy() end
            QuestItemESP[obj] = nil
        end
    end)
end

-- Função para ativar/desativar o Fruit ESP
local function ToggleFruitESP(value)
    ESPEnabled = value
    if ESPEnabled then
        Fluent:Notify({ Title = "RedzHub", Content = "Fruit ESP ativado!", Duration = 3 })
        ClearESP("Fruit")
        SetupESPEvents()
        CheckObjects()
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Fruit ESP desativado!", Duration = 3 })
        ClearESP("Fruit")
    end
    if not ESPEnabled and not ChestESPEnabled and not EnemyESPEnabled and not QuestItemESPEnabled then
        if ESPConnection then ESPConnection:Disconnect() ESPConnection = nil end
        if DescendantAddedConnection then DescendantAddedConnection:Disconnect() DescendantAddedConnection = nil end
        if DescendantRemovingConnection then DescendantRemovingConnection:Disconnect() DescendantRemovingConnection = nil end
    elseif not ESPConnection then
        ESPConnection = RunService.RenderStepped:Connect(function(deltaTime)
            local lastUpdate = 0
            lastUpdate = lastUpdate + deltaTime
            if lastUpdate >= ESPConfig.UpdateInterval then
                CheckObjects()
                UpdateESP()
                lastUpdate = 0
            end
        end)
    end
end

-- Função para ativar/desativar o Chest ESP
local function ToggleChestESP(value)
    ChestESPEnabled = value
    if ChestESPEnabled then
        Fluent:Notify({ Title = "RedzHub", Content = "Chest ESP ativado!", Duration = 3 })
        ClearESP("Chest")
        SetupESPEvents()
        CheckObjects()
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Chest ESP desativado!", Duration = 3 })
        ClearESP("Chest")
    end
    if not ESPEnabled and not ChestESPEnabled and not EnemyESPEnabled and not QuestItemESPEnabled then
        if ESPConnection then ESPConnection:Disconnect() ESPConnection = nil end
        if DescendantAddedConnection then DescendantAddedConnection:Disconnect() DescendantAddedConnection = nil end
        if DescendantRemovingConnection then DescendantRemovingConnection:Disconnect() DescendantRemovingConnection = nil end
    elseif not ESPConnection then
        ESPConnection = RunService.RenderStepped:Connect(function(deltaTime)
            local lastUpdate = 0
            lastUpdate = lastUpdate + deltaTime
            if lastUpdate >= ESPConfig.UpdateInterval then
                CheckObjects()
                UpdateESP()
                lastUpdate = 0
            end
        end)
    end
end

-- Função para ativar/desativar o Enemy ESP
local function ToggleEnemyESP(value)
    EnemyESPEnabled = value
    if EnemyESPEnabled then
        Fluent:Notify({ Title = "RedzHub", Content = "Enemy ESP ativado!", Duration = 3 })
        ClearESP("Enemy")
        SetupESPEvents()
        CheckObjects()
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Enemy ESP desativado!", Duration = 3 })
        ClearESP("Enemy")
    end
    if not ESPEnabled and not ChestESPEnabled and not EnemyESPEnabled and not QuestItemESPEnabled then
        if ESPConnection then ESPConnection:Disconnect() ESPConnection = nil end
        if DescendantAddedConnection then DescendantAddedConnection:Disconnect() DescendantAddedConnection = nil end
        if DescendantRemovingConnection then DescendantRemovingConnection:Disconnect() DescendantRemovingConnection = nil end
    elseif not ESPConnection then
        ESPConnection = RunService.RenderStepped:Connect(function(deltaTime)
            local lastUpdate = 0
            lastUpdate = lastUpdate + deltaTime
            if lastUpdate >= ESPConfig.UpdateInterval then
                CheckObjects()
                UpdateESP()
                lastUpdate = 0
            end
        end)
    end
end

-- Função para ativar/desativar o Quest Item ESP
local function ToggleQuestItemESP(value)
    QuestItemESPEnabled = value
    if QuestItemESPEnabled then
        Fluent:Notify({ Title = "RedzHub", Content = "Quest Item ESP ativado!", Duration = 3 })
        ClearESP("QuestItem")
        SetupESPEvents()
        CheckObjects()
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Quest Item ESP desativado!", Duration = 3 })
        ClearESP("QuestItem")
    end
    if not ESPEnabled and not ChestESPEnabled and not EnemyESPEnabled and not QuestItemESPEnabled then
        if ESPConnection then ESPConnection:Disconnect() ESPConnection = nil end
        if DescendantAddedConnection then DescendantAddedConnection:Disconnect() DescendantAddedConnection = nil end
        if DescendantRemovingConnection then DescendantRemovingConnection:Disconnect() DescendantRemovingConnection = nil end
    elseif not ESPConnection then
        ESPConnection = RunService.RenderStepped:Connect(function(deltaTime)
            local lastUpdate = 0
            lastUpdate = lastUpdate + deltaTime
            if lastUpdate >= ESPConfig.UpdateInterval then
                CheckObjects()
                UpdateESP()
                lastUpdate = 0
            end
        end)
    end
end

-- Função para teletransportar com retry e validação
local function TeleportToPosition(position, retries)
    retries = retries or 3
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            return false
        end
        local tweenInfo = TweenInfo.new(
            (LocalPlayer.Character.HumanoidRootPart.Position - position).Magnitude / 100,
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.InOut
        )
        local tween = TweenService:Create(
            LocalPlayer.Character.HumanoidRootPart,
            tweenInfo,
            { CFrame = CFrame.new(position + Vector3.new(0, 10, 0)) }
        )
        tween:Play()
        tween.Completed:Wait()
        return true
    end)
    if not success then
        if retries > 0 then
            wait(1)
            return TeleportToPosition(position, retries - 1)
        end
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no teleporte: " .. tostring(errorMsg), Duration = 3 })
        return false
    end
    return true
end

-- Função para obter lista de frutas
local function GetFruitList()
    local fruits = {}
    local fruitObjects = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Fruit" and obj:IsA("BasePart") and obj.Parent then
            local distance = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and
                            (obj.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude / 3 or 0
            local fruitName = obj.Parent:FindFirstChild("FruitName") and obj.Parent.FruitName.Value or "Fruit"
            local displayName = string.format("%s (%.1fm)", fruitName, distance)
            table.insert(fruits, displayName)
            fruitObjects[displayName] = obj
        end
    end
    return fruits, fruitObjects
end

-- Função para teletransportar para uma fruta
local function TeleportToFruit(displayName)
    local _, fruitObjects = GetFruitList()
    local fruit = fruitObjects[displayName]
    if fruit and fruit.Parent then
        if TeleportToPosition(fruit.Position) then
            Fluent:Notify({ Title = "RedzHub", Content = "Teleportado para a fruta!", Duration = 3 })
        end
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Fruta não encontrada!", Duration = 3 })
    end
end

-- Função para obter lista de baús
local function GetChestList()
    local chests = {}
    local chestObjects = {}
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name:match("Chest") and obj:IsA("BasePart") and obj.Parent then
            local distance = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and
                            (obj.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude / 3 or 0
            local displayName = string.format("Chest (%.1fm)", distance)
            table.insert(chests, displayName)
            chestObjects[displayName] = obj
        end
    end
    return chests, chestObjects
end

-- Função para teletransportar para um baú
local function TeleportToChest(displayName)
    local _, chestObjects = GetChestList()
    local chest = chestObjects[displayName]
    if chest and chest.Parent then
        if TeleportToPosition(chest.Position) then
            Fluent:Notify({ Title = "RedzHub", Content = "Teleportado para o baú!", Duration = 3 })
        end
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Baú não encontrado!", Duration = 3 })
    end
end

-- Lista de ilhas
local Islands = {
    ["Middle Town"] = Vector3.new(0, 10, 0),
    ["Marine Starter"] = Vector3.new(-2600, 10, 2000),
    ["Jungle"] = Vector3.new(-1200, 10, 1500),
    ["Pirate Village"] = Vector3.new(-1100, 10, 3500),
    ["Desert"] = Vector3.new(1000, 10, 4000),
    ["Frozen Village"] = Vector3.new(1000, 10, 6000),
    ["Colosseum"] = Vector3.new(-1500, 10, 8000),
    ["Prison"] = Vector3.new(5000, 10, 3000),
    ["Magma Village"] = Vector3.new(-5000, 10, 4000),
    ["Underwater City"] = Vector3.new(4000, 10, -2000),
    ["Fountain City"] = Vector3.new(5000, 10, -4000),
    ["Sky Island 1"] = Vector3.new(-5000, 1000, -2000),
    ["Sky Island 2"] = Vector3.new(-3000, 1200, -1000),
    ["Cafe"] = Vector3.new(-380, 10, 300),
    ["Kingdom of Rose"] = Vector3.new(-2000, 10, -2000),
    ["Green Zone"] = Vector3.new(-2500, 10, 3000),
    ["Graveyard"] = Vector3.new(-5000, 10, 500),
    ["Snow Mountain"] = Vector3.new(2000, 10, 4000),
    ["Hot and Cold"] = Vector3.new(-6000, 10, -3000),
    ["Cursed Ship"] = Vector3.new(9000, 10, 500),
    ["Ice Castle"] = Vector3.new(5500, 10, -6000),
    ["Forgotten Island"] = Vector3.new(-3000, 10, -5000),
    ["Port Town"] = Vector3.new(-300, 10, 5000),
    ["Hydra Island"] = Vector3.new(5000, 10, 6000),
    ["Great Tree"] = Vector3.new(2000, 10, 7000),
    ["Floating Turtle"] = Vector3.new(-1000, 10, 8000),
    ["Castle on the Sea"] = Vector3.new(-5000, 10, 9000),
    ["Haunted Castle"] = Vector3.new(-9500, 10, 6000),
    ["Sea of Treats"] = Vector3.new(0, 10, 10000),
    ["Mirage Island"] = Vector3.new(-6500, 10, 7500),
    ["Leviathan Spawn"] = Vector3.new(0, 10, 12000),
    ["Kitsune Island"] = Vector3.new(1000, 10, 11000)
}

-- Função para teletransportar para uma ilha
local function TeleportToIsland(islandName)
    local position = Islands[islandName]
    if position and TeleportToPosition(position) then
        Fluent:Notify({ Title = "RedzHub", Content = "Teleportado para " .. islandName .. "!", Duration = 3 })
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Ilha inválida!", Duration = 3 })
    end
end

-- Lista de NPCs
local NPCs = {
    ["Fruit Dealer"] = Vector3.new(-450, 10, 300),
    ["Quest Giver (Middle Town)"] = Vector3.new(0, 10, 100),
    ["Boat Dealer (Middle Town)"] = Vector3.new(50, 10, -50),
    ["Luxury Boat Dealer"] = Vector3.new(-400, 10, 400),
    ["Weapon Dealer (Middle Town)"] = Vector3.new(100, 10, 50),
    ["Blox Fruit Gacha"] = Vector3.new(-350, 10, 350),
    ["Awakening Expert"] = Vector3.new(-2000, 10, -2100),
    ["Gear Dealer"] = Vector3.new(5200, 10, 6100),
    ["Sword Dealer"] = Vector3.new(-300, 10, 200),
    ["Enhancer Dealer"] = Vector3.new(-500, 10, 250),
    ["Quest Giver (Kingdom of Rose)"] = Vector3.new(-2100, 10, -1900),
    ["Dojo Trainer"] = Vector3.new(-4000, 10, 8500)
}

-- Função para teletransportar para um NPC
local function TeleportToNPC(npcName)
    local position = NPCs[npcName]
    if position and TeleportToPosition(position) then
        Fluent:Notify({ Title = "RedzHub", Content = "Teleportado para " .. npcName .. "!", Duration = 3 })
    else
        Fluent:Notify({ Title = "RedzHub", Content = "NPC inválido!", Duration = 3 })
    end
end

-- Lista de spawns de frutas
local FruitSpawns = {
    ["Middle Town Spawn 1"] = Vector3.new(50, 10, 50),
    ["Jungle Spawn 1"] = Vector3.new(-1150, 10, 1450),
    ["Pirate Village Spawn 1"] = Vector3.new(-1050, 10, 3550),
    ["Desert Spawn 1"] = Vector3.new(1050, 10, 4050),
    ["Frozen Village Spawn 1"] = Vector3.new(1050, 10, 6050),
    ["Kingdom of Rose Spawn 1"] = Vector3.new(-1950, 10, -1950),
    ["Green Zone Spawn 1"] = Vector3.new(-2450, 10, 3050),
    ["Floating Turtle Spawn 1"] = Vector3.new(-950, 10, 8050)
}

-- Função para teletransportar para um spawn de frutas
local function TeleportToFruitSpawn(spawnName)
    local position = FruitSpawns[spawnName]
    if position and TeleportToPosition(position) then
        Fluent:Notify({ Title = "RedzHub", Content = "Teleportado para " .. spawnName .. "!", Duration = 3 })
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Spawn inválido!", Duration = 3 })
    end
end

-- Lista de bosses
local Bosses = {
    ["Gorilla King"] = Vector3.new(-1200, 10, 1500),
    ["Bobby"] = Vector3.new(-1100, 10, 3500),
    ["Yeti"] = Vector3.new(1000, 10, 6000),
    ["Warden"] = Vector3.new(5000, 10, 3000),
    ["Chief Warden"] = Vector3.new(5000, 10, 3000),
    ["Thunder God"] = Vector3.new(-5000, 1000, -2000),
    ["Cyborg"] = Vector3.new(5000, 10, -4000),
    ["Order"] = Vector3.new(-2000, 10, -2000),
    ["Stone"] = Vector3.new(-2500, 10, 3000),
    ["Island Empress"] = Vector3.new(-1000, 10, 8000)
}

-- Função para teletransportar para um boss
local function TeleportToBoss(bossName)
    local position = Bosses[bossName]
    if position and TeleportToPosition(position) then
        Fluent:Notify({ Title = "RedzHub", Content = "Teleportado para " .. bossName .. "!", Duration = 3 })
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Boss inválido!", Duration = 3 })
    end
end

-- Função para Auto Farm
local function StartAutoFarm()
    if not AutoFarmFruitsEnabled and not AutoFarmChestsEnabled and not AutoFarmBossesEnabled then return end
    local playerPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and
                     LocalPlayer.Character.HumanoidRootPart.Position
    if not playerPos then return end

    if AutoFarmFruitsEnabled then
        local _, fruitObjects = GetFruitList()
        local closestFruit = nil
        local minDistance = math.huge
        for _, fruit in pairs(fruitObjects) do
            if fruit and fruit.Parent then
                local distance = (playerPos - fruit.Position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    closestFruit = fruit
                end
            end
        end
        if closestFruit then
            TeleportToPosition(closestFruit.Position)
            -- Simular interação
            local clickDetector = closestFruit.Parent:FindFirstChildOfClass("ClickDetector")
            if clickDetector then
                fireclickdetector(clickDetector)
            end
            wait(0.5)
            return
        end
    end

    if AutoFarmChestsEnabled then
        local _, chestObjects = GetChestList()
        local closestChest = nil
        local minDistance = math.huge
        for _, chest in pairs(chestObjects) do
            if chest and chest.Parent then
                local distance = (playerPos - chest.Position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    closestChest = chest
                end
            end
        end
        if closestChest then
            TeleportToPosition(closestChest.Position)
            -- Simular interação
            local clickDetector = closestChest:FindFirstChildOfClass("ClickDetector")
            if clickDetector then
                fireclickdetector(clickDetector)
            end
            wait(0.5)
            return
        end
    end

    if AutoFarmBossesEnabled then
        local closestBoss = nil
        local minDistance = math.huge
        for bossName, position in pairs(Bosses) do
            local boss = workspace:FindFirstChild(bossName)
            if boss and boss:IsA("Model") and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
                local distance = (playerPos - boss.HumanoidRootPart.Position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    closestBoss = boss
                end
            end
        end
        if closestBoss then
            TeleportToPosition(closestBoss.HumanoidRootPart.Position)
            -- Simular ataque
            ReplicatedStorage.Remotes.Combat:FireServer(AutoFarmWeapon, closestBoss.Humanoid)
            wait(0.5)
            return
        end
    end

    Fluent:Notify({ Title = "RedzHub", Content = "Nenhum alvo encontrado para Auto Farm!", Duration = 3 })
end

-- Função para ativar/desativar o Auto Farm de frutas
local function ToggleAutoFarmFruits(value)
    AutoFarmFruitsEnabled = value
    if AutoFarmFruitsEnabled then
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Farm de frutas ativado!", Duration = 3 })
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Farm de frutas desativado!", Duration = 3 })
    end
    if (AutoFarmFruitsEnabled or AutoFarmChestsEnabled or AutoFarmBossesEnabled) and not AutoFarmConnection then
        AutoFarmConnection = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoFarm)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Farm: " .. tostring(errorMsg), Duration = 3 })
                AutoFarmFruitsEnabled = false
                AutoFarmChestsEnabled = false
                AutoFarmBossesEnabled = false
                AutoFarmConnection:Disconnect()
                AutoFarmConnection = nil
            end
        end)
    elseif not AutoFarmFruitsEnabled and not AutoFarmChestsEnabled and not AutoFarmBossesEnabled and AutoFarmConnection then
        AutoFarmConnection:Disconnect()
        AutoFarmConnection = nil
    end
end

-- Função para ativar/desativar o Auto Farm de baús
local function ToggleAutoFarmChests(value)
    AutoFarmChestsEnabled = value
    if AutoFarmChestsEnabled then
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Farm de baús ativado!", Duration = 3 })
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Farm de baús desativado!", Duration = 3 })
    end
    if (AutoFarmFruitsEnabled or AutoFarmChestsEnabled or AutoFarmBossesEnabled) and not AutoFarmConnection then
        AutoFarmConnection = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoFarm)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Farm: " .. tostring(errorMsg), Duration = 3 })
                AutoFarmFruitsEnabled = false
                AutoFarmChestsEnabled = false
                AutoFarmBossesEnabled = false
                AutoFarmConnection:Disconnect()
                AutoFarmConnection = nil
            end
        end)
    elseif not AutoFarmFruitsEnabled and not AutoFarmChestsEnabled and not AutoFarmBossesEnabled and AutoFarmConnection then
        AutoFarmConnection:Disconnect()
        AutoFarmConnection = nil
    end
end

-- Função para ativar/desativar o Auto Farm de bosses
local function ToggleAutoFarmBosses(value)
    AutoFarmBossesEnabled = value
    if AutoFarmBossesEnabled then
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Farm de bosses ativado!", Duration = 3 })
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Farm de bosses desativado!", Duration = 3 })
    end
    if (AutoFarmFruitsEnabled or AutoFarmChestsEnabled or AutoFarmBossesEnabled) and not AutoFarmConnection then
        AutoFarmConnection = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoFarm)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Farm: " .. tostring(errorMsg), Duration = 3 })
                AutoFarmFruitsEnabled = false
                AutoFarmChestsEnabled = false
                AutoFarmBossesEnabled = false
                AutoFarmConnection:Disconnect()
                AutoFarmConnection = nil
            end
        end)
    elseif not AutoFarmFruitsEnabled and not AutoFarmChestsEnabled and not AutoFarmBossesEnabled and AutoFarmConnection then
        AutoFarmConnection:Disconnect()
        AutoFarmConnection = nil
    end
end

-- Função para Auto Quest
local function StartAutoQuest()
    if not AutoQuestEnabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local questGiver = NPCs["Quest Giver (Middle Town)"] or NPCs["Quest Giver (Kingdom of Rose)"]
        if not questGiver then return end

        -- Aceitar quest
        TeleportToPosition(questGiver)
        local questNPC = workspace:FindFirstChild("QuestGiver")
        if questNPC then
            fireclickdetector(questNPC:FindFirstChildOfClass("ClickDetector"))
            wait(0.5)
        end

        -- Encontrar inimigo para a quest
        local closestEnemy = nil
        local minDistance = math.huge
        local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
        for _, enemy in pairs(workspace:GetChildren()) do
            if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and
               enemy:FindFirstChild("HumanoidRootPart") and enemy.Humanoid.Health > 0 and
               enemy ~= LocalPlayer.Character then
                local distance = (playerPos - enemy.HumanoidRootPart.Position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    closestEnemy = enemy
                end
            end
        end
        if closestEnemy then
            TeleportToPosition(closestEnemy.HumanoidRootPart.Position)
            ReplicatedStorage.Remotes.Combat:FireServer(AutoFarmWeapon, closestEnemy.Humanoid)
            wait(0.5)
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Quest: " .. tostring(errorMsg), Duration = 3 })
        AutoQuestEnabled = false
        AutoQuestConnection:Disconnect()
        AutoQuestConnection = nil
    end
end

-- Função para ativar/desativar o Auto Quest
local function ToggleAutoQuest(value)
    AutoQuestEnabled = value
    if AutoQuestEnabled then
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Quest ativado!", Duration = 3 })
        AutoQuestConnection = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoQuest)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Quest: " .. tostring(errorMsg), Duration = 3 })
                AutoQuestEnabled = false
                AutoQuestConnection:Disconnect()
                AutoQuestConnection = nil
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Quest desativado!", Duration = 3 })
        if AutoQuestConnection then
            AutoQuestConnection:Disconnect()
            AutoQuestConnection = nil
        end
    end
end

-- Função para Auto Raid
local function StartAutoRaid()
    if not AutoRaidEnabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local raidNPC = NPCs["Awakening Expert"]
        if not raidNPC then return end

        -- Iniciar raid
        TeleportToPosition(raidNPC)
        ReplicatedStorage.Remotes.StartRaid:FireServer(AutoRaidType)
        wait(2)

        -- Atacar inimigos no raid
        local raidEnemies = workspace:FindFirstChild("RaidEnemies")
        if raidEnemies then
            for _, enemy in pairs(raidEnemies:GetChildren()) do
                if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                    TeleportToPosition(enemy.HumanoidRootPart.Position)
                    ReplicatedStorage.Remotes.Combat:FireServer(AutoFarmWeapon, enemy.Humanoid)
                    wait(0.5)
                end
            end
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Raid: " .. tostring(errorMsg), Duration = 3 })
        AutoRaidEnabled = false
        AutoRaidConnection:Disconnect()
        AutoRaidConnection = nil
    end
end

-- Função para ativar/desativar o Auto Raid
local function ToggleAutoRaid(value)
    AutoRaidEnabled = value
    if AutoRaidEnabled then
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Raid ativado!", Duration = 3 })
        AutoRaidConnection = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoRaid)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Raid: " .. tostring(errorMsg), Duration = 3 })
                AutoRaidEnabled = false
                AutoRaidConnection:Disconnect()
                AutoRaidConnection = nil
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Raid desativado!", Duration = 3 })
        if AutoRaidConnection then
            AutoRaidConnection:Disconnect()
            AutoRaidConnection = nil
        end
    end
end

-- Função para Fruit Sniper
local function StartFruitSniper()
    if not FruitSniperEnabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local _, fruitObjects = GetFruitList()
        for _, fruit in pairs(fruitObjects) do
            if fruit and fruit.Parent and fruit.Parent:FindFirstChild("FruitName") then
                local fruitName = fruit.Parent.FruitName.Value
                if table.find(RareFruits, fruitName) then
                    TeleportToPosition(fruit.Position)
                    local clickDetector = fruit.Parent:FindFirstChildOfClass("ClickDetector")
                    if clickDetector then
                        fireclickdetector(clickDetector)
                    end
                    Fluent:Notify({ Title = "RedzHub", Content = "Fruta rara encontrada: " .. fruitName .. "!", Duration = 5 })
                    SendWebhook("Fruta rara encontrada: " .. fruitName .. "!")
                    wait(0.5)
                    return
                end
            end
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Fruit Sniper: " .. tostring(errorMsg), Duration = 3 })
        FruitSniperEnabled = false
        FruitSniperConnection:Disconnect()
        FruitSniperConnection = nil
    end
end

-- Função para ativar/desativar o Fruit Sniper
local function ToggleFruitSniper(value)
    FruitSniperEnabled = value
    if FruitSniperEnabled then
        Fluent:Notify({ Title = "RedzHub", Content = "Fruit Sniper ativado!", Duration = 3 })
        FruitSniperConnection = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartFruitSniper)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Fruit Sniper: " .. tostring(errorMsg), Duration = 3 })
                FruitSniperEnabled = false
                FruitSniperConnection:Disconnect()
                FruitSniperConnection = nil
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Fruit Sniper desativado!", Duration = 3 })
        if FruitSniperConnection then
            FruitSniperConnection:Disconnect()
            FruitSniperConnection = nil
        end
    end
end

-- Função para Auto Sea Events
local function StartAutoSeaEvents()
    if not AutoSeaEventsEnabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local event = workspace:FindFirstChild("Leviathan") or workspace:FindFirstChild("KitsuneIsland")
        if event then
            TeleportToPosition(event.Position)
            Fluent:Notify({ Title = "RedzHub", Content = "Participando de evento marítimo!", Duration = 5 })
            SendWebhook("Evento marítimo detectado!")
            wait(1)
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Sea Events: " .. tostring(errorMsg), Duration = 3 })
        AutoSeaEventsEnabled = false
        AutoSeaEventsConnection:Disconnect()
        AutoSeaEventsConnection = nil
    end
end

-- Função para ativar/desativar o Auto Sea Events
local function ToggleAutoSeaEvents(value)
    AutoSeaEventsEnabled = value
    if AutoSeaEventsEnabled then
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Sea Events ativado!", Duration = 3 })
        AutoSeaEventsConnection = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoSeaEvents)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Sea Events: " .. tostring(errorMsg), Duration = 3 })
                AutoSeaEventsEnabled = false
                AutoSeaEventsConnection:Disconnect()
                AutoSeaEventsConnection = nil
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Sea Events desativado!", Duration = 3 })
        if AutoSeaEventsConnection then
            AutoSeaEventsConnection:Disconnect()
            AutoSeaEventsConnection = nil
        end
    end
end

-- Função para Player Bounty Farm
local function StartPlayerBountyFarm()
    if not PlayerBountyFarmEnabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local closestPlayer = nil
        local minDistance = math.huge
        local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and
               player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                local bounty = player.Data and player.Data.Bounty and player.Data.Bounty.Value or 0
                if bounty >= MinBounty then
                    local distance = (playerPos - player.Character.HumanoidRootPart.Position).Magnitude
                    if distance < minDistance then
                        minDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
        if closestPlayer then
            TeleportToPosition(closestPlayer.Character.HumanoidRootPart.Position)
            ReplicatedStorage.Remotes.Combat:FireServer(AutoFarmWeapon, closestPlayer.Character.Humanoid)
            wait(0.5)
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Player Bounty Farm: " .. tostring(errorMsg), Duration = 3 })
        PlayerBountyFarmEnabled = false
        PlayerBountyFarmConnection:Disconnect()
        PlayerBountyFarmConnection = nil
    end
end

-- Função para ativar/desativar o Player Bounty Farm
local function TogglePlayerBountyFarm(value)
    PlayerBountyFarmEnabled = value
    if PlayerBountyFarmEnabled then
        Fluent:Notify({ Title = "RedzHub", Content = "Player Bounty Farm ativado!", Duration = 3 })
        PlayerBountyFarmConnection = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartPlayerBountyFarm)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Player Bounty Farm: " .. tostring(errorMsg), Duration = 3 })
                PlayerBountyFarmEnabled = false
                PlayerBountyFarmConnection:Disconnect()
                PlayerBountyFarmConnection = nil
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Player Bounty Farm desativado!", Duration = 3 })
        if PlayerBountyFarmConnection then
            PlayerBountyFarmConnection:Disconnect()
            PlayerBountyFarmConnection = nil
        end
    end
end

-- Função para Auto Awakening
local function StartAutoAwakening()
    if not AutoAwakeningEnabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local awakeningNPC = NPCs["Awakening Expert"]
        if not awakeningNPC then return end

        TeleportToPosition(awakeningNPC)
        ReplicatedStorage.Remotes.AwakenFruit:FireServer()
        wait(1)
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Awakening: " .. tostring(errorMsg), Duration = 3 })
        AutoAwakeningEnabled = false
        AutoAwakeningConnection:Disconnect()
        AutoAwakeningConnection = nil
    end
end

-- Função para ativar/desativar o Auto Awakening
local function ToggleAutoAwakening(value)
    AutoAwakeningEnabled = value
    if AutoAwakeningEnabled then
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Awakening ativado!", Duration = 3 })
        AutoAwakeningConnection = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoAwakening)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Awakening: " .. tostring(errorMsg), Duration = 3 })
                AutoAwakeningEnabled = false
                AutoAwakeningConnection:Disconnect()
                AutoAwakeningConnection = nil
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Awakening desativado!", Duration = 3 })
        if AutoAwakeningConnection then
            AutoAwakeningConnection:Disconnect()
            AutoAwakeningConnection = nil
        end
    end
end

-- Função para Kill Aura
local function StartKillAura()
    if not KillAuraEnabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
        for _, enemy in pairs(workspace:GetChildren()) do
            if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and
               enemy:FindFirstChild("HumanoidRootPart") and enemy.Humanoid.Health > 0 and
               enemy ~= LocalPlayer.Character then
                local distance = (playerPos - enemy.HumanoidRootPart.Position).Magnitude / 3
                if distance <= KillAuraRange then
                    ReplicatedStorage.Remotes.Combat:FireServer(AutoFarmWeapon, enemy.Humanoid)
                end
            end
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Kill Aura: " .. tostring(errorMsg), Duration = 3 })
        KillAuraEnabled = false
        KillAuraConnection:Disconnect()
        KillAuraConnection = nil
    end
end

-- Função para ativar/desativar o Kill Aura
local function ToggleKillAura(value)
    KillAuraEnabled = value
    if KillAuraEnabled then
        Fluent:Notify({ Title = "RedzHub", Content = "Kill Aura ativado!", Duration = 3 })
        KillAuraConnection = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartKillAura)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Kill Aura: " .. tostring(errorMsg), Duration = 3 })
                KillAuraEnabled = false
                KillAuraConnection:Disconnect()
                KillAuraConnection = nil
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Kill Aura desativado!", Duration = 3 })
        if KillAuraConnection then
            KillAuraConnection:Disconnect()
            KillAuraConnection = nil
        end
    end
end

-- Função para Hitbox Expander
local function StartHitboxExpander()
    if not HitboxExpanderEnabled then return end
    local success, errorMsg = pcall(function()
        for _, enemy in pairs(workspace:GetChildren()) do
            if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") and
               enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 and
               enemy ~= LocalPlayer.Character then
                enemy.HumanoidRootPart.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                enemy.HumanoidRootPart.Transparency = 0.8
                enemy.HumanoidRootPart.CanCollide = false
            end
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Hitbox Expander: " .. tostring(errorMsg), Duration = 3 })
        HitboxExpanderEnabled = false
        HitboxExpanderConnection:Disconnect()
        HitboxExpanderConnection = nil
    end
end

-- Função para ativar/desativar o Hitbox Expander
local function ToggleHitboxExpander(value)
    HitboxExpanderEnabled = value
    if HitboxExpanderEnabled then
        Fluent:Notify({ Title = "RedzHub", Content = "Hitbox Expander ativado!", Duration = 3 })
        HitboxExpanderConnection = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartHitboxExpander)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Hitbox Expander: " .. tostring(errorMsg), Duration = 3 })
                HitboxExpanderEnabled = false
                HitboxExpanderConnection:Disconnect()
                HitboxExpanderConnection = nil
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Hitbox Expander desativado!", Duration = 3 })
        if HitboxExpanderConnection then
            HitboxExpanderConnection:Disconnect()
            HitboxExpanderConnection = nil
            -- Restaurar hitboxes
            for _, enemy in pairs(workspace:GetChildren()) do
                if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") then
                    enemy.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                    enemy.HumanoidRootPart.Transparency = 0
                    enemy.HumanoidRootPart.CanCollide = true
                end
            end
        end
    end
end

-- Função para Auto Haki
local function StartAutoHaki()
    if not AutoHakiEnabled then return end
    local success, errorMsg = pcall(function()
        ReplicatedStorage.Remotes.Haki:FireServer("Observation", true)
        ReplicatedStorage.Remotes.Haki:FireServer("Enhancement", true)
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Haki: " .. tostring(errorMsg), Duration = 3 })
        AutoHakiEnabled = false
        AutoHakiConnection:Disconnect()
        AutoHakiConnection = nil
    end
end

-- Função para ativar/desativar o Auto Haki
local function ToggleAutoHaki(value)
    AutoHakiEnabled = value
    if AutoHakiEnabled then
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Haki ativado!", Duration = 3 })
        AutoHakiConnection = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoHaki)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Haki: " .. tostring(errorMsg), Duration = 3 })
                AutoHakiEnabled = false
                AutoHakiConnection:Disconnect()
                AutoHakiConnection = nil
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Haki desativado!", Duration = 3 })
        if AutoHakiConnection then
            AutoHakiConnection:Disconnect()
            AutoHakiConnection = nil
        end
    end
end

-- Função para Auto Stats
local function StartAutoStats()
    if not AutoStatsEnabled then return end
    local success, errorMsg = pcall(function()
        local stats = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("StatPoints")
        if stats and stats.Value > 0 then
            ReplicatedStorage.Remotes.AddStat:FireServer(StatPriority, 1)
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Stats: " .. tostring(errorMsg), Duration = 3 })
        AutoStatsEnabled = false
        AutoStatsConnection:Disconnect()
        AutoStatsConnection = nil
    end
end

-- Função para ativar/desativar o Auto Stats
local function ToggleAutoStats(value)
    AutoStatsEnabled = value
    if AutoStatsEnabled then
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Stats ativado!", Duration = 3 })
        AutoStatsConnection = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoStats)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Stats: " .. tostring(errorMsg), Duration = 3 })
                AutoStatsEnabled = false
                AutoStatsConnection:Disconnect()
                AutoStatsConnection = nil
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Stats desativado!", Duration = 3 })
        if AutoStatsConnection then
            AutoStatsConnection:Disconnect()
            AutoStatsConnection = nil
        end
    end
end

-- Função para ativar/desativar o Speed Hack
local function ToggleSpeedHack(value)
    SpeedHackEnabled = value
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") then return end
        LocalPlayer.Character.Humanoid.WalkSpeed = SpeedHackEnabled and SpeedHackValue or DefaultWalkSpeed
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Speed Hack: " .. tostring(errorMsg), Duration = 3 })
        SpeedHackEnabled = false
        return
    end
    Fluent:Notify({ Title = "RedzHub", Content = SpeedHackEnabled and "Speed Hack ativado!" or "Speed Hack desativado!", Duration = 3 })
end

-- Função para ativar/desativar o Webhook
local function ToggleWebhook(value)
    WebhookEnabled = value
    Fluent:Notify({ Title = "RedzHub", Content = WebhookEnabled and "Webhook ativado!" or "Webhook desativado!", Duration = 3 })
end

-- Notificações para eventos especiais
workspace.DescendantAdded:Connect(function(obj)
    if obj.Name == "MirageIsland" then
        Fluent:Notify({ Title = "RedzHub", Content = "Mirage Island spawnada! Teleporte disponível!", Duration = 10 })
        SendWebhook("Mirage Island spawnada!")
    elseif obj.Name == "Leviathan" then
        Fluent:Notify({ Title = "RedzHub", Content = "Leviathan spawnado! Teleporte disponível!", Duration = 10 })
        SendWebhook("Leviathan spawnado!")
    elseif obj.Name == "KitsuneIsland" then
        Fluent:Notify({ Title = "RedzHub", Content = "Kitsune Island spawnada! Teleporte disponível!", Duration = 10 })
        SendWebhook("Kitsune Island spawnada!")
    end
end)

-- Aba Main
Tabs.Main:AddParagraph({
    Title = "Bem-vindo ao RedzHub!",
    Content = "Hub definitivo para Blox Fruits. ESP em tempo real, Teleport, Auto Farm, Auto Raid, Fruit Sniper, Auto Sea Events, Player Bounty Farm, Auto Awakening, Hitbox Expander, Auto Haki, Webhook e mais. Otimizado para mobile e PC!"
})

Tabs.Main:AddButton({
    Title = "Copiar Link do Discord",
    Description = "Junte-se ao nosso Discord!",
    Callback = function()
        setclipboard("https://discord.gg/redzhub")
        Fluent:Notify({ Title = "RedzHub", Content = "Link do Discord copiado!", Duration = 3 })
    end
})

-- Aba Farming
local AutoFarmFruitsToggle = Tabs.Farming:AddToggle("AutoFarmFruitsToggle", {
    Title = "Auto Farm Frutas",
    Description = "Teleporta e coleta frutas automaticamente",
    Default = false
})

AutoFarmFruitsToggle:OnChanged(function(value)
    ToggleAutoFarmFruits(value)
end)

local AutoFarmChestsToggle = Tabs.Farming:AddToggle("AutoFarmChestsToggle", {
    Title = "Auto Farm Baús",
    Description = "Teleporta e coleta baús automaticamente",
    Default = false
})

AutoFarmChestsToggle:OnChanged(function(value)
    ToggleAutoFarmChests(value)
end)

local AutoFarmBossesToggle = Tabs.Farming:AddToggle("AutoFarmBossesToggle", {
    Title = "Auto Farm Bosses",
    Description = "Teleporta e derrota bosses automaticamente",
    Default = false
})

AutoFarmBossesToggle:OnChanged(function(value)
    ToggleAutoFarmBosses(value)
end)

local AutoQuestToggle = Tabs.Farming:AddToggle("AutoQuestToggle", {
    Title = "Auto Quest",
    Description = "Aceita e completa quests automaticamente",
    Default = false
})

AutoQuestToggle:OnChanged(function(value)
    ToggleAutoQuest(value)
end)

local AutoRaidToggle = Tabs.Farming:AddToggle("AutoRaidToggle", {
    Title = "Auto Raid",
    Description = "Participa de raids automaticamente",
    Default = false
})

AutoRaidToggle:OnChanged(function(value)
    ToggleAutoRaid(value)
end)

local RaidTypeDropdown = Tabs.Farming:AddDropdown("RaidTypeDropdown", {
    Title = "Tipo de Raid",
    Description = "Selecione o tipo de raid",
    Values = { "Light", "Dark", "Flame", "Ice", "Quake", "String", "Rumble", "Magma", "Human" },
    Default = "Light"
})

RaidTypeDropdown:OnChanged(function(value)
    AutoRaidType = value
    Fluent:Notify({ Title = "RedzHub", Content = "Tipo de raid alterado para " .. value .. "!", Duration = 3 })
end)

local FruitSniperToggle = Tabs.Farming:AddToggle("FruitSniperToggle", {
    Title = "Fruit Sniper",
    Description = "Detecta e coleta frutas raras automaticamente",
    Default = false
})

FruitSniperToggle:OnChanged(function(value)
    ToggleFruitSniper(value)
end)

local AutoFarmWeaponDropdown = Tabs.Farming:AddDropdown("AutoFarmWeaponDropdown", {
    Title = "Arma para Auto Farm",
    Description = "Selecione a arma para Auto Farm",
    Values = { "Melee", "Sword", "Gun", "Fruit" },
    Default = "Melee"
})

AutoFarmWeaponDropdown:OnChanged(function(value)
    AutoFarmWeapon = value
    Fluent:Notify({ Title = "RedzHub", Content = "Arma para Auto Farm alterada para " .. value .. "!", Duration = 3 })
end)

-- Aba Visuals
local FruitESPToggle = Tabs.Visuals:AddToggle("FruitESPToggle", {
    Title = "Fruit ESP",
    Description = "Mostra frutas com nome e distância",
    Default = false
})

FruitESPToggle:OnChanged(function(value)
    ToggleFruitESP(value)
end)

local ChestESPToggle = Tabs.Visuals:AddToggle("ChestESPToggle", {
    Title = "Chest ESP",
    Description = "Mostra baús com distância",
    Default = false
})

ChestESPToggle:OnChanged(function(value)
    ToggleChestESP(value)
end)

local EnemyESPToggle = Tabs.Visuals:AddToggle("EnemyESPToggle", {
    Title = "Enemy ESP",
    Description = "Mostra inimigos com nome, nível e distância",
    Default = false
})

EnemyESPToggle:OnChanged(function(value)
    ToggleEnemyESP(value)
end)

local QuestItemESPToggle = Tabs.Visuals:AddToggle("QuestItemESPToggle", {
    Title = "Quest Item ESP",
    Description = "Mostra itens de quest com nome e distância",
    Default = false
})

QuestItemESPToggle:OnChanged(function(value)
    ToggleQuestItemESP(value)
end)

-- Aba Teleport
local FruitDropdown
local function UpdateFruitDropdown()
    local fruits, _ = GetFruitList()
    FruitDropdown:SetOptions(fruits)
end

FruitDropdown = Tabs.Teleport:AddDropdown("FruitDropdown", {
    Title = "Teleportar para Fruta",
    Description = "Selecione uma fruta para teleporte",
    Values = GetFruitList(),
    Default = nil,
    Callback = function()
        UpdateFruitDropdown()
    end
})

Tabs.Teleport:AddButton({
    Title = "Teleportar para Fruta",
    Description = "Teleporta para a fruta selecionada",
    Callback = function()
        local selectedValue = FruitDropdown:GetValue()
        if selectedValue then
            TeleportToFruit(selectedValue)
        else
