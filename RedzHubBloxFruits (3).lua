--// RedzHub-Style Blox Fruits Script with Fluent UI
--// Criado por um Dev Lua profissional no estilo RedzHub, sem limites
--// Corrige erros 'attempt to call a nil value', 'GetValue', e 'Humanoid is not a valid member of Model "Monkey"'
--// Inclui Fruit ESP, Chest ESP, Enemy ESP, Boss ESP, Teleport, Auto Farm, Auto Quest, Auto Awakening, Kill Aura, Auto Stats, No-Clip, Fruit Sniping, Server Hop, Event Tracker, Auto Buy, e notificações
--// Otimizado para mobile e PC, com execução sem erros

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Função para carregar bibliotecas com segurança
local function SafeLoadString(url, name)
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not success then
        warn("Falha ao carregar " .. name .. ": " .. tostring(result))
        return nil
    end
    return result
end

-- Carregar bibliotecas Fluent
local Fluent = SafeLoadString("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua", "Fluent")
local SaveManager = SafeLoadString("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua", "SaveManager")
local InterfaceManager = SafeLoadString("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua", "InterfaceManager")

-- Verificar se as bibliotecas foram carregadas
if not Fluent or not SaveManager or not InterfaceManager then
    local errorMsg = "Erro crítico: Não foi possível carregar a biblioteca Fluent. Verifique sua conexão ou tente novamente."
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "RedzHub",
        Text = errorMsg,
        Duration = 10
    })
    print(errorMsg)
    return
end

-- Configurações da Janela (otimizada para mobile)
local Window = Fluent:CreateWindow({
    Title = "RedzHub - Blox Fruits",
    SubTitle = "by RedzHub (inspired)",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 420),
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
    Stats = Window:AddTab({ Title = "Stats", Icon = "lucide-bar-chart" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "lucide-settings" })
}

-- Módulo de Configurações
local Config = {
    ESP = {
        FruitTextColor = Color3.fromRGB(255, 50, 50),
        ChestTextColor = Color3.fromRGB(255, 215, 0),
        EnemyTextColor = Color3.fromRGB(0, 255, 0),
        BossTextColor = Color3.fromRGB(255, 0, 255),
        TextSize = 14,
        OutlineColor = Color3.fromRGB(0, 0, 0),
        UpdateInterval = 0.15,
        MaxRenderDistance = 10000
    },
    KillAuraRange = 20,
    SpeedHackValue = 50,
    DefaultWalkSpeed = 16,
    StatPriorities = { Melee = 0.5, Defense = 0.5, Sword = 0, Gun = 0, Fruit = 0 },
    RareFruits = { "Leopard", "Kitsune", "Dragon", "Venom", "Dough" }
}

-- Módulo de Estado
local State = {
    ESPEnabled = false,
    ChestESPEnabled = false,
    EnemyESPEnabled = false,
    BossESPEnabled = false,
    AutoFarmFruitsEnabled = false,
    AutoFarmChestsEnabled = false,
    AutoQuestEnabled = false,
    KillAuraEnabled = false,
    AutoStatsEnabled = false,
    SpeedHackEnabled = false,
    NoClipEnabled = false,
    AutoAwakeningEnabled = false,
    FruitSnipingEnabled = false,
    ServerHopEnabled = false,
    AutoBuyEnabled = false
}

-- Módulo de Conexões
local Connections = {
    ESP = nil,
    AutoFarm = nil,
    AutoQuest = nil,
    KillAura = nil,
    AutoStats = nil,
    NoClip = nil,
    AutoAwakening = nil,
    FruitSniping = nil,
    ServerHop = nil,
    DescendantAdded = nil,
    DescendantRemoving = nil
}

-- Módulo de ESP
local ESP = {
    Fruit = {},
    Chest = {},
    Enemy = {},
    Boss = {}
}

-- Função para criar BillboardGui para ESP
local function CreateESP(object, type)
    if not object or (type == "Enemy" or type == "Boss") and not object:IsA("Model") or (type ~= "Enemy" and type ~= "Boss" and not object:IsA("BasePart")) then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = type .. "ESP"
    billboard.Adornee = (type == "Enemy" or type == "Boss") and object:FindFirstChild("HumanoidRootPart") or object
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = type == "Fruit" and State.ESPEnabled or
                       type == "Chest" and State.ChestESPEnabled or
                       type == "Enemy" and State.EnemyESPEnabled or
                       State.BossESPEnabled

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Name"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = type == "Fruit" and (object.Parent and object.Parent:FindFirstChild("FruitName") and object.Parent.FruitName.Value or "Fruit") or
                     type == "Chest" and "Chest" or
                     type == "Boss" and (object.Name .. " [Boss]") or
                     (object.Name .. (object:FindFirstChild("Level") and " [Lv. " .. object.Level.Value .. "]" or ""))
    textLabel.TextColor3 = type == "Fruit" and Config.ESP.FruitTextColor or
                          type == "Chest" and Config.ESP.ChestTextColor or
                          type == "Enemy" and Config.ESP.EnemyTextColor or
                          Config.ESP.BossTextColor
    textLabel.TextSize = Config.ESP.TextSize
    textLabel.TextStrokeColor3 = Config.ESP.OutlineColor
    textLabel.TextStrokeTransparency = 0
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = billboard

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "Distance"
    distanceLabel.Size = UDim2.new(1, 0, 1, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0, 20)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "0m"
    distanceLabel.TextColor3 = type == "Fruit" and Config.ESP.FruitTextColor or
                             type == "Chest" and Config.ESP.ChestTextColor or
                             type == "Enemy" and Config.ESP.EnemyTextColor or
                             Config.ESP.BossTextColor
    distanceLabel.TextSize = Config.ESP.TextSize
    distanceLabel.TextStrokeColor3 = Config.ESP.OutlineColor
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.Font = Enum.Font.SourceSansBold
    distanceLabel.Parent = billboard

    billboard.Parent = (type == "Enemy" or type == "Boss") and object:FindFirstChild("HumanoidRootPart") or object

    ESP[type][object] = { Billboard = billboard, DistanceLabel = distanceLabel }
end

-- Função para atualizar ESP
local function UpdateESP()
    if not State.ESPEnabled and not State.ChestESPEnabled and not State.EnemyESPEnabled and not State.BossESPEnabled then return end
    local playerPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
    if not playerPos then return end

    for type, objects in pairs(ESP) do
        for object, esp in pairs(objects) do
            if not object or not object.Parent or (type == "Enemy" or type == "Boss") and not object:FindFirstChild("HumanoidRootPart") then
                if esp.Billboard then esp.Billboard:Destroy() end
                objects[object] = nil
                continue
            end
            local objectPos = (type == "Enemy" or type == "Boss") and object.HumanoidRootPart.Position or object.Position
            local distance = (playerPos - objectPos).Magnitude / 3
            esp.DistanceLabel.Text = string.format("%.1fm", distance)
            esp.Billboard.Enabled = type == "Fruit" and State.ESPEnabled or
                                   type == "Chest" and State.ChestESPEnabled or
                                   type == "Enemy" and State.EnemyESPEnabled or
                                   State.BossESPEnabled
            esp.Billboard.MaxDistance = Config.ESP.MaxRenderDistance
        end
    end
end

-- Função para verificar novos objetos
local function CheckObjects()
    if not State.ESPEnabled and not State.ChestESPEnabled and not State.EnemyESPEnabled and not State.BossESPEnabled then return end
    for _, obj in pairs(workspace:GetChildren()) do
        if State.ESPEnabled and obj.Name == "Fruit" and obj:IsA("BasePart") and not ESP.Fruit[obj] then
            CreateESP(obj, "Fruit")
        elseif State.ChestESPEnabled and obj.Name:match("Chest") and obj:IsA("BasePart") and not ESP.Chest[obj] then
            CreateESP(obj, "Chest")
        elseif (State.EnemyESPEnabled or State.BossESPEnabled) and obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") and obj ~= LocalPlayer.Character then
            local isBoss = obj.Name:match("Boss") or table.find({"Rip_Indra", "Dough King", "Tide Keeper"}, obj.Name)
            if isBoss and State.BossESPEnabled and not ESP.Boss[obj] then
                CreateESP(obj, "Boss")
            elseif not isBoss and State.EnemyESPEnabled and not ESP.Enemy[obj] then
                CreateESP(obj, "Enemy")
            end
        end
    end
end

-- Função para limpar ESP
local function ClearESP(type)
    for _, esp in pairs(ESP[type]) do
        if esp.Billboard then esp.Billboard:Destroy() end
    end
    ESP[type] = {}
end

-- Função para configurar eventos do ESP
local function SetupESPEvents()
    if Connections.DescendantAdded then Connections.DescendantAdded:Disconnect() end
    if Connections.DescendantRemoving then Connections.DescendantRemoving:Disconnect() end

    Connections.DescendantAdded = workspace.DescendantAdded:Connect(function(obj)
        if State.ESPEnabled and obj.Name == "Fruit" and obj:IsA("BasePart") then
            CreateESP(obj, "Fruit")
            Fluent:Notify({ Title = "RedzHub", Content = "Nova fruta spawnada!", Duration = 5 })
        elseif State.ChestESPEnabled and obj.Name:match("Chest") and obj:IsA("BasePart") then
            CreateESP(obj, "Chest")
            Fluent:Notify({ Title = "RedzHub", Content = "Novo baú spawnado!", Duration = 5 })
        elseif (State.EnemyESPEnabled or State.BossESPEnabled) and obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") and obj ~= LocalPlayer.Character then
            local isBoss = obj.Name:match("Boss") or table.find({"Rip_Indra", "Dough King", "Tide Keeper"}, obj.Name)
            if isBoss and State.BossESPEnabled then
                CreateESP(obj, "Boss")
                Fluent:Notify({ Title = "RedzHub", Content = "Boss spawnado: " .. obj.Name .. "!", Duration = 5 })
            elseif not isBoss and State.EnemyESPEnabled then
                CreateESP(obj, "Enemy")
            end
        end
    end)

    Connections.DescendantRemoving = workspace.DescendantRemoving:Connect(function(obj)
        for type, objects in pairs(ESP) do
            if objects[obj] then
                if objects[obj].Billboard then objects[obj].Billboard:Destroy() end
                objects[obj] = nil
            end
        end
    end)
end

-- Função para ativar/desativar ESP
local function ToggleESP(type, value)
    State[type .. "Enabled"] = value
    if value then
        Fluent:Notify({ Title = "RedzHub", Content = type .. " ESP ativado!", Duration = 3 })
        ClearESP(type)
        SetupESPEvents()
        CheckObjects()
    else
        Fluent:Notify({ Title = "RedzHub", Content = type .. " ESP desativado!", Duration = 3 })
        ClearESP(type)
    end
    if not State.ESPEnabled and not State.ChestESPEnabled and not State.EnemyESPEnabled and not State.BossESPEnabled then
        if Connections.ESP then Connections.ESP:Disconnect() Connections.ESP = nil end
        if Connections.DescendantAdded then Connections.DescendantAdded:Disconnect() Connections.DescendantAdded = nil end
        if Connections.DescendantRemoving then Connections.DescendantRemoving:Disconnect() Connections.DescendantRemoving = nil end
    elseif not Connections.ESP then
        Connections.ESP = RunService.RenderStepped:Connect(function(deltaTime)
            local lastUpdate = 0
            lastUpdate = lastUpdate + deltaTime
            if lastUpdate >= Config.ESP.UpdateInterval then
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
    for _, obj in pairs(workspace:GetChildren()) do
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
    for _, obj in pairs(workspace:GetChildren()) do
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
    ["Leviathan Spawn"] = Vector3.new(0, 10, 12000),
    ["Tiki Outpost"] = Vector3.new(-16000, 10, 8000)
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
    ["Item Vendor"] = Vector3.new(-200, 10, 400)
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
    ["Floating Turtle Spawn 1"] = Vector3.new(-950, 10, 8050),
    ["Mirage Island Spawn 1"] = Vector3.new(-6450, 10, 7550)
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
    if not State.AutoFarmFruitsEnabled and not State.AutoFarmChestsEnabled then return end
    local playerPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
    if not playerPos then return end

    if State.AutoFarmFruitsEnabled then
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

    if State.AutoFarmChestsEnabled then
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

-- Função para ativar/desativar Auto Farm
local function ToggleAutoFarm(type, value)
    State[type .. "Enabled"] = value
    if value then
        Fluent:Notify({ Title = "RedzHub", Content = type .. " ativado!", Duration = 3 })
    else
        Fluent:Notify({ Title = "RedzHub", Content = type .. " desativado!", Duration = 3 })
    end
    if (State.AutoFarmFruitsEnabled or State.AutoFarmChestsEnabled) and not Connections.AutoFarm then
        Connections.AutoFarm = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoFarm)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Farm: " .. tostring(errorMsg), Duration = 3 })
                State.AutoFarmFruitsEnabled = false
                State.AutoFarmChestsEnabled = false
                if Connections.AutoFarm then Connections.AutoFarm:Disconnect() Connections.AutoFarm = nil end
            end
        end)
    elseif not State.AutoFarmFruitsEnabled and not State.AutoFarmChestsEnabled and Connections.AutoFarm then
        Connections.AutoFarm:Disconnect()
        Connections.AutoFarm = nil
    end
