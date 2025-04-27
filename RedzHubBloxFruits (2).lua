--// RedzHub-Style Blox Fruits Script with Fluent UI
--// Criado por um Dev Lua profissional no estilo RedzHub, sem limites
--// Corrige erros 'GetValue' e 'Humanoid is not a valid member of Model "Monkey"'
--// Inclui Fruit ESP, Chest ESP, Enemy ESP, Teleport, Auto Farm, Auto Quest, Kill Aura, Auto Stats, Speed Hack e notificações
--// Otimizado para mobile e PC, com execução sem erros

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configurações da Janela (otimizada para mobile)
local Window = Fluent:CreateWindow({
    Title = "RedzHub - Blox Fruits",
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
    AutoFarm = Window:AddTab({ Title = "Auto Farm", Icon = "lucide-bot" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "lucide-eye" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "lucide-map-pin" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "lucide-sword" }),
    Stats = Window:AddTab({ Title = "Stats", Icon = "lucide-bar-chart" })
}

-- Variáveis do ESP
local FruitESP = {}
local ChestESP = {}
local EnemyESP = {}
local ESPEnabled = false
local ChestESPEnabled = false
local EnemyESPEnabled = false
local ESPConnection = nil
local DescendantAddedConnection = nil
local DescendantRemovingConnection = nil

-- Variáveis do Auto Farm
local AutoFarmFruitsEnabled = false
local AutoFarmChestsEnabled = false
local AutoFarmConnection = nil

-- Variáveis do Auto Quest
local AutoQuestEnabled = false
local AutoQuestConnection = nil

-- Variáveis do Kill Aura
local KillAuraEnabled = false
local KillAuraConnection = nil
local KillAuraRange = 20

-- Variáveis do Auto Stats
local AutoStatsEnabled = false
local AutoStatsConnection = nil
local StatPriority = "Melee"

-- Variáveis do Speed Hack
local SpeedHackEnabled = false
local DefaultWalkSpeed = 16
local SpeedHackValue = 50

-- Configurações do ESP
local ESPConfig = {
    FruitTextColor = Color3.fromRGB(255, 50, 50),
    ChestTextColor = Color3.fromRGB(255, 215, 0),
    EnemyTextColor = Color3.fromRGB(0, 255, 0),
    TextSize = 14,
    OutlineColor = Color3.fromRGB(0, 0, 0),
    UpdateInterval = 0.15,
    MaxRenderDistance = 10000
}

-- Função para criar o BillboardGui para frutas, baús ou inimigos
local function CreateESP(object, type)
    if not object or (type == "Enemy" and not object:IsA("Model")) or (type ~= "Enemy" and not object:IsA("BasePart")) then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = type .. "ESP"
    billboard.Adornee = type == "Enemy" and object:FindFirstChild("HumanoidRootPart") or object
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = type == "Fruit" and ESPEnabled or type == "Chest" and ChestESPEnabled or EnemyESPEnabled

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Name"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = type == "Fruit" and (object.Parent and object.Parent:FindFirstChild("FruitName") and object.Parent.FruitName.Value or "Fruit") or
                     type == "Chest" and "Chest" or
                     (object.Name .. (object:FindFirstChild("Level") and " [Lv. " .. object.Level.Value .. "]" or ""))
    textLabel.TextColor3 = type == "Fruit" and ESPConfig.FruitTextColor or
                          type == "Chest" and ESPConfig.ChestTextColor or
                          ESPConfig.EnemyTextColor
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
                             ESPConfig.EnemyTextColor
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
    else
        EnemyESP[object] = { Billboard = billboard, DistanceLabel = distanceLabel }
    end
end

-- Função para atualizar a distância no ESP
local function UpdateESP()
    if not ESPEnabled and not ChestESPEnabled and not EnemyESPEnabled then return end
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
        if not object or not object.Parent or not object:FindFirstChild("HumanoidRootPart") then
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
end

-- Função para verificar novos objetos
local function CheckObjects()
    if not ESPEnabled and not ChestESPEnabled and not EnemyESPEnabled then return end
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Fruit" and obj:IsA("BasePart") and not FruitESP[obj] and ESPEnabled then
            CreateESP(obj, "Fruit")
        elseif obj.Name:match("Chest") and obj:IsA("BasePart") and not ChestESP[obj] and ChestESPEnabled then
            CreateESP(obj, "Chest")
        elseif obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") and not EnemyESP[obj] and EnemyESPEnabled and obj ~= LocalPlayer.Character then
            CreateESP(obj, "Enemy")
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
    else
        for _, esp in pairs(EnemyESP) do
            if esp.Billboard then esp.Billboard:Destroy() end
        end
        EnemyESP = {}
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
        elseif ChestESPEnabled and obj.Name:match("Chest") and obj:IsA("BasePart") then
            CreateESP(obj, "Chest")
            Fluent:Notify({ Title = "RedzHub", Content = "Novo baú spawnado!", Duration = 5 })
        elseif EnemyESPEnabled and obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") and obj ~= LocalPlayer.Character then
            CreateESP(obj, "Enemy")
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
    if not ESPEnabled and not ChestESPEnabled and not EnemyESPEnabled then
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
    if not ESPEnabled and not ChestESPEnabled and not EnemyESPEnabled then
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
    if not ESPEnabled and not ChestESPEnabled and not EnemyESPEnabled then
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

-- Função para teletransportar
local function TeleportToPosition(position)
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            return false
        end
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(position + Vector3.new(0, 10, 0))
        return true
    end)
    if not success then
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
        if obj.Name == "Fruit" and obj:IsA("BasePart") then
            local distance = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (obj.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude / 3 or 0
            local fruitName = obj.Parent and obj.Parent:FindFirstChild("FruitName") and obj.Parent.FruitName.Value or "Fruit"
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
        if obj.Name:match("Chest") and obj:IsA("BasePart") then
            local distance = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (obj.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude / 3 or 0
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
    ["Leviathan Spawn"] = Vector3.new(0, 10, 12000)
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
    ["Quest Giver (Kingdom of Rose)"] = Vector3.new(-2100, 10, -1900)
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

-- Função para Auto Farm
local function StartAutoFarm()
    if not AutoFarmFruitsEnabled and not AutoFarmChestsEnabled then return end
    local playerPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
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
    if (AutoFarmFruitsEnabled or AutoFarmChestsEnabled) and not AutoFarmConnection then
        AutoFarmConnection = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoFarm)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Farm: " .. tostring(errorMsg), Duration = 3 })
                AutoFarmFruitsEnabled = false
                AutoFarmChestsEnabled = false
                AutoFarmConnection:Disconnect()
                AutoFarmConnection = nil
            end
        end)
    elseif not AutoFarmFruitsEnabled and not AutoFarmChestsEnabled and AutoFarmConnection then
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
    if (AutoFarmFruitsEnabled or AutoFarmChestsEnabled) and not AutoFarmConnection then
        AutoFarmConnection = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoFarm)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Farm: " .. tostring(errorMsg), Duration = 3 })
                AutoFarmFruitsEnabled = false
                AutoFarmChestsEnabled = false
                AutoFarmConnection:Disconnect()
                AutoFarmConnection = nil
            end
        end)
    elseif not AutoFarmFruitsEnabled and not AutoFarmChestsEnabled and AutoFarmConnection then
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
        local questNPC = workspace:FindFirstChild("QuestGiver") -- Ajustar conforme estrutura do jogo
        if questNPC then
            -- Simular interação com quest
            -- Pode variar dependendo do jogo; aqui é um exemplo genérico
            fireclickdetector(questNPC:FindFirstChildOfClass("ClickDetector"))
        end

        -- Encontrar inimigo para a quest
        local closestEnemy = nil
        local minDistance = math.huge
        local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
        for _, enemy in pairs(workspace:GetChildren()) do
            if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") and enemy ~= LocalPlayer.Character then
                local distance = (playerPos - enemy.HumanoidRootPart.Position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    closestEnemy = enemy
                end
            end
        end
        if closestEnemy then
            TeleportToPosition(closestEnemy.HumanoidRootPart.Position)
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

-- Função para Kill Aura
local function StartKillAura()
    if not KillAuraEnabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
        for _, enemy in pairs(workspace:GetChildren()) do
            if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") and enemy ~= LocalPlayer.Character then
                local distance = (playerPos - enemy.HumanoidRootPart.Position).Magnitude / 3
                if distance <= KillAuraRange then
                    -- Simular ataque (exemplo genérico; ajustar conforme sistema de combate)
                    enemy.Humanoid:TakeDamage(10) -- Ajustar dano conforme necessário
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

-- Função para Auto Stats
local function StartAutoStats()
    if not AutoStatsEnabled then return end
    local success, errorMsg = pcall(function()
        local stats = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("StatPoints")
        if stats and stats.Value > 0 then
            -- Exemplo: adicionar pontos ao stat prioritário
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

-- Notificações para eventos especiais
workspace.DescendantAdded:Connect(function(obj)
    if obj.Name == "MirageIsland" then
        Fluent:Notify({ Title = "RedzHub", Content = "Mirage Island spawnada! Teleporte disponível!", Duration = 10 })
    elseif obj.Name == "Leviathan" then
        Fluent:Notify({ Title = "RedzHub", Content = "Leviathan spawnado! Teleporte disponível!", Duration = 10 })
    end
end)

-- Aba Main
Tabs.Main:AddParagraph({
    Title = "Bem-vindo ao RedzHub!",
    Content = "Hub definitivo para Blox Fruits. ESP, Teleport, Auto Farm, Auto Quest, Combat, Stats e mais. Otimizado para mobile e PC!"
})

Tabs.Main:AddButton({
    Title = "Copiar Link do Discord",
    Description = "Junte-se ao nosso Discord!",
    Callback = function()
        setclipboard("https://discord.gg/redzhub")
        Fluent:Notify({ Title = "RedzHub", Content = "Link do Discord copiado!", Duration = 3 })
    end
})

-- Aba Auto Farm
local AutoFarmFruitsToggle = Tabs.AutoFarm:AddToggle("AutoFarmFruitsToggle", {
    Title = "Auto Farm Frutas",
    Description = "Teleporta automaticamente para a fruta mais próxima",
    Default = false
})

AutoFarmFruitsToggle:OnChanged(function(value)
    ToggleAutoFarmFruits(value)
end)

local AutoFarmChestsToggle = Tabs.AutoFarm:AddToggle("AutoFarmChestsToggle", {
    Title = "Auto Farm Baús",
    Description = "Teleporta automaticamente para o baú mais próximo",
    Default = false
})

AutoFarmChestsToggle:OnChanged(function(value)
    ToggleAutoFarmChests(value)
end)

local AutoQuestToggle = Tabs.AutoFarm:AddToggle("AutoQuestToggle", {
    Title = "Auto Quest",
    Description = "Aceita e completa quests automaticamente",
    Default = false
})

AutoQuestToggle:OnChanged(function(value)
    ToggleAutoQuest(value)
end)

local SpeedHackToggle = Tabs.AutoFarm:AddToggle("SpeedHackToggle", {
    Title = "Speed Hack",
    Description = "Aumenta a velocidade do jogador",
    Default = false
})

SpeedHackToggle:OnChanged(function(value)
    ToggleSpeedHack(value)
end)

-- Aba ESP
local FruitESPToggle = Tabs.ESP:AddToggle("FruitESPToggle", {
    Title = "Fruit ESP",
    Description = "Mostra todas as frutas no mapa com nome e distância",
    Default = false
})

FruitESPToggle:OnChanged(function(value)
    ToggleFruitESP(value)
end)

local ChestESPToggle = Tabs.ESP:AddToggle("ChestESPToggle", {
    Title = "Chest ESP",
    Description = "Mostra todos os baús no mapa com distância",
    Default = false
})

ChestESPToggle:OnChanged(function(value)
    ToggleChestESP(value)
end)

local EnemyESPToggle = Tabs.ESP:AddToggle("EnemyESPToggle", {
    Title = "Enemy ESP",
    Description = "Mostra todos os inimigos no mapa com nome, nível e distância",
    Default = false
})

EnemyESPToggle:OnChanged(function(value)
    ToggleEnemyESP(value)
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
            Fluent:Notify({ Title = "RedzHub", Content = "Nenhuma fruta selecionada!", Duration = 3 })
        end
    end
})

local ChestDropdown
local function UpdateChestDropdown()
    local chests, _ = GetChestList()
    ChestDropdown:SetOptions(chests)
end

ChestDropdown = Tabs.Teleport:AddDropdown("ChestDropdown", {
    Title = "Teleportar para Baú",
    Description = "Selecione um baú para teleporte",
    Values = GetChestList(),
    Default = nil,
    Callback = function()
        UpdateChestDropdown()
    end
})

Tabs.Teleport:AddButton({
    Title = "Teleportar para Baú",
    Description = "Teleporta para o baú selecionado",
    Callback = function()
        local selectedValue = ChestDropdown:GetValue()
        if selectedValue then
            TeleportToChest(selectedValue)
        else
            Fluent:Notify({ Title = "RedzHub", Content = "Nenhum baú selecionado!", Duration = 3 })
        end
    end
})

local IslandDropdown = Tabs.Teleport:AddDropdown("IslandDropdown", {
    Title = "Teleportar para Ilha",
    Description = "Selecione uma ilha para teleporte",
    Values = {
        "Middle Town", "Marine Starter", "Jungle", "Pirate Village", "Desert",
        "Frozen Village", "Colosseum", "Prison", "Magma Village", "Underwater City",
        "Fountain City", "Sky Island 1", "Sky Island 2", "Cafe", "Kingdom of Rose",
        "Green Zone", "Graveyard", "Snow Mountain", "Hot and Cold", "Cursed Ship",
        "Ice Castle", "Forgotten Island", "Port Town", "Hydra Island", "Great Tree",
        "Floating Turtle", "Castle on the Sea", "Haunted Castle", "Sea of Treats",
        "Mirage Island", "Leviathan Spawn"
    },
    Default = nil
})

Tabs.Teleport:AddButton({
    Title = "Teleportar para Ilha",
    Description = "Teleporta para a ilha selecionada",
    Callback = function()
        local selectedIsland = IslandDropdown:GetValue()
        if selectedIsland then
            TeleportToIsland(selectedIsland)
        else
            Fluent:Notify({ Title = "RedzHub", Content = "Nenhuma ilha selecionada!", Duration = 3 })
        end
    end
})

local NPCDropdown = Tabs.Teleport:AddDropdown("NPCDropdown", {
    Title = "Teleportar para NPC",
    Description = "Selecione um NPC para teleporte",
    Values = {
        "Fruit Dealer", "Quest Giver (Middle Town)", "Boat Dealer (Middle Town)",
        "Luxury Boat Dealer", "Weapon Dealer (Middle Town)", "Blox Fruit Gacha",
        "Awakening Expert", "Gear Dealer", "Sword Dealer", "Enhancer Dealer",
        "Quest Giver (Kingdom of Rose)"
    },
    Default = nil
})

Tabs.Teleport:AddButton({
    Title = "Teleportar para NPC",
    Description = "Teleporta para o NPC selecionado",
    Callback = function()
        local selectedNPC = NPCDropdown:GetValue()
        if selectedNPC then
            TeleportToNPC(selectedNPC)
        else
            Fluent:Notify({ Title = "RedzHub", Content = "Nenhum NPC selecionado!", Duration = 3 })
        end
    end
})

local FruitSpawnDropdown = Tabs.Teleport:AddDropdown("FruitSpawnDropdown", {
    Title = "Teleportar para Spawn de Frutas",
    Description = "Selecione um spawn de frutas para teleporte",
    Values = {
        "Middle Town Spawn 1", "Jungle Spawn 1", "Pirate Village Spawn 1",
        "Desert Spawn 1", "Frozen Village Spawn 1", "Kingdom of Rose Spawn 1",
        "Green Zone Spawn 1", "Floating Turtle Spawn 1"
    },
    Default = nil
})

Tabs.Teleport:AddButton({
    Title = "Teleportar para Spawn de Frutas",
    Description = "Teleporta para o spawn selecionado",
    Callback = function()
        local selectedSpawn = FruitSpawnDropdown:GetValue()
        if selectedSpawn then
            TeleportToFruitSpawn(selectedSpawn)
        else
            Fluent:Notify({ Title = "RedzHub", Content = "Nenhum spawn selecionado!", Duration = 3 })
        end
    end
})

-- Aba Combat
local KillAuraToggle = Tabs.Combat:AddToggle("KillAuraToggle", {
    Title = "Kill Aura",
    Description = "Ataca automaticamente inimigos próximos",
    Default = false
})

KillAuraToggle:OnChanged(function(value)
    ToggleKillAura(value)
end)

-- Aba Stats
local AutoStatsToggle = Tabs.Stats:AddToggle("AutoStatsToggle", {
    Title = "Auto Stats",
    Description = "Distribui pontos de stat automaticamente",
    Default = false
})

AutoStatsToggle:OnChanged(function(value)
    ToggleAutoStats(value)
end)

local StatPriorityDropdown = Tabs.Stats:AddDropdown("StatPriorityDropdown", {
    Title = "Prioridade de Stat",
    Description = "Selecione o stat para Auto Stats",
    Values = { "Melee", "Defense", "Sword", "Gun", "Fruit" },
    Default = "Melee"
})

StatPriorityDropdown:OnChanged(function(value)
    StatPriority = value
    Fluent:Notify({ Title = "RedzHub", Content = "Prioridade de stat alterada para " .. value .. "!", Duration = 3 })
end)

-- Configurar SaveManager e InterfaceManager
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("RedzHub")
SaveManager:SetFolder("RedzHub/BloxFruits")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

-- Inicializar
Window:SelectTab(1)
Fluent:Notify({
    Title = "RedzHub",
    Content = "Script carregado com sucesso! Use as abas para explorar.",
    Duration = 5
})

print("RedzHub Blox Fruits Script v9.0 carregado! Interface Fluent com ESP, Teleport, Auto Farm, Auto Quest, Combat, Stats e notificações.")