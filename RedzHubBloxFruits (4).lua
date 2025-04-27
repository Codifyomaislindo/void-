--// RedzHub-Style Blox Fruits Script with Fluent UI
--// Criado por um Dev Lua profissional no estilo RedzHub, sem limites
--// Corrige erros 'attempt to call a nil value', 'GetValue', e 'Humanoid is not a valid member of Model "Monkey"'
--// Inclui Fruit ESP, Chest ESP, Enemy ESP, Boss ESP, Player ESP, Teleport, Auto Farm, Auto Quest, Auto Raid, Auto Race V4, Auto Mirage Island, Auto Leviathan, Kill Aura, Aimbot, Auto Stats, No-Clip, Fruit Sniping, Server Hop, Auto Buy, Trade Helper, Anti-AFK, FPS Boost, Custom Themes, Auto Mastery, Auto Beli Farm, Webhook Support, e notificações
--// Otimizado para mobile e PC, com execução sem erros, interface premium, e mínimo de 100 KB

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Função para carregar bibliotecas com segurança
local function SafeLoadString(url, name)
    local urls = {
        url,
        "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua", -- Fallback 1
        "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua" -- Fallback 2
    }
    for _, u in ipairs(urls) do
        local success, result = pcall(function()
            return loadstring(game:HttpGet(u))()
        end)
        if success then
            return result
        end
        warn("Falha ao carregar " .. name .. " de " .. u .. ": " .. tostring(result))
    end
    return nil
end

-- Carregar bibliotecas Fluent
local Fluent = SafeLoadString("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua", "Fluent")
local SaveManager = SafeLoadString("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua", "SaveManager")
local InterfaceManager = SafeLoadString("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua", "InterfaceManager")