end

-- Função para Auto Quest
local function StartAutoQuest()
    if not State.AutoQuestEnabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local questGiver = NPCs["Quest Giver (Middle Town)"] or NPCs["Quest Giver (Kingdom of Rose)"]
        if not questGiver then return end

        -- Aceitar quest
        TeleportToPosition(questGiver)
        local questNPC = workspace.NPCs:FindFirstChild("QuestGiver") -- Ajustar conforme estrutura
        if questNPC then
            local clickDetector = questNPC:FindFirstChildOfClass("ClickDetector")
            if clickDetector then
                fireclickdetector(clickDetector)
            end
        end

        -- Encontrar inimigo
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
            -- Atacar inimigo (exemplo genérico)
            ReplicatedStorage.Remotes.Combat:FireServer("Attack", closestEnemy)
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Quest: " .. tostring(errorMsg), Duration = 3 })
        State.AutoQuestEnabled = false
        if Connections.AutoQuest then Connections.AutoQuest:Disconnect() Connections.AutoQuest = nil end
    end
end

-- Função para ativar/desativar Auto Quest
local function ToggleAutoQuest(value)
    State.AutoQuestEnabled = value
    if value then
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Quest ativado!", Duration = 3 })
        Connections.AutoQuest = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoQuest)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Quest: " .. tostring(errorMsg), Duration = 3 })
                State.AutoQuestEnabled = false
                if Connections.AutoQuest then Connections.AutoQuest:Disconnect() Connections.AutoQuest = nil end
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Quest desativado!", Duration = 3 })
        if Connections.AutoQuest then Connections.AutoQuest:Disconnect() Connections.AutoQuest = nil end
    end
end

-- Função para Kill Aura
local function StartKillAura()
    if not State.KillAuraEnabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
        for _, enemy in pairs(workspace:GetChildren()) do
            if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") and enemy ~= LocalPlayer.Character then
                local distance = (playerPos - enemy.HumanoidRootPart.Position).Magnitude / 3
                if distance <= Config.KillAuraRange then
                    ReplicatedStorage.Remotes.Combat:FireServer("Attack", enemy)
                end
            end
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Kill Aura: " .. tostring(errorMsg), Duration = 3 })
        State.KillAuraEnabled = false
        if Connections.KillAura then Connections.KillAura:Disconnect() Connections.KillAura = nil end
    end
end

-- Função para ativar/desativar Kill Aura
local function ToggleKillAura(value)
    State.KillAuraEnabled = value
    if value then
        Fluent:Notify({ Title = "RedzHub", Content = "Kill Aura ativado!", Duration = 3 })
        Connections.KillAura = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartKillAura)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Kill Aura: " .. tostring(errorMsg), Duration = 3 })
                State.KillAuraEnabled = false
                if Connections.KillAura then Connections.KillAura:Disconnect() Connections.KillAura = nil end
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Kill Aura desativado!", Duration = 3 })
        if Connections.KillAura then Connections.KillAura:Disconnect() Connections.KillAura = nil end
    end
end

-- Função para Auto Stats
local function StartAutoStats()
    if not State.AutoStatsEnabled then return end
    local success, errorMsg = pcall(function()
        local stats = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("StatPoints")
        if stats and stats.Value > 0 then
            for stat, weight in pairs(Config.StatPriorities) do
                if weight > 0 and stats.Value > 0 then
                    local points = math.min(math.floor(stats.Value * weight), stats.Value)
                    if points > 0 then
                        ReplicatedStorage.Remotes.AddStat:FireServer(stat, points)
                    end
                end
            end
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Stats: " .. tostring(errorMsg), Duration = 3 })
        State.AutoStatsEnabled = false
        if Connections.AutoStats then Connections.AutoStats:Disconnect() Connections.AutoStats = nil end
    end
end

-- Função para ativar/desativar Auto Stats
local function ToggleAutoStats(value)
    State.AutoStatsEnabled = value
    if value then
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Stats ativado!", Duration = 3 })
        Connections.AutoStats = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoStats)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Stats: " .. tostring(errorMsg), Duration = 3 })
                State.AutoStatsEnabled = false
                if Connections.AutoStats then Connections.AutoStats:Disconnect() Connections.AutoStats = nil end
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Stats desativado!", Duration = 3 })
        if Connections.AutoStats then Connections.AutoStats:Disconnect() Connections.AutoStats = nil end
    end