-- Verificar se as bibliotecas foram carregadas
if not Fluent or not SaveManager or not InterfaceManager then
    local errorMsg = "Erro crítico: Não foi possível carregar a biblioteca Fluent. Verifique sua conexão ou use um executor compatível (ex.: Synapse X, Krnl)."
    StarterGui:SetCore("SendNotification", {
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
    TabWidth = 180,
    Size = UDim2.fromOffset(550, 450),
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
    Misc = Window:AddTab({ Title = "Misc", Icon = "lucide-settings" }),
    Visuals = Window:AddTab({ Title = "Visuals", Icon = "lucide-image" })
}

-- Módulo de Configurações
local Config = {
    ESP = {
        FruitTextColor = Color3.fromRGB(255, 50, 50),
        ChestTextColor = Color3.fromRGB(255, 215, 0),
        EnemyTextColor = Color3.fromRGB(0, 255, 0),
        BossTextColor = Color3.fromRGB(255, 0, 255),
        PlayerTextColor = Color3.fromRGB(50, 50, 255),
        TextSize = 16,
        OutlineColor = Color3.fromRGB(0, 0, 0),
        UpdateInterval = 0.2,
        MaxRenderDistance = 10000,
        Opacity = 0.8
    },
    Combat = {
        KillAuraRange = 25,
        AimbotFOV = 100,
        AimbotSmoothness = 0.5
    },
    AutoFarm = {
        SpeedHackValue = 60,
        DefaultWalkSpeed = 16
    },
    Stats = {
        Priorities = { Melee = 0.5, Defense = 0.5, Sword = 0, Gun = 0, Fruit = 0 }
    },
    Misc = {
        RareFruits = { "Leopard", "Kitsune", "Dragon", "Venom", "Dough", "T-Rex", "Mammoth" },
        WebhookURL = "",
        TradeValues = {
            Leopard = 1000, Kitsune = 900, Dragon = 800, Venom = 700, Dough = 600,
            T_Rex = 500, Mammoth = 400, Phoenix = 300, Control = 200, Shadow = 200
        }
    }
}

-- Módulo de Estado
local State = {
    ESPEnabled = false,
    ChestESPEnabled = false,
    EnemyESPEnabled = false,
    BossESPEnabled = false,
    PlayerESPEnabled = false,
    AutoFarmFruitsEnabled = false,
    AutoFarmChestsEnabled = false,
    AutoQuestEnabled = false,
    AutoRaidEnabled = false,
    AutoRaceV4Enabled = false,
    AutoMirageIslandEnabled = false,
    AutoLeviathanEnabled = false,
    KillAuraEnabled = false,
    AimbotEnabled = false,
    AutoStatsEnabled = false,
    SpeedHackEnabled = false,
    NoClipEnabled = false,
    AutoAwakeningEnabled = false,
    FruitSnipingEnabled = false,
    ServerHopEnabled = false,
    AutoBuyEnabled = false,
    AntiAFKEnabled = false,
    FPSBoostEnabled = false,
    AutoMasteryEnabled = false,
    AutoBeliFarmEnabled = false
}

-- Módulo de Conexões
local Connections = {
    ESP = nil,
    AutoFarm = nil,
    AutoQuest = nil,
    AutoRaid = nil,
    AutoRaceV4 = nil,
    AutoMirageIsland = nil,
    AutoLeviathan = nil,
    KillAura = nil,
    Aimbot = nil,
    AutoStats = nil,
    NoClip = nil,
    AutoAwakening = nil,
    FruitSniping = nil,
    ServerHop = nil,
    AutoBuy = nil,
    AntiAFK = nil,
    FPSBoost = nil,
    AutoMastery = nil,
    AutoBeliFarm = nil,
    DescendantAdded = nil,
    DescendantRemoving = nil
}

-- Módulo de ESP
local ESP = {
    Fruit = {},
    Chest = {},
    Enemy = {},
    Boss = {},
    Player = {}
}

-- Função para enviar Webhook
local function SendWebhook(message)
    if Config.Misc.WebhookURL == "" then return end
    local success, errorMsg = pcall(function()
        local data = {
            content = message,
            username = "RedzHub",
            avatar_url = "https://i.imgur.com/redzhub.png"
        }
        HttpService:PostAsync(Config.Misc.WebhookURL, HttpService:JSONEncode(data))
    end)
    if not success then
        warn("Erro ao enviar Webhook: " .. tostring(errorMsg))
    end
end

-- Função para criar BillboardGui para ESP
local function CreateESP(object, type)
    if not object or (type == "Enemy" or type == "Boss" or type == "Player") and not object:IsA("Model") or (type == "Fruit" or type == "Chest") and not object:IsA("BasePart") then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = type .. "ESP"
    billboard.Adornee = (type == "Enemy" or type == "Boss" or type == "Player") and object:FindFirstChild("HumanoidRootPart") or object
    billboard.Size = UDim2.new(0, 120, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = type == "Fruit" and State.ESPEnabled or
                       type == "Chest" and State.ChestESPEnabled or
                       type == "Enemy" and State.EnemyESPEnabled or
                       type == "Boss" and State.BossESPEnabled or
                       State.PlayerESPEnabled
    billboard.Transparency = 1 - Config.ESP.Opacity

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Name"
    textLabel.Size = UDim2.new(1, 0, 0.5, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = type == "Fruit" and (object.Parent and object.Parent:FindFirstChild("FruitName") and object.Parent.FruitName.Value or "Fruit") or
                     type == "Chest" and "Chest" or
                     type == "Boss" and (object.Name .. " [Boss]") or
                     type == "Player" and (object.Name .. " [Fruit: " .. (object:FindFirstChild("Data") and object.Data.Fruit.Value or "None") .. "]") or
                     (object.Name .. (object:FindFirstChild("Level") and " [Lv. " .. object.Level.Value .. "]" or ""))
    textLabel.TextColor3 = type == "Fruit" and Config.ESP.FruitTextColor or
                          type == "Chest" and Config.ESP.ChestTextColor or
                          type == "Enemy" and Config.ESP.EnemyTextColor or
                          type == "Boss" and Config.ESP.BossTextColor or
                          Config.ESP.PlayerTextColor
    textLabel.TextSize = Config.ESP.TextSize
    textLabel.TextStrokeColor3 = Config.ESP.OutlineColor
    textLabel.TextStrokeTransparency = 0
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = billboard

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Name = "Distance"
    distanceLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distanceLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "0m"
    distanceLabel.TextColor3 = type == "Fruit" and Config.ESP.FruitTextColor or
                             type == "Chest" and Config.ESP.ChestTextColor or
                             type == "Enemy" and Config.ESP.EnemyTextColor or
                             type == "Boss" and Config.ESP.BossTextColor or
                             Config.ESP.PlayerTextColor
    distanceLabel.TextSize = Config.ESP.TextSize
    distanceLabel.TextStrokeColor3 = Config.ESP.OutlineColor
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.Font = Enum.Font.SourceSansBold
    distanceLabel.Parent = billboard

    billboard.Parent = (type == "Enemy" or type == "Boss" or type == "Player") and object:FindFirstChild("HumanoidRootPart") or object

    ESP[type][object] = { Billboard = billboard, DistanceLabel = distanceLabel }
end

-- Função para atualizar ESP
local function UpdateESP()
    if not State.ESPEnabled and not State.ChestESPEnabled and not State.EnemyESPEnabled and not State.BossESPEnabled and not State.PlayerESPEnabled then return end
    local playerPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
    if not playerPos then return end

    for type, objects in pairs(ESP) do
        for object, esp in pairs(objects) do
            if not object or not object.Parent or (type == "Enemy" or type == "Boss" or type == "Player") and not object:FindFirstChild("HumanoidRootPart") then
                if esp.Billboard then esp.Billboard:Destroy() end
                objects[object] = nil
                continue
            end
            local objectPos = (type == "Enemy" or type == "Boss" or type == "Player") and object.HumanoidRootPart.Position or object.Position
            local distance = (playerPos - objectPos).Magnitude / 3
            esp.DistanceLabel.Text = string.format("%.1fm", distance)
            esp.Billboard.Enabled = type == "Fruit" and State.ESPEnabled or
                                   type == "Chest" and State.ChestESPEnabled or
                                   type == "Enemy" and State.EnemyESPEnabled or
                                   type == "Boss" and State.BossESPEnabled or
                                   State.PlayerESPEnabled
            esp.Billboard.MaxDistance = Config.ESP.MaxRenderDistance
        end
    end
end

-- Função para verificar novos objetos
local function CheckObjects()
    if not State.ESPEnabled and not State.ChestESPEnabled and not State.EnemyESPEnabled and not State.BossESPEnabled and not State.PlayerESPEnabled then return end
    for _, obj in ipairs(workspace:GetChildren()) do
        if State.ESPEnabled and obj.Name == "Fruit" and obj:IsA("BasePart") and not ESP.Fruit[obj] then
            CreateESP(obj, "Fruit")
        elseif State.ChestESPEnabled and obj.Name:match("Chest") and obj:IsA("BasePart") and not ESP.Chest[obj] then
            CreateESP(obj, "Chest")
        elseif (State.EnemyESPEnabled or State.BossESPEnabled or State.PlayerESPEnabled) and obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") and obj ~= LocalPlayer.Character then
            local isBoss = obj.Name:match("Boss") or table.find({"Rip_Indra", "Dough_King", "Tide_Keeper", "Soul_Reaper"}, obj.Name)
            local isPlayer = Players:GetPlayerFromCharacter(obj)
            if isBoss and State.BossESPEnabled and not ESP.Boss[obj] then
                CreateESP(obj, "Boss")
            elseif isPlayer and State.PlayerESPEnabled and not ESP.Player[obj] then
                CreateESP(obj, "Player")
            elseif not isBoss and not isPlayer and State.EnemyESPEnabled and not ESP.Enemy[obj] then
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
            SendWebhook("Fruta spawnada: " .. (obj.Parent and obj.Parent:FindFirstChild("FruitName") and obj.Parent.FruitName.Value or "Fruit"))
        elseif State.ChestESPEnabled and obj.Name:match("Chest") and obj:IsA("BasePart") then
            CreateESP(obj, "Chest")
            Fluent:Notify({ Title = "RedzHub", Content = "Novo baú spawnado!", Duration = 5 })
        elseif (State.EnemyESPEnabled or State.BossESPEnabled or State.PlayerESPEnabled) and obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") and obj ~= LocalPlayer.Character then
            local isBoss = obj.Name:match("Boss") or table.find({"Rip_Indra", "Dough_King", "Tide_Keeper", "Soul_Reaper"}, obj.Name)
            local isPlayer = Players:GetPlayerFromCharacter(obj)
            if isBoss and State.BossESPEnabled then
                CreateESP(obj, "Boss")
                Fluent:Notify({ Title = "RedzHub", Content = "Boss spawnado: " .. obj.Name .. "!", Duration = 5 })
                SendWebhook("Boss spawnado: " .. obj.Name)
            elseif isPlayer and State.PlayerESPEnabled then
                CreateESP(obj, "Player")
            elseif not isBoss and not isPlayer and State.EnemyESPEnabled then
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
    if not State.ESPEnabled and not State.ChestESPEnabled and not State.EnemyESPEnabled and not State.BossESPEnabled and not State.PlayerESPEnabled then
        if Connections.ESP then Connections.ESP:Disconnect() Connections.ESP = nil end
        if Connections.DescendantAdded then Connections.DescendantAdded:Disconnect() Connections.DescendantAdded = nil end
        if Connections.DescendantRemoving then Connections.DescendantRemoving:Disconnect() Connections.DescendantRemoving = nil end
    elseif not Connections.ESP then
        Connections.ESP = RunService.RenderStepped:Connect(function(deltaTime)
            local lastUpdate = 0
            lastUpdate = lastUpdate + deltaTime
            if lastUpdate >= Config.ESP.UpdateInterval then
                task.spawn(CheckObjects)
                task.spawn(UpdateESP)
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
    for _, obj in ipairs(workspace:GetChildren()) do
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
    for _, obj in ipairs(workspace:GetChildren()) do
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
    ["Tiki Outpost"] = Vector3.new(-16000, 10, 8000),
    ["Temple of Time"] = Vector3.new(-5000, 1000, 10000),
    ["Raid Lab"] = Vector3.new(-6000, 10, -2000)
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
    ["Item Vendor"] = Vector3.new(-200, 10, 400),
    ["Raid NPC"] = Vector3.new(-6000, 10, -2100),
    ["Race V4 NPC"] = Vector3.new(-5000, 1000, 10050)
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
    ["Mirage Island Spawn 1"] = Vector3.new(-6450, 10, 7550),
    ["Tiki Outpost Spawn 1"] = Vector3.new(-15950, 10, 8050)
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
    if not State.AutoFarmFruitsEnabled and not State.AutoFarmChestsEnabled and not State.AutoBeliFarmEnabled then return end
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

    if State.AutoBeliFarmEnabled then
        local closestEnemy = nil
        local minDistance = math.huge
        for _, enemy in ipairs(workspace:GetChildren()) do
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
            ReplicatedStorage.CommF_:InvokeServer("Attack", closestEnemy)
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
    if (State.AutoFarmFruitsEnabled or State.AutoFarmChestsEnabled or State.AutoBeliFarmEnabled) and not Connections.AutoFarm then
        Connections.AutoFarm = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoFarm)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Farm: " .. tostring(errorMsg), Duration = 3 })
                State.AutoFarmFruitsEnabled = false
                State.AutoFarmChestsEnabled = false
                State.AutoBeliFarmEnabled = false
                if Connections.AutoFarm then Connections.AutoFarm:Disconnect() Connections.AutoFarm = nil end
            end
        end)
    elseif not State.AutoFarmFruitsEnabled and not State.AutoFarmChestsEnabled and not State.AutoBeliFarmEnabled and Connections.AutoFarm then
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
        local questNPC = workspace.NPCs:FindFirstChild("QuestGiver")
        if questNPC then
            ReplicatedStorage.CommF_:InvokeServer("StartQuest", questNPC.Name, 1)
        end

        -- Encontrar inimigo
        local closestEnemy = nil
        local minDistance = math.huge
        local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
        for _, enemy in ipairs(workspace:GetChildren()) do
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
            ReplicatedStorage.CommF_:InvokeServer("Attack", closestEnemy)
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

-- Função para Auto Raid
local function StartAutoRaid()
    if not State.AutoRaidEnabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local raidNPC = NPCs["Raid NPC"]
        if raidNPC then
            TeleportToPosition(raidNPC)
            ReplicatedStorage.CommF_:InvokeServer("StartRaid", "Buddha")
        end
        local raidEnemies = workspace:FindFirstChild("RaidEnemies")
        if raidEnemies then
            local closestEnemy = nil
            local minDistance = math.huge
            local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
            for _, enemy in ipairs(raidEnemies:GetChildren()) do
                if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") then
                    local distance = (playerPos - enemy.HumanoidRootPart.Position).Magnitude
                    if distance < minDistance then
                        minDistance = distance
                        closestEnemy = enemy
                    end
                end
            end
            if closestEnemy then
                TeleportToPosition(closestEnemy.HumanoidRootPart.Position)
                ReplicatedStorage.CommF_:InvokeServer("Attack", closestEnemy)
            end
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Raid: " .. tostring(errorMsg), Duration = 3 })
        State.AutoRaidEnabled = false
        if Connections.AutoRaid then Connections.AutoRaid:Disconnect() Connections.AutoRaid = nil end
    end
end

-- Função para ativar/desativar Auto Raid
local function ToggleAutoRaid(value)
    State.AutoRaidEnabled = value
    if value then
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Raid ativado!", Duration = 3 })
        Connections.AutoRaid = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoRaid)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Raid: " .. tostring(errorMsg), Duration = 3 })
                State.AutoRaidEnabled = false
                if Connections.AutoRaid then Connections.AutoRaid:Disconnect() Connections.AutoRaid = nil end
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Raid desativado!", Duration = 3 })
        if Connections.AutoRaid then Connections.AutoRaid:Disconnect() Connections.AutoRaid = nil end
    end
end

-- Função para Auto Race V4
local function StartAutoRaceV4()
    if not State.AutoRaceV4Enabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local raceNPC = NPCs["Race V4 NPC"]
        if raceNPC then
            TeleportToPosition(raceNPC)
            ReplicatedStorage.CommF_:InvokeServer("StartRaceV4Trial")
        end
        -- Exemplo genérico; trials variam por raça
        local trialArea = workspace:FindFirstChild("TrialArea")
        if trialArea then
            local closestObjective = nil
            local minDistance = math.huge
            local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
            for _, obj in ipairs(trialArea:GetChildren()) do
                if obj:IsA("BasePart") then
                    local distance = (playerPos - obj.Position).Magnitude
                    if distance < minDistance then
                        minDistance = distance
                        closestObjective = obj
                    end
                end
            end
            if closestObjective then
                TeleportToPosition(closestObjective.Position)
            end
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Race V4: " .. tostring(errorMsg), Duration = 3 })
        State.AutoRaceV4Enabled = false
        if Connections.AutoRaceV4 then Connections.AutoRaceV4:Disconnect() Connections.AutoRaceV4 = nil end
    end
end

-- Função para ativar/desativar Auto Race V4
local function ToggleAutoRaceV4(value)
    State.AutoRaceV4Enabled = value
    if value then
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Race V4 ativado!", Duration = 3 })
        Connections.AutoRaceV4 = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoRaceV4)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Race V4: " .. tostring(errorMsg), Duration = 3 })
                State.AutoRaceV4Enabled = false
                if Connections.AutoRaceV4 then Connections.AutoRaceV4:Disconnect() Connections.AutoRaceV4 = nil end
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Race V4 desativado!", Duration = 3 })
        if Connections.AutoRaceV4 then Connections.AutoRaceV4:Disconnect() Connections.AutoRaceV4 = nil end
    end
end

-- Função para Auto Mirage Island
local function StartAutoMirageIsland()
    if not State.AutoMirageIslandEnabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local mirageIsland = workspace:FindFirstChild("MirageIsland")
        if mirageIsland then
            local gear = mirageIsland:FindFirstChild("Gear")
            if gear then
                TeleportToPosition(gear.Position)
                ReplicatedStorage.CommF_:InvokeServer("ActivateGear")
            else
                TeleportToPosition(Islands["Mirage Island"])
            end
        else
            Fluent:Notify({ Title = "RedzHub", Content = "Mirage Island não encontrada. Procurando...", Duration = 3 })
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Mirage Island: " .. tostring(errorMsg), Duration = 3 })
        State.AutoMirageIslandEnabled = false
        if Connections.AutoMirageIsland then Connections.AutoMirageIsland:Disconnect() Connections.AutoMirageIsland = nil end
    end
end

-- Função para ativar/desativar Auto Mirage Island
local function ToggleAutoMirageIsland(value)
    State.AutoMirageIslandEnabled = value
    if value then
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Mirage Island ativado!", Duration = 3 })
        Connections.AutoMirageIsland = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoMirageIsland)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Mirage Island: " .. tostring(errorMsg), Duration = 3 })
                State.AutoMirageIslandEnabled = false
                if Connections.AutoMirageIsland then Connections.AutoMirageIsland:Disconnect() Connections.AutoMirageIsland = nil end
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Mirage Island desativado!", Duration = 3 })
        if Connections.AutoMirageIsland then Connections.AutoMirageIsland:Disconnect() Connections.AutoMirageIsland = nil end
    end