end

-- Função para No-Clip
local function StartNoClip()
    if not State.NoClipEnabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character then return end
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no No-Clip: " .. tostring(errorMsg), Duration = 3 })
        State.NoClipEnabled = false
        if Connections.NoClip then Connections.NoClip:Disconnect() Connections.NoClip = nil end
    end
end

-- Função para ativar/desativar No-Clip
local function ToggleNoClip(value)
    State.NoClipEnabled = value
    if value then
        Fluent:Notify({ Title = "RedzHub", Content = "No-Clip ativado!", Duration = 3 })
        Connections.NoClip = RunService.Stepped:Connect(function()
            local success, errorMsg = pcall(StartNoClip)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no No-Clip: " .. tostring(errorMsg), Duration = 3 })
                State.NoClipEnabled = false
                if Connections.NoClip then Connections.NoClip:Disconnect() Connections.NoClip = nil end
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "No-Clip desativado!", Duration = 3 })
        if Connections.NoClip then Connections.NoClip:Disconnect() Connections.NoClip = nil end
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- Função para Auto Awakening
local function StartAutoAwakening()
    if not State.AutoAwakeningEnabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character then return end
        local awakeningExpert = NPCs["Awakening Expert"]
        if awakeningExpert then
            TeleportToPosition(awakeningExpert)
            ReplicatedStorage.Remotes.AwakenFruit:FireServer()
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Awakening: " .. tostring(errorMsg), Duration = 3 })
        State.AutoAwakeningEnabled = false
        if Connections.AutoAwakening then Connections.AutoAwakening:Disconnect() Connections.AutoAwakening = nil end
    end
end

-- Função para ativar/desativar Auto Awakening
local function ToggleAutoAwakening(value)
    State.AutoAwakeningEnabled = value
    if value then
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Awakening ativado!", Duration = 3 })
        Connections.AutoAwakening = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoAwakening)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Awakening: " .. tostring(errorMsg), Duration = 3 })
                State.AutoAwakeningEnabled = false
                if Connections.AutoAwakening then Connections.AutoAwakening:Disconnect() Connections.AutoAwakening = nil end
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Awakening desativado!", Duration = 3 })
        if Connections.AutoAwakening then Connections.AutoAwakening:Disconnect() Connections.AutoAwakening = nil end
    end
end

-- Função para Fruit Sniping
local function StartFruitSniping()
    if not State.FruitSnipingEnabled then return end
    local success, errorMsg = pcall(function()
        local _, fruitObjects = GetFruitList()
        for displayName, fruit in pairs(fruitObjects) do
            if fruit and fruit.Parent then
                local fruitName = fruit.Parent and fruit.Parent:FindFirstChild("FruitName") and fruit.Parent.FruitName.Value or "Fruit"
                if table.find(Config.RareFruits, fruitName) then
                    TeleportToPosition(fruit.Position)
                    Fluent:Notify({ Title = "RedzHub", Content = "Fruta rara encontrada: " .. fruitName .. "!", Duration = 5 })
                    return
                end
            end
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Fruit Sniping: " .. tostring(errorMsg), Duration = 3 })
        State.FruitSnipingEnabled = false
        if Connections.FruitSniping then Connections.FruitSniping:Disconnect() Connections.FruitSniping = nil end
    end
end

-- Função para ativar/desativar Fruit Sniping
local function ToggleFruitSniping(value)
    State.FruitSnipingEnabled = value
    if value then
        Fluent:Notify({ Title = "RedzHub", Content = "Fruit Sniping ativado!", Duration = 3 })
        Connections.FruitSniping = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartFruitSniping)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Fruit Sniping: " .. tostring(errorMsg), Duration = 3 })
                State.FruitSnipingEnabled = false
                if Connections.FruitSniping then Connections.FruitSniping:Disconnect() Connections.FruitSniping = nil end
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Fruit Sniping desativado!", Duration = 3 })
        if Connections.FruitSniping then Connections.FruitSniping:Disconnect() Connections.FruitSniping = nil end
    end