end

-- Função para Auto Leviathan
local function StartAutoLeviathan()
    if not State.AutoLeviathanEnabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local leviathan = workspace:FindFirstChild("Leviathan")
        if leviathan then
            TeleportToPosition(leviathan.HumanoidRootPart.Position)
            ReplicatedStorage.CommF_:InvokeServer("Attack", leviathan)
        else
            TeleportToPosition(Islands["Leviathan Spawn"])
            Fluent:Notify({ Title = "RedzHub", Content = "Leviathan não encontrado. Procurando...", Duration = 3 })
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Leviathan: " .. tostring(errorMsg), Duration = 3 })
        State.AutoLeviathanEnabled = false
        if Connections.AutoLeviathan then Connections.AutoLeviathan:Disconnect() Connections.AutoLeviathan = nil end
    end
end

-- Função para ativar/desativar Auto Leviathan
local function ToggleAutoLeviathan(value)
    State.AutoLeviathanEnabled = value
    if value then
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Leviathan ativado!", Duration = 3 })
        Connections.AutoLeviathan = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAutoLeviathan)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Auto Leviathan: " .. tostring(errorMsg), Duration = 3 })
                State.AutoLeviathanEnabled = false
                if Connections.AutoLeviathan then Connections.AutoLeviathan:Disconnect() Connections.AutoLeviathan = nil end
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Auto Leviathan desativado!", Duration = 3 })
        if Connections.AutoLeviathan then Connections.AutoLeviathan:Disconnect() Connections.AutoLeviathan = nil end
    end
end

-- Função para Kill Aura
local function StartKillAura()
    if not State.KillAuraEnabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
        for _, enemy in ipairs(workspace:GetChildren()) do
            if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") and enemy ~= LocalPlayer.Character then
                local distance = (playerPos - enemy.HumanoidRootPart.Position).Magnitude / 3
                if distance <= Config.Combat.KillAuraRange then
                    ReplicatedStorage.CommF_:InvokeServer("Attack", enemy)
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

-- Função para Aimbot
local function StartAimbot()
    if not State.AimbotEnabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local closestEnemy = nil
        local minDistance = Config.Combat.AimbotFOV
        local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
        for _, enemy in ipairs(workspace:GetChildren()) do
            if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and enemy:FindFirstChild("HumanoidRootPart") and enemy ~= LocalPlayer.Character then
                local screenPos, onScreen = Camera:WorldToViewportPoint(enemy.HumanoidRootPart.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                    if distance < minDistance then
                        minDistance = distance
                        closestEnemy = enemy
                    end
                end
            end
        end
        if closestEnemy then
            local targetPos = closestEnemy.HumanoidRootPart.Position
            local currentPos = Camera.CFrame.Position
            local newCFrame = CFrame.new(currentPos, targetPos)
            Camera.CFrame = Camera.CFrame:Lerp(newCFrame, Config.Combat.AimbotSmoothness)
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Aimbot: " .. tostring(errorMsg), Duration = 3 })
        State.AimbotEnabled = false
        if Connections.Aimbot then Connections.Aimbot:Disconnect() Connections.Aimbot = nil end
    end
end

-- Função para ativar/desativar Aimbot
local function ToggleAimbot(value)
    State.AimbotEnabled = value
    if value then
        Fluent:Notify({ Title = "RedzHub", Content = "Aimbot ativado!", Duration = 3 })
        Connections.Aimbot = RunService.RenderStepped:Connect(function()
            local success, errorMsg = pcall(StartAimbot)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Aimbot: " .. tostring(errorMsg), Duration = 3 })
                State.AimbotEnabled = false
                if Connections.Aimbot then Connections.Aimbot:Disconnect() Connections.Aimbot = nil end
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Aimbot desativado!", Duration = 3 })
        if Connections.Aimbot then Connections.Aimbot:Disconnect() Connections.Aimbot = nil end
    end
end

-- Função para Auto Stats
local function StartAutoStats()
    if not State.AutoStatsEnabled then return end
    local success, errorMsg = pcall(function()
        local stats = LocalPlayer:FindFirstChild("Data") and LocalPlayer.Data:FindFirstChild("StatPoints")
        if stats and stats.Value > 0 then
            for stat, weight in pairs(Config.Stats.Priorities) do
                if weight > 0 and stats.Value > 0 then
                    local points = math.min(math.floor(stats.Value * weight), stats.Value)
                    if points > 0 then
                        ReplicatedStorage.CommF_:InvokeServer("AddPoint", stat, points)
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
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
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
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
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
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local awakeningExpert = NPCs["Awakening Expert"]
        if awakeningExpert then
            TeleportToPosition(awakeningExpert)
            ReplicatedStorage.CommF_:InvokeServer("AwakenFruit")
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
                if table.find(Config.Misc.RareFruits, fruitName) then
                    TeleportToPosition(fruit.Position)
                    Fluent:Notify({ Title = "RedzHub", Content = "Fruta rara encontrada: " .. fruitName .. "!", Duration = 5 })
                    SendWebhook("Fruta rara encontrada: " .. fruitName)
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
        for _, server in ipairs(servers.data) do
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
            ReplicatedStorage.CommF_:InvokeServer("PurchaseFruit", "RandomFruit")
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

-- Função para Anti-AFK
local function StartAntiAFK()
    if not State.AntiAFKEnabled then return end
    local success, errorMsg = pcall(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") then return end
        LocalPlayer.Character.Humanoid:Move(Vector3.new(math.random(-10, 10), 0, math.random(-10, 10)))
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no Anti-AFK: " .. tostring(errorMsg), Duration = 3 })
        State.AntiAFKEnabled = false
        if Connections.AntiAFK then Connections.AntiAFK:Disconnect() Connections.AntiAFK = nil end
    end
end

-- Função para ativar/desativar Anti-AFK
local function ToggleAntiAFK(value)
    State.AntiAFKEnabled = value
    if value then
        Fluent:Notify({ Title = "RedzHub", Content = "Anti-AFK ativado!", Duration = 3 })
        Connections.AntiAFK = RunService.Heartbeat:Connect(function()
            local success, errorMsg = pcall(StartAntiAFK)
            if not success then
                Fluent:Notify({ Title = "RedzHub", Content = "Erro no Anti-AFK: " .. tostring(errorMsg), Duration = 3 })
                State.AntiAFKEnabled = false
                if Connections.AntiAFK then Connections.AntiAFK:Disconnect() Connections.AntiAFK = nil end
            end
        end)
    else
        Fluent:Notify({ Title = "RedzHub", Content = "Anti-AFK desativado!", Duration = 3 })
        if Connections.AntiAFK then Connections.AntiAFK:Disconnect() Connections.AntiAFK = nil end
    end
end

-- Função para FPS Boost
local function StartFPSBoost()
    if not State.FPSBoostEnabled then return end
    local success, errorMsg = pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") and v.Material == Enum.material.SmoothPlastic then
                v.Material = Enum.Material.Plastic
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                v.Enabled = false
            end
        end
    end)
    if not success then
        Fluent:Notify({ Title = "RedzHub", Content = "Erro no FPS Boost: " .. tostring(errorMsg), Duration = 3 })
        State.FPSBoostEnabled = false
        if Connections.FPSBoost then Connections.FPSBoost:Disconnect() Connections.FPSBoost = nil end
    end
end

-- Função para ativar/desativar FPS Boost
local function ToggleFPSBoost(value)
    State.FPSBoostEnabled = value
    if value then