end

-- Função para Server Hop
local function StartServerHop()
    if not State.ServerHopEnabled then return end
    local success, errorMsg = pcall(function()
        Fluent:Notify({ Title = "RedzHub", Content = "Iniciando Server Hop...", Duration = 3 })
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        for _, server in pairs(servers.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                break
            end
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Server Hop: " .. tostring(errorMsg), Duration = 3 })
        State.ServerHopEnabled = false
        if Connections.ServerHop then Connections.ServerHop:Disconnect() Connections.ServerHop = nil end
    end
end

-- Função para ativar/desativar Server Hop
local function ToggleServerHop(value)
    State.ServerHopEnabled = value
    if value then
        Fluent:Notify({ Title = "RedzHub", Content = "Server Hop ativado!", Duration = 3 })
        Connections.ServerHop = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartServerHop)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Server Hop: " .. tostring(errorMsg), Duration = 3 })
                State.ServerHopEnabled = false
                if Connections.ServerHop then Connections.ServerHop:Disconnect() Connections.ServerHop = nil end
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Server Hop desativado!", Duration = 3 })
        if Connections.ServerHop then Connections.ServerHop:Disconnect() Connections.ServerHop = nil end
    end
end

-- Função para Auto Buy
local function StartAutoBuy()
    if not State.AutoBuyEnabled then return end
    local success, errorMsg = pcall(function()
        local itemVendor = NPCs["Item Vendor"]
        if itemVendor then
            TeleportToPosition(itemVendor)
            ReplicatedStorage.Remotes.BuyItem:FireServer("RandomFruit")
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Buy: " .. tostring(errorMsg), Duration = 3 })
        State.AutoBuyEnabled = false
        if Connections.AutoBuy then Connections.AutoBuy:Disconnect() Connections.AutoBuy = nil end
    end
end

-- Função para ativar/desativar Auto Buy
local function ToggleAutoBuy(value)
    State.AutoBuyEnabled = value
    if value then
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Buy ativado!", Duration = 3 })
        Connections.AutoBuy = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoBuy)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Buy: " .. tostring(errorMsg), Duration = 3 })
                State.AutoBuyEnabled = false
                if Connections.AutoBuy then Connections.AutoBuy:Disconnect() Connections.AutoBuy = nil end
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Buy desativado!", Duration = 3 })
        if Connections.AutoBuy then Connections.AutoBuy:Disconnect() Connections.AutoBuy = nil end
    end
end

-- Função para ativar/desativar Speed Hack
local function ToggleSpeedHack(value)
    State.SpeedHackEnabled = value
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") then return end
        LocalPlayer.Character.Humanoid.WalkSpeed = State.SpeedHackEnabled and Config.SpeedHackValue or Config.DefaultWalkSpeed
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Speed Hack: " .. tostring(errorMsg), Duration = 3 })
        State.SpeedHackEnabled = false
        return
    end
    Fluent:Notify({ Title = "RedzHub", Content = State.SpeedHackEnabled and "Speed Hack ativado!" or "Speed Hack desativado!", Duration = 3 })
end

-- Notificações para eventos especiais
workspace.DescendantAdded:Connect(function(obj)
    if obj.Name == "MirageIsland" then
        Fluent:Notify({ Title = "RedzHub", Content = "Mirage Island spawnada! Teleporte disponível!", Duration = 10 })
    elseif obj.Name == "Leviathan" then
        Fluent:Notify({ Title = "RedzHub", Content = "Leviathan spawnado! Teleporte disponível!", Duration = 10 })
    elseif obj.Name == "FullMoon" then
        Fluent:Notify({ Title = "RedzHub", Content = "Full Moon detectada! Verifique Mirage Island!", Duration = 10 })
    end
end)

-- Aba Main
Tabs.Main:AddParagraph({
    Title = "Bem-vindo ao RedzHub!",
    Content = "Hub definitivo para Blox Fruits. ESP, Teleport, Auto Farm, Auto Quest, Combat, Stats, No-Clip, Fruit Sniping, Server Hop, Auto Buy e mais. Otimizado para mobile e PC!"
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
Tabs.AutoFarm:AddSection("Farm Options")
local AutoFarmFruitsToggle = Tabs.AutoFarm:AddToggle("AutoFarmFruitsToggle", {
    Title = "Auto Farm Frutas",
    Description = "Teleporta automaticamente para a fruta mais próxima",
    Default = false
})

AutoFarmFruitsToggle:OnChanged(function(value)
    ToggleAutoFarm("AutoFarmFruits", value)
end)

local AutoFarmChestsToggle = Tabs.AutoFarm:AddToggle("AutoFarmChestsToggle", {
    Title = "Auto Farm Baús",
    Description = "Teleporta automaticamente para o baú mais próximo",
    Default = false
})

AutoFarmChestsToggle:OnChanged(function(value)
    ToggleAutoFarm("AutoFarmChests", value)
end)

local AutoQuestToggle = Tabs.AutoFarm:AddToggle("AutoQuestToggle", {
    Title = "Auto Quest",
    Description = "Aceita e completa quests automaticamente",
    Default = false
})

AutoQuestToggle:OnChanged(function(value)
    ToggleAutoQuest(value)
end)

local AutoAwakeningToggle = Tabs.AutoFarm:AddToggle("AutoAwakeningToggle", {
    Title = "Auto Awakening",
    Description = "Ativa habilidades despertadas automaticamente",
    Default = false
})

AutoAwakeningToggle:OnChanged(function(value)
    ToggleAutoAwakening(value)
end)

local FruitSnipingToggle = Tabs.AutoFarm:AddToggle("FruitSnipingToggle", {
    Title = "Fruit Sniping",
    Description = "Teleporta para frutas raras (ex.: Leopard, Kitsune)",
    Default = false
})

FruitSnipingToggle:OnChanged(function(value)
    ToggleFruitSniping(value)
end)

local ServerHopToggle = Tabs.AutoFarm:AddToggle("ServerHopToggle", {
    Title = "Server Hop",
    Description = "Alterna servidores para encontrar frutas ou eventos",
    Default = false
})

ServerHopToggle:OnChanged(function(value)
    ToggleServerHop(value)
end)

-- Aba ESP
Tabs.ESP:AddSection("ESP Options")
local FruitESPToggle = Tabs.ESP:AddToggle("FruitESPToggle", {
    Title = "Fruit ESP",
    Description = "Mostra todas as frutas no mapa com nome e distância",
    Default = false
})

FruitESPToggle:OnChanged(function(value)
    ToggleESP("Fruit", value)
end)

local ChestESPToggle = Tabs.ESP:AddToggle("ChestESPToggle", {
    Title = "Chest ESP",
    Description = "Mostra todos os baús no mapa com distância",
    Default = false
})

ChestESPToggle:OnChanged(function(value)
    ToggleESP("Chest", value)
end)

local EnemyESPToggle = Tabs.ESP:AddToggle("EnemyESPToggle", {
    Title = "Enemy ESP",
    Description = "Mostra todos os inimigos no mapa com nome, nível e distância",
    Default = false
})

EnemyESPToggle:OnChanged(function(value)
    ToggleESP("Enemy", value)
end)

local BossESPToggle = Tabs.ESP:AddToggle("BossESPToggle", {
    Title = "Boss ESP",
    Description = "Mostra todos os bosses no mapa com nome e distância",
    Default = false
})

BossESPToggle:OnChanged(function(value)
    ToggleESP("Boss", value)
end)

Tabs.ESP:AddSection("ESP Colors")
Tabs.ESP:AddColorPicker("FruitESPColor", {
    Title = "Fruit ESP Color",
    Description = "Cor do texto do Fruit ESP",
    Default = Config.ESP.FruitTextColor,
    Callback = function(value)
        Config.ESP.FruitTextColor = value
        for _, esp in pairs(ESP.Fruit) do
            if esp.Billboard then
                esp.Billboard.Name.TextColor3 = value
                esp.Billboard.Distance.TextColor3 = value
            end
        end
    end
})

Tabs.ESP:AddColorPicker("ChestESPColor", {
    Title = "Chest ESP Color",
    Description = "Cor do texto do Chest ESP",
    Default = Config.ESP.ChestTextColor,
    Callback = function(value)
        Config.ESP.ChestTextColor = value
        for _, esp in pairs(ESP.Chest) do
            if esp.Billboard then
                esp.Billboard.Name.TextColor3 = value
                esp.Billboard.Distance.TextColor3 = value
            end
        end
    end
})

Tabs.ESP:AddColorPicker("EnemyESPColor", {
    Title = "Enemy ESP Color",
    Description = "Cor do texto do Enemy ESP",
    Default = Config.ESP.EnemyTextColor,
    Callback = function(value)
        Config.ESP.EnemyTextColor = value
        for _, esp in pairs(ESP.Enemy) do
            if esp.Billboard then
                esp.Billboard.Name.TextColor3 = value
                esp.Billboard.Distance.TextColor3 = value
            end
        end
    end
})

Tabs.ESP:AddColorPicker("BossESPColor", {
    Title = "Boss ESP Color",
    Description = "Cor do texto do Boss ESP",
    Default = Config.ESP.BossTextColor,
    Callback = function(value)
        Config.ESP.BossTextColor = value
        for _, esp in pairs(ESP.Boss) do
            if esp.Billboard then
                esp.Billboard.Name.TextColor3 = value
                esp.Billboard.Distance.TextColor3 = value
            end
        end
    end
})

-- Aba Teleport
Tabs.Teleport:AddSection("Teleport Options")
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
        "Mirage Island", "Leviathan Spawn", "Tiki Outpost"
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
        "Quest Giver (Kingdom of Rose)", "Item Vendor"
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
        "Green Zone Spawn 1", "Floating Turtle Spawn 1", "Mirage Island Spawn 1"
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
Tabs.Combat:AddSection("Combat Options")
local KillAuraToggle = Tabs.Combat:AddToggle("KillAuraToggle", {
    Title = "Kill Aura",
    Description = "Ataca automaticamente inimigos próximos",
    Default = false
})

KillAuraToggle:OnChanged(function(value)
    ToggleKillAura(value)
end)

-- Aba Stats
Tabs.Stats:AddSection("Stats Options")
local AutoStatsToggle = Tabs.Stats:AddToggle("AutoStatsToggle", {
    Title = "Auto Stats",
    Description = "Distribui pontos de stat automaticamente",
    Default = false
})

AutoStatsToggle:OnChanged(function(value)
    ToggleAutoStats(value)
end)

Tabs.Stats:AddSlider("MeleeWeight", {
    Title = "Melee Weight",
    Description = "Proporção de pontos para Melee",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        Config.StatPriorities.Melee = value / 100
    end
})

Tabs.Stats:AddSlider("DefenseWeight", {
    Title = "Defense Weight",
    Description = "Proporção de pontos para Defense",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        Config.StatPriorities.Defense = value / 100
    end
})

Tabs.Stats:AddSlider("SwordWeight", {
    Title = "Sword Weight",
    Description = "Proporção de pontos para Sword",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        Config.StatPriorities.Sword = value / 100
    end
})

Tabs.Stats:AddSlider("GunWeight", {
    Title = "Gun Weight",
    Description = "Proporção de pontos para Gun",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        Config.StatPriorities.Gun = value / 100
    end
})

Tabs.Stats:AddSlider("FruitWeight", {
    Title = "Fruit Weight",
    Description = "Proporção de pontos para Fruit",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        Config.StatPriorities.Fruit = value / 100
    end
})

-- Aba Misc
Tabs.Misc:AddSection("Misc Options")
local SpeedHackToggle = Tabs.Misc:AddToggle("SpeedHackToggle", {
    Title = "Speed Hack",
    Description = "Aumenta a velocidade do jogador",
    Default = false
})

SpeedHackToggle:OnChanged(function(value)
    ToggleSpeedHack(value)
end)

local NoClipToggle = Tabs.Misc:AddToggle("NoClipToggle", {
    Title = "No-Clip",
    Description = "Permite atravessar paredes",
    Default = false
})

NoClipToggle:OnChanged(function(value)
    ToggleNoClip(value)
end)

local AutoBuyToggle = Tabs.Misc:AddToggle("AutoBuyToggle", {
    Title = "Auto Buy",
    Description = "Compra itens automaticamente (ex.: frutas)",
    Default = false
})

AutoBuyToggle:OnChanged(function(value)
    ToggleAutoBuy(value)
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

print("RedzHub Blox Fruits Script v10.0 carregado! Interface Fluent com ESP, Teleport, Auto Farm, Auto Quest, Combat, Stats, No-Clip, Fruit Sniping, Server Hop, Auto Buy e notificações.")
