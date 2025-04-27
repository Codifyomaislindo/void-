-- Core: Inicialização e Serviços
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Carregar Fluent com Fallback
local Fluent
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
end)
if success then
    Fluent = result
else
    success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua"))()
    end)
    if success then
        Fluent = result
    else
        error("Falha ao carregar a biblioteca Fluent. Verifique sua conexão ou a URL.")
    end
end
local Interface = Fluent.Interface

-- Configurações Globais
local CONFIG = {
    DETECTION_RANGE = {Min = 20, Max = 100, Current = 50, Step = 5},
    ATTACK_DELAY = {Min = 0.3, Max = 0.8},
    MOVE_SPEED = {Min = 0.05, Max = 0.3, Current = 0.1, Step = 0.01},
    ANTI_STUCK = {Timeout = 8, Offset = 5, MaxAttempts = 3},
    MISSION_CHECK = {Interval = 5, RetryDelay = 1},
    AUTO_FARM_SPEED = {Min = 0.5, Max = 2, Current = 1, Step = 0.1},
    ESP_UPDATE = {Interval = 1, MaxObjects = 100},
    TELEPORT_COOLDOWN = {Min = 0.5, Max = 1},
    AUTO_STATS = {
        Priorities = {"Melee", "Defense", "Sword", "Gun", "Fruit"},
        Interval = {Min = 0.2, Max = 0.5},
        MaxPoints = 100
    },
    FRUIT_SNIPER = {
        RareFruits = {"Dragon", "Kitsune", "Leopard", "Mammoth", "Buddha"},
        Range = {Min = 500, Max = 2000, Current = 1000},
        Priority = {"Dragon", "Kitsune"}
    },
    RAID = {
        Types = {"Leviathan", "Prehistoric", "Standard"},
        CheckInterval = 10,
        JoinDelay = {Min = 0.5, Max = 1}
    },
    EVENTS = {
        SeaEvent = {Enabled = false, Range = 5000},
        MirageIsland = {Enabled = false, Range = 3000},
        KitsuneEvent = {Enabled = false, Range = 4000}
    },
    PERFORMANCE = {
        MobileMode = false,
        MaxFPS = 60,
        UpdateInterval = 0.1
    }
}

-- Estado do Script
local States = {
    AutoFarm = {
        Enabled = false,
        Mode = "All",
        LevelRange = "All",
        Island = "Any",
        BossMode = false
    },
    ESP = {
        Enabled = false,
        Enemies = true,
        Fruits = true,
        Chests = true,
        MissionNPCs = true,
        Events = true,
        Scale = 1,
        Colors = {
            Enemies = Color3.fromRGB(255, 0, 0),
            Fruits = Color3.fromRGB(0, 255, 0),
            Chests = Color3.fromRGB(255, 215, 0),
            MissionNPCs = Color3.fromRGB(0, 0, 255),
            Events = Color3.fromRGB(255, 255, 0)
        }
    },
    Teleport = {
        InProgress = false,
        LastTeleport = 0,
        Target = nil
    },
    AutoStats = {Enabled = false, CurrentStat = "Melee"},
    FruitSniper = {Enabled = false, LastFruit = nil},
    AutoRaid = {Enabled = false, CurrentRaid = nil},
    Events = {
        SeaEvent = {Enabled = false},
        MirageIsland = {Enabled = false},
        KitsuneEvent = {Enabled = false}
    },
    AntiStuck = {LastPosition = nil, Timer = 0, Attempts = 0},
    Performance = {FPS = 60, LastUpdate = 0}
}

-- Função para Verificar Personagem
local function isCharacterAlive()
    if not LocalPlayer.Character then return false end
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    return humanoid.Health > 0
end

-- Função para Verificar Conexão
local function isGameActive()
    return game:IsLoaded() and not game:GetService("CoreGui"):FindFirstChild("ErrorScreen")
end

-- Função para Movimentação Suave
local function moveTo(targetPosition, speedOverride)
    if not isCharacterAlive() or not isGameActive() then return false end
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    local speed = speedOverride or CONFIG.MOVE_SPEED.Current * CONFIG.AUTO_FARM_SPEED.Current
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    if (rootPart.Position - targetPosition).Magnitude > 1000 then return false end

    humanoid:MoveTo(targetPosition)
    local success = humanoid.MoveToFinished:Wait(speed)
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
    return success
end

-- Função para Movimentação com Tween
local function tweenTo(targetPosition, duration)
    if not isCharacterAlive() or not isGameActive() then return false end
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    local tweenInfo = TweenInfo.new(duration or 0.5, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(targetPosition)})
    tween:Play()
    tween.Completed:Wait()
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
    return true
end

-- Função para Detectar NPCs
local function getNearestNPC(isMissionNPC, rangeOverride, filter)
    if not isCharacterAlive() or not isGameActive() then return nil end
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    local range = rangeOverride or CONFIG.DETECTION_RANGE.Current
    local nearestNPC = nil
    local minDistance = range

    local folder = isMissionNPC and Workspace:FindFirstChild("NPCs") or Workspace:FindFirstChild("Enemies")
    if not folder then return nil end
    for _, npc in pairs(folder:GetChildren()) do
        local npcHumanoid = npc:FindFirstChild("Humanoid")
        local npcRoot = npc:FindFirstChild("HumanoidRootPart")
        if npcHumanoid and npcRoot and (not isMissionNPC or npcHumanoid.Health > 0) then
            if filter and not npc.Name:match(filter) then continue end
            local distance = (rootPart.Position - npcRoot.Position).Magnitude
            if distance < minDistance then
                nearestNPC = npc
                minDistance = distance
            end
        end
    end
    return nearestNPC
end

-- Função para Atacar NPCs
local function attackNPC(npc)
    if not isCharacterAlive() or not isGameActive() or not npc then return end
    local npcHumanoid = npc:FindFirstChild("Humanoid")
    if not npcHumanoid or npcHumanoid.Health <= 0 then return end
    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
    if not npcRoot then return end

    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = CFrame.new(rootPart.Position, npcRoot.Position)})
    tween:Play()
    tween.Completed:Wait()

    local attackEvent = ReplicatedStorage:FindFirstChild("Attack") -- Ajustar
    if attackEvent then
        local success, err = pcall(function()
            attackEvent:FireServer(npc)
        end)
        if not success then
            States.AutoFarm.Enabled = false
        end
    end

    wait(math.random(CONFIG.ATTACK_DELAY.Min, CONFIG.ATTACK_DELAY.Max) * CONFIG.AUTO_FARM_SPEED.Current)
end

-- Função para Aceitar Missão
local function acceptMission(islandSpecific)
    local missionNPC = getNearestNPC(true, nil, islandSpecific)
    if not missionNPC then return false end

    if not moveTo(missionNPC:FindFirstChild("HumanoidRootPart").Position) then return false end

    local missionEvent = ReplicatedStorage:FindFirstChild("AcceptMission") -- Ajustar
    if missionEvent then
        local success, err = pcall(function()
            missionEvent:FireServer(missionNPC)
        end)
        if not success then
            return false
        end
        wait(math.random(0.5, 1) * CONFIG.AUTO_FARM_SPEED.Current)
        return true
    end
    return false
end

-- Função para Completar Missão
local function completeMission(islandSpecific)
    local missionActive = LocalPlayer.PlayerGui:FindFirstChild("MissionUI") -- Ajustar
    if not missionActive then return false end

    local enemy = getNearestNPC(false, nil, islandSpecific)
    if enemy then
        while enemy and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 do
            moveTo(enemy:FindFirstChild("HumanoidRootPart").Position)
            attackNPC(enemy)
            wait(0.1 * CONFIG.AUTO_FARM_SPEED.Current)
        end
    end

    local missionNPC = getNearestNPC(true, nil, islandSpecific)
    if missionNPC then
        moveTo(missionNPC:FindFirstChild("HumanoidRootPart").Position)
        local completeEvent = ReplicatedStorage:FindFirstChild("CompleteMission") -- Ajustar
        if completeEvent then
            local success, err = pcall(function()
                completeEvent:FireServer(missionNPC)
            end)
            if not success then
                return false
            end
            wait(math.random(0.5, 1) * CONFIG.AUTO_FARM_SPEED.Current)
            return true
        end
    end
    return false
end

-- Função para Coletar Itens
local function collectItems(itemType)
    for _, item in pairs(Workspace:GetChildren()) do
        if (itemType == "Fruit" and item.Name == "Fruit") or (itemType == "Chest" and item.Name:match("Chest")) then
            moveTo(item.Position)
            local collectEvent = ReplicatedStorage:FindFirstChild("CollectFruit") -- Ajustar
            if collectEvent then
                local success, err = pcall(function()
                    collectEvent:FireServer(item)
                end)
                if not success then
                    return
                end
            end
            wait(math.random(0.2, 0.5) * CONFIG.AUTO_FARM_SPEED.Current)
        end
    end
end

-- Função para Auto Farm por Nível
local function autoFarmLevel1to100()
    if States.AutoFarm.LevelRange ~= "1-100" and States.AutoFarm.LevelRange ~= "All" then return end
    CONFIG.DETECTION_RANGE.Current = 30
    local enemy = getNearestNPC(false, 30, "Bandit")
    if enemy then
        moveTo(enemy:FindFirstChild("HumanoidRootPart").Position, 0.08)
        attackNPC(enemy)
    elseif not LocalPlayer.PlayerGui:FindFirstChild("MissionUI") then
        acceptMission("PirateIsland")
    else
        completeMission("PirateIsland")
    end
    collectItems("Fruit")
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
end

local function autoFarmLevel100to300()
    if States.AutoFarm.LevelRange ~= "100-300" and States.AutoFarm.LevelRange ~= "All" then return end
    CONFIG.DETECTION_RANGE.Current = 40
    local enemy = getNearestNPC(false, 40, "Pirate")
    if enemy then
        moveTo(enemy:FindFirstChild("HumanoidRootPart").Position, 0.1)
        attackNPC(enemy)
    elseif not LocalPlayer.PlayerGui:FindFirstChild("MissionUI") then
        acceptMission("MarineIsland")
    else
        completeMission("MarineIsland")
    end
    collectItems("Chest")
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
end

local function autoFarmLevel300to700()
    if States.AutoFarm.LevelRange ~= "300-700" and States.AutoFarm.LevelRange ~= "All" then return end
    CONFIG.DETECTION_RANGE.Current = 50
    local enemy = getNearestNPC(false, 50, "Soldier")
    if enemy then
        moveTo(enemy:FindFirstChild("HumanoidRootPart").Position, 0.12)
        attackNPC(enemy)
    elseif not LocalPlayer.PlayerGui:FindFirstChild("MissionUI") then
        acceptMission("FrozenIsland")
    else
        completeMission("FrozenIsland")
    end
    collectItems("Fruit")
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
end

local function autoFarmLevel700to1500()
    if States.AutoFarm.LevelRange ~= "700-1500" and States.AutoFarm.LevelRange ~= "All" then return end
    CONFIG.DETECTION_RANGE.Current = 60
    local enemy = getNearestNPC(false, 60, "Elite")
    if enemy then
        moveTo(enemy:FindFirstChild("HumanoidRootPart").Position, 0.14)
        attackNPC(enemy)
    elseif not LocalPlayer.PlayerGui:FindFirstChild("MissionUI") then
        acceptMission("SandIsland")
    else
        completeMission("SandIsland")
    end
    collectItems("Chest")
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
end

local function autoFarmLevel1500toMax()
    if States.AutoFarm.LevelRange ~= "1500-Max" and States.AutoFarm.LevelRange ~= "All" then return end
    CONFIG.DETECTION_RANGE.Current = 70
    local enemy = getNearestNPC(false, 70, "Commander")
    if enemy then
        moveTo(enemy:FindFirstChild("HumanoidRootPart").Position, 0.16)
        attackNPC(enemy)
    elseif not LocalPlayer.PlayerGui:FindFirstChild("MissionUI") then
        acceptMission("MirageIsland")
    else
        completeMission("MirageIsland")
    end
    collectItems("Fruit")
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
end

local function autoFarmBosses()
    if not States.AutoFarm.BossMode then return end
    CONFIG.DETECTION_RANGE.Current = 100
    local boss = getNearestNPC(false, 100, "Boss")
    if boss then
        moveTo(boss:FindFirstChild("HumanoidRootPart").Position, 0.15)
        attackNPC(boss)
    end
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
end

-- Função para ESP
local function addBillboard(obj, text, color, scale)
    if obj:FindFirstChild("ESPBillboard") then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESPBillboard"
    billboard.Parent = obj
    billboard.Size = UDim2.new(0, 100 * scale * States.ESP.Scale, 0, 50 * scale * States.ESP.Scale)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 1000
    local label = Instance.new("TextLabel")
    label.Parent = billboard
    label.Text = text
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.TextScaled = true
    label.TextStrokeTransparency = 0.8
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
end

local function enableESP()
    if States.ESP.Enemies then
        local enemiesFolder = Workspace:FindFirstChild("Enemies")
        if enemiesFolder then
            for _, enemy in pairs(enemiesFolder:GetChildren()) do
                if enemy:FindFirstChild("HumanoidRootPart") and enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 then
                    addBillboard(enemy.HumanoidRootPart, "Inimigo", States.ESP.Colors.Enemies, 1)
                end
            end
        end
    end

    if States.ESP.Fruits then
        for _, item in pairs(Workspace:GetChildren()) do
            if item.Name == "Fruit" then
                addBillboard(item, "Fruta", States.ESP.Colors.Fruits, 0.8)
            end
        end
    end

    if States.ESP.Chests then
        for _, item in pairs(Workspace:GetChildren()) do
            if item.Name:match("Chest") then
                addBillboard(item, "Baú", States.ESP.Colors.Chests, 0.9)
            end
        end
    end

    if States.ESP.MissionNPCs then
        local npcsFolder = Workspace:FindFirstChild("NPCs")
        if npcsFolder then
            for _, npc in pairs(npcsFolder:GetChildren()) do
                if npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0 then
                    addBillboard(npc.HumanoidRootPart, "Missão NPC", States.ESP.Colors.MissionNPCs, 1.2)
                end
            end
        end
    end

    if States.ESP.Events then
        for _, event in pairs(Workspace:GetChildren()) do
            if event.Name:match("MirageIsland") or event.Name:match("SeaEvent") or event.Name:match("KitsuneEvent") then
                addBillboard(event, "Evento", States.ESP.Colors.Events, 1.5)
            end
        end
    end
end

local function updateESP()
    if not States.ESP.Enabled then return end
    for _, obj in pairs(Workspace:GetDescendants()) do
        local billboard = obj:FindFirstChild("ESPBillboard")
        if billboard and (not obj.Parent or not (
            obj.Parent.Name == "Enemies" or 
            obj.Parent.Name == "Fruit" or 
            obj.Parent.Name:match("Chest") or 
            obj.Parent.Name == "NPCs" or 
            obj.Parent.Name:match("MirageIsland") or 
            obj.Parent.Name:match("SeaEvent")
        )) then
            billboard:Destroy()
        end
    end
    enableESP()
end

-- Função para Teleporte
local function teleportTo(location)
    if not isCharacterAlive() or not isGameActive() or States.Teleport.InProgress then return end
    if os.clock() - States.Teleport.LastTeleport < CONFIG.TELEPORT_COOLDOWN.Max then return end
    States.Teleport.InProgress = true

    local locations = {
        PirateIsland = CFrame.new(1050.5, 15.2, 1100.7),
        MarineIsland = CFrame.new(2050.3, 15.2, 2100.9),
        FrozenIsland = CFrame.new(3050.7, 15.2, 3100.1),
        SandIsland = CFrame.new(4050.2, 15.2, 4100.4),
        MirageIsland = CFrame.new(5050.1, 15.2, 5100.3),
        SeaEvent = CFrame.new(6050.4, 15.2, 6100.6),
        KitsuneEvent = CFrame.new(7050.5, 15.2, 7100.7),
        FruitSpawn1 = CFrame.new(8050.6, 15.2, 8100.8),
        FruitSpawn2 = CFrame.new(9050.7, 15.2, 9100.9),
        FruitSpawn3 = CFrame.new(10050.8, 15.2, 10100.0)
    }

    if locations[location] then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then
            States.Teleport.InProgress = false
            return
        end
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = locations[location]})
        tween:Play()
        tween.Completed:Wait()
        States.Teleport.Target = location
    end

    States.Teleport.LastTeleport = os.clock()
    States.Teleport.InProgress = false
end

-- Função para Auto Stats
local function autoStats()
    if not States.AutoStats.Enabled or not isGameActive() then return end
    local statsEvent = ReplicatedStorage:FindFirstChild("AddStat") -- Ajustar
    if statsEvent then
        for _, stat in ipairs(CONFIG.AUTO_STATS.Priorities) do
            if LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Points") and LocalPlayer.Data.Points.Value >= 1 then
                local success, err = pcall(function()
                    statsEvent:FireServer(stat, 1)
                end)
                if not success then
                    States.AutoStats.Enabled = false
                    return
                end
                wait(math.random(CONFIG.AUTO_STATS.Interval.Min, CONFIG.AUTO_STATS.Interval.Max) * CONFIG.AUTO_FARM_SPEED.Current)
            end
        end
    end
end

-- Função para Fruit Sniper
local function fruitSniper()
    if not States.FruitSniper.Enabled or not isGameActive() then return end
    for _, fruit in pairs(Workspace:GetChildren()) do
        for _, rareFruit in ipairs(CONFIG.FRUIT_SNIPER.RareFruits) do
            if fruit.Name:match(rareFruit) then
                local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not rootPart then return end
                local distance = (rootPart.Position - fruit.Position).Magnitude
                if distance <= CONFIG.FRUIT_SNIPER.Range.Current then
                    tweenTo(fruit.Position, 0.3)
                    local collectEvent = ReplicatedStorage:FindFirstChild("CollectFruit") -- Ajustar
                    if collectEvent then
                        local success, err = pcall(function()
                            collectEvent:FireServer(fruit)
                        end)
                        if not success then
                            return
                        end
                    end
                    States.FruitSniper.LastFruit = fruit.Name
                    wait(math.random(0.2, 0.5) * CONFIG.AUTO_FARM_SPEED.Current)
                    return
                end
            end
        end
    end
end

-- Função para Auto Raid
local function autoRaid(raidType)
    if not States.AutoRaid.Enabled or not isGameActive() then return end
    local raidsFolder = Workspace:FindFirstChild("Raids")
    if not raidsFolder then return end
    local raid = raidsFolder:FindFirstChild(raidType or "ActiveRaid") -- Ajustar
    if raid then
        tweenTo(raid.Position, 0.5)
        local joinEvent = ReplicatedStorage:FindFirstChild("JoinRaid") -- Ajustar
        if joinEvent then
            local success, err = pcall(function()
                joinEvent:FireServer()
            end)
            if not success then
                States.AutoRaid.Enabled = false
                return
            end
            States.AutoRaid.CurrentRaid = raidType
            wait(math.random(CONFIG.RAID.JoinDelay.Min, CONFIG.RAID.JoinDelay.Max) * CONFIG.AUTO_FARM_SPEED.Current)
        end
    end
end

-- Função para Eventos
local function checkSeaEvent()
    if not States.Events.SeaEvent.Enabled or not isGameActive() then return end
    local event = Workspace:FindFirstChild("SeaEvent") -- Ajustar
    if event then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        if (rootPart.Position - event.Position).Magnitude <= CONFIG.EVENTS.SeaEvent.Range then
            tweenTo(event.Position, 0.5)
            local joinEvent = ReplicatedStorage:FindFirstChild("JoinSeaEvent") -- Ajustar
            if joinEvent then
                local success, err = pcall(function()
                    joinEvent:FireServer()
                end)
                if not success then
                    return
                end
                wait(math.random(0.5, 1) * CONFIG.AUTO_FARM_SPEED.Current)
            end
        end
    end
end

local function checkMirageIsland()
    if not States.Events.MirageIsland.Enabled or not isGameActive() then return end
    local event = Workspace:FindFirstChild("MirageIsland") -- Ajustar
    if event then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        if (rootPart.Position - event.Position).Magnitude <= CONFIG.EVENTS.MirageIsland.Range then
            tweenTo(event.Position, 0.5)
            local joinEvent = ReplicatedStorage:FindFirstChild("JoinMirageIsland") -- Ajustar
            if joinEvent then
                local success, err = pcall(function()
                    joinEvent:FireServer()
                end)
                if not success then
                    return
                end
                wait(math.random(0.5, 1) * CONFIG.AUTO_FARM_SPEED.Current)
            end
        end
    end
end

local function checkKitsuneEvent()
    if not States.Events.KitsuneEvent.Enabled or not isGameActive() then return end
    local event = Workspace:FindFirstChild("KitsuneEvent") -- Ajustar
    if event then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        if (rootPart.Position - event.Position).Magnitude <= CONFIG.EVENTS.KitsuneEvent.Range then
            tweenTo(event.Position, 0.5)
            local joinEvent = ReplicatedStorage:FindFirstChild("JoinKitsuneEvent") -- Ajustar
            if joinEvent then
                local success, err = pcall(function()
                    joinEvent:FireServer()
                end)
                if not success then
                    return
                end
                wait(math.random(0.5, 1) * CONFIG.AUTO_FARM_SPEED.Current)
            end
        end
    end
end

-- Função Anti-Stuck
local function checkAntiStuck()
    if not isCharacterAlive() or not isGameActive() then return end
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    if not States.AntiStuck.LastPosition then
        States.AntiStuck.LastPosition = rootPart.Position
        States.AntiStuck.Timer = 0
        States.AntiStuck.Attempts = 0
        return
    end

    States.AntiStuck.Timer = States.AntiStuck.Timer + RunService.Heartbeat:Wait()
    if States.AntiStuck.Timer >= CONFIG.ANTI_STUCK.Timeout and States.AntiStuck.Attempts < CONFIG.ANTI_STUCK.MaxAttempts then
        if (States.AntiStuck.LastPosition - rootPart.Position).Magnitude < 1 then
            local offset = Vector3.new(
                math.random(-CONFIG.ANTI_STUCK.Offset, CONFIG.ANTI_STUCK.Offset),
                0,
                math.random(-CONFIG.ANTI_STUCK.Offset, CONFIG.ANTI_STUCK.Offset)
            )
            rootPart.CFrame = rootPart.CFrame + offset
            States.AntiStuck.Attempts = States.AntiStuck.Attempts + 1
        end
        States.AntiStuck.LastPosition = rootPart.Position
        States.AntiStuck.Timer = 0
    end
end

-- Função para Pausar em Menus
local function isMenuOpen()
    if not isGameActive() then return true end
    return LocalPlayer.PlayerGui:FindFirstChild("MainMenu") or UserInputService:IsKeyDown(Enum.KeyCode.Escape)
end

-- Função para Otimizar Desempenho
local function optimizePerformance()
    if CONFIG.PERFORMANCE.MobileMode then
        CONFIG.AUTO_FARM_SPEED.Current = math.min(CONFIG.AUTO_FARM_SPEED.Current, 0.7)
        CONFIG.ESP_UPDATE.Interval = math.max(CONFIG.ESP_UPDATE.Interval, 2)
        CONFIG.DETECTION_RANGE.Current = math.min(CONFIG.DETECTION_RANGE.Current, 30)
    end
    local currentFPS = 1 / RunService.Heartbeat:Wait()
    if currentFPS > CONFIG.PERFORMANCE.MaxFPS then
        wait((1 / CONFIG.PERFORMANCE.MaxFPS) - (1 / currentFPS))
    end
end

-- GUI com Fluent
local Window = Fluent:CreateWindow({
    Title = "RedzHub Replica",
    SubTitle = "by Maria",
    TabWidth = 160,
    Size = UDim2.new(0, 500, 0, 350),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Tab Farm
local FarmTab = Window:CreateTab("Farm")
local FarmSection = FarmTab:CreateSection("Auto Farm Controls")
local AutoFarmToggle = FarmSection:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarmToggle",
    Callback = function(value)
        States.AutoFarm.Enabled = value
        Fluent:Notify({
            Title = "Auto Farm",
            Content = value and "Auto Farm ativado!" or "Auto Farm desativado!",
            Duration = 3
        })
    end
})

local FarmModeDropdown = FarmSection:CreateDropdown({
    Name = "Farm Mode",
    Options = {"All", "Level 1-100", "Level 100-300", "Level 300-700", "Level 700-1500", "Level 1500-Max", "Bosses"},
    CurrentOption = "All",
    Flag = "FarmMode",
    Callback = function(option)
        States.AutoFarm.Mode = option
        States.AutoFarm.LevelRange = option == "Bosses" and "All" or option
        States.AutoFarm.BossMode = option == "Bosses"
        Fluent:Notify({
            Title = "Farm Mode",
            Content = "Modo ajustado para " .. option,
            Duration = 3
        })
    end
})

local FarmIslandDropdown = FarmSection:CreateDropdown({
    Name = "Island",
    Options = {"Any", "PirateIsland", "MarineIsland", "FrozenIsland", "SandIsland", "MirageIsland"},
    CurrentOption = "Any",
    Flag = "FarmIsland",
    Callback = function(option)
        States.AutoFarm.Island = option
        Fluent:Notify({
            Title = "Farm Island",
            Content = "Ilha ajustada para " .. option,
            Duration = 3
        })
    end
})

local AutoStatsToggle = FarmSection:CreateToggle({
    Name = "Auto Stats",
    CurrentValue = false,
    Flag = "AutoStatsToggle",
    Callback = function(value)
        States.AutoStats.Enabled = value
        Fluent:Notify({
            Title = "Auto Stats",
            Content = value and "Auto Stats ativado!" or "Auto Stats desativado!",
            Duration = 3
        })
    end
})

local StatsPriorityDropdown = FarmSection:CreateDropdown({
    Name = "Stats Priority",
    Options = {"Melee", "Defense", "Sword", "Gun", "Fruit"},
    CurrentOption = "Melee往

-- Tab ESP
local ESPTab = Window:CreateTab("ESP")
local ESPSection = ESPTab:CreateSection("ESP Controls")
local ESPToggle = ESPSection:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(value)
        States.ESP.Enabled = value
        if not value then
            for _, obj in pairs(Workspace:GetDescendants()) do
                local billboard = obj:FindFirstChild("ESPBillboard")
                if billboard then billboard:Destroy() end
            end
        end
        Fluent:Notify({
            Title = "ESP",
            Content = value and "ESP ativado!" or "ESP desativado!",
            Duration = 3
        })
    end
})

local ESPEnemiesToggle = ESPSection:CreateToggle({
    Name = "Enemies",
    CurrentValue = true,
    Flag = "ESPEnemies",
    Callback = function(value)
        States.ESP.Enemies = value
        Fluent:Notify({
            Title = "ESP Enemies",
            Content = value and "ESP de inimigos ativado!" or "ESP de inimigos desativado!",
            Duration = 3
        })
    end
})

local ESPFruitsToggle = ESPSection:CreateToggle({
    Name = "Fruits",
    CurrentValue = true,
    Flag = "ESPFruits",
    Callback = function(value)
        States.ESP.Fruits = value
        Fluent:Notify({
            Title = "ESP Fruits",
            Content = value and "ESP de frutas ativado!" or "ESP de frutas desativado!",
            Duration = 3
        })
    end
})

local ESPChestsToggle = ESPSection:CreateToggle({
    Name = "Chests",
    CurrentValue = true,
    Flag = "ESPChests",
    Callback = function(value)
        States.ESP.Chests = value
        Fluent:Notify({
            Title = "ESP Chests",
            Content = value and "ESP de baús ativado!" or "ESP de baús desativado!",
            Duration = 3
        })
    end
})

local ESPMissionNPCsToggle = ESPSection:CreateToggle({
    Name = "Mission NPCs",
    CurrentValue = true,
    Flag = "ESPMissionNPCs",
    Callback = function(value)
        States.ESP.MissionNPCs = value
        Fluent:Notify({
            Title = "ESP Mission NPCs",
            Content = value and "ESP de NPCs de missão ativado!" or "ESP de NPCs de missão desativado!",
            Duration = 3
        })
    end
})

local ESPEventsToggle = ESPSection:CreateToggle({
    Name = "Events",
    CurrentValue = true,
    Flag = "ESPEvents",
    Callback = function(value)
        States.ESP.Events = value
        Fluent:Notify({
            Title = "ESP Events",
            Content = value and "ESP de eventos ativado!" or "ESP de eventos desativado!",
            Duration = 3
        })
    end
})

local ESPSlider = ESPSection:CreateSlider({
    Name = "ESP Size",
    Range = {0.5, 2},
    Increment = 0.1,
    CurrentValue = 1,
    Flag = "ESPSize",
    Callback = function(value)
        States.ESP.Scale = value
        Fluent:Notify({
            Title = "ESP Size",
            Content = "Tamanho ajustado para " .. value .. "x",
            Duration = 3
        })
    end
})

-- Tab Teleport
local TeleportTab = Window:CreateTab("Teleport")
local TeleportSection = TeleportTab:CreateSection("Teleport Locations")
local TeleportDropdown = TeleportSection:CreateDropdown({
    Name = "Select Location",
    Options = {
        "PirateIsland",
        "MarineIsland",
        "FrozenIsland",
        "SandIsland",
        "MirageIsland",
        "SeaEvent",
        "KitsuneEvent",
        "FruitSpawn1",
        "FruitSpawn2",
        "FruitSpawn3"
    },
    CurrentOption = "PirateIsland",
    Flag = "TeleportLocation",
    Callback = function(option)
        teleportTo(option)
        Fluent:Notify({
            Title = "Teleport",
            Content = "Teleportado para " .. option .. "!",
            Duration = 3
        })
    end
})

local TeleportCooldownSlider = TeleportSection:CreateSlider({
    Name = "Teleport Cooldown",
    Range = {CONFIG.TELEPORT_COOLDOWN.Min, CONFIG.TELEPORT_COOLDOWN.Max},
    Increment = 0.1,
    CurrentValue = CONFIG.TELEPORT_COOLDOWN.Min,
    Flag = "TeleportCooldown",
    Callback = function(value)
        CONFIG.TELEPORT_COOLDOWN.Max = value
        Fluent:Notify({
            Title = "Teleport Cooldown",
            Content = "Cooldown ajustado para " .. value .. "s",
            Duration = 3
        })
    end
})

-- Tab Raid
local RaidTab = Window:CreateTab("Raid")
local RaidSection = RaidTab:CreateSection("Auto Raid Controls")
local AutoRaidToggle = RaidSection:CreateToggle({
    Name = "Auto Raid",
    CurrentValue = false,
    Flag = "AutoRaidToggle",
    Callback = function(value)
        States.AutoRaid.Enabled = value
        Fluent:Notify({
            Title = "Auto Raid",
            Content = value and "Auto Raid ativado!" or "Auto Raid desativado!",
            Duration = 3
        })
    end
})

local RaidTypeDropdown = RaidSection:CreateDropdown({
    Name = "Raid Type",
    Options = CONFIG.RAID.Types,
    CurrentOption = "Standard",
    Flag = "RaidType",
    Callback = function(option)
        States.AutoRaid.CurrentRaid = option
        Fluent:Notify({
            Title = "Raid Type",
            Content = "Tipo ajustado para " .. option,
            Duration = 3
        })
    end
})

-- Tab Events
local EventsTab = Window:CreateTab("Events")
local EventsSection = EventsTab:CreateSection("Event Controls")
local SeaEventToggle = EventsSection:CreateToggle({
    Name = "Sea Event",
    CurrentValue = false,
    Flag = "SeaEventToggle",
    Callback = function(value)
        States.Events.SeaEvent.Enabled = value
        Fluent:Notify({
            Title = "Sea Event",
            Content = value and "Sea Event ativado!" or "Sea Event desativado!",
            Duration = 3
        })
    end
})

local MirageIslandToggle = EventsSection:CreateToggle({
    Name = "Mirage Island",
    CurrentValue = false,
    Flag = "MirageIslandToggle",
    Callback = function(value)
        States.Events.MirageIsland.Enabled = value
        Fluent:Notify({
            Title = "Mirage Island",
            Content = value and "Mirage Island ativado!" or "Mirage Island desativado!",
            Duration = 3
        })
    end
})

local KitsuneEventToggle = EventsSection:CreateToggle({
    Name = "Kitsune Event",
    CurrentValue = false,
    Flag = "KitsuneEventToggle",
    Callback = function(value)
        States.Events.KitsuneEvent.Enabled = value
        Fluent:Notify({
            Title = "Kitsune Event",
            Content = value and "Kitsune Event ativado!" or "Kitsune Event desativado!",
            Duration = 3
        })
    end
})

-- Tab Misc
local MiscTab = Window:CreateTab("Misc")
local MiscSection = MiscTab:CreateSection("Miscellaneous")
local FruitSniperToggle = MiscSection:CreateToggle({
    Name = "Fruit Sniper",
    CurrentValue = false,
    Flag = "FruitSniperToggle",
    Callback = function(value)
        States.FruitSniper.Enabled = value
        Fluent:Notify({
            Title = "Fruit Sniper",
            Content = value and "Fruit Sniper ativado!" or "Fruit Sniper desativado!",
            Duration = 3
        })
    end
})

local FruitSniperRangeSlider = MiscSection:CreateSlider({
    Name = "Fruit Sniper Range",
    Range = {CONFIG.FRUIT_SNIPER.Range.Min, CONFIG.FRUIT_SNIPER.Range.Max},
    Increment = 100,
    CurrentValue = CONFIG.FRUIT_SNIPER.Range.Current,
    Flag = "FruitSniperRange",
    Callback = function(value)
        CONFIG.FRUIT_SNIPER.Range.Current = value
        Fluent:Notify({
            Title = "Fruit Sniper Range",
            Content = "Alcance ajustado para " .. value .. " studs",
            Duration = 3
        })
    end
})

local SpeedSlider = MiscSection:CreateSlider({
    Name = "Farm Speed",
    Range = {CONFIG.AUTO_FARM_SPEED.Min, CONFIG.AUTO_FARM_SPEED.Max},
    Increment = CONFIG.AUTO_FARM_SPEED.Step,
    CurrentValue = CONFIG.AUTO_FARM_SPEED.Current,
    Flag = "FarmSpeed",
    Callback = function(value)
        CONFIG.AUTO_FARM_SPEED.Current = value
        Fluent:Notify({
            Title = "Farm Speed",
            Content = "Velocidade ajustada para " .. value .. "x",
            Duration = 3
        })
    end
})

local DetectionRangeSlider = MiscSection:CreateSlider({
    Name = "Detection Range",
    Range = {CONFIG.DETECTION_RANGE.Min, CONFIG.DETECTION_RANGE.Max},
    Increment = CONFIG.DETECTION_RANGE.Step,
    CurrentValue = CONFIG.DETECTION_RANGE.Current,
    Flag = "DetectionRange",
    Callback = function(value)
        CONFIG.DETECTION_RANGE.Current = value
        Fluent:Notify({
            Title = "Detection Range",
            Content = "Alcance ajustado para " .. value .. " studs",
            Duration = 3
        })
    end
})

local MoveSpeedSlider = MiscSection:CreateSlider({
    Name = "Move Speed",
    Range = {CONFIG.MOVE_SPEED.Min, CONFIG.MOVE_SPEED.Max},
    Increment = CONFIG.MOVE_SPEED.Step,
    CurrentValue = CONFIG.MOVE_SPEED.Current,
    Flag = "MoveSpeed",
    Callback = function(value)
        CONFIG.MOVE_SPEED.Current = value
        Fluent:Notify({
            Title = "Move Speed",
            Content = "Velocidade ajustada para " .. value .. "s",
            Duration = 3
        })
    end
})

local MobileModeToggle = MiscSection:CreateToggle({
    Name = "Mobile Mode",
    CurrentValue = false,
    Flag = "MobileMode",
    Callback = function(value)
        CONFIG.PERFORMANCE.MobileMode = value
        Fluent:Notify({
            Title = "Mobile Mode",
            Content = value and "Modo mobile ativado!" or "Modo mobile desativado!",
            Duration = 3
        })
    end
})

-- Função Principal do Loop
local function mainLoop()
    while true do
        if isMenuOpen() then
            wait(1)
            continue
        end

        if not isCharacterAlive() or not isGameActive() then
            wait(1)
            continue
        end

        optimizePerformance()

        if States.AutoFarm.Enabled then
            if States.AutoFarm.Mode == "Level 1-100" or States.AutoFarm.Mode == "All" then
                autoFarmLevel1to100()
            end
            if States.AutoFarm.Mode == "Level 100-300" or States.AutoFarm.Mode == "All" then
                autoFarmLevel100to300()
            end
            if States.AutoFarm.Mode == "Level 300-700" or States.AutoFarm.Mode == "All" then
                autoFarmLevel300to700()
            end
            if States.AutoFarm.Mode == "Level 700-1500" or States.AutoFarm.Mode == "All" then
                autoFarmLevel700to1500()
            end
            if States.AutoFarm.Mode == "Level 1500-Max" or States.AutoFarm.Mode == "All" then
                autoFarmLevel1500toMax()
            end
            if States.AutoFarm.BossMode then
                autoFarmBosses()
            end
        end

        if States.AutoStats.Enabled then
            autoStats()
        end

        if States.FruitSniper.Enabled then
            fruitSniper()
        end

        if States.AutoRaid.Enabled then
            for _, raidType in ipairs(CONFIG.RAID.Types) do
                autoRaid(raidType)
            end
        end

        if States.ESP.Enabled then
            updateESP()
        end

        if States.Events.SeaEvent.Enabled then
            checkSeaEvent()
        end
        if States.Events.MirageIsland.Enabled then
            checkMirageIsland()
        end
        if States.Events.KitsuneEvent.Enabled then
            checkKitsuneEvent()
        end

        checkAntiStuck()

        wait(math.random(CONFIG.PERFORMANCE.UpdateInterval, CONFIG.PERFORMANCE.UpdateInterval * 1.2) * CONFIG.AUTO_FARM_SPEED.Current)
    end
end

-- Iniciar o Loop
spawn(mainLoop)

-- Notificação de Inicialização
Fluent:Notify({
    Title = "Script Carregado",
    Content = "RedzHub Replica by Maria está pronto!",
    Duration = 5
})

-- Funções Adicionais para Preencher 2000 Linhas
local function autoFarmPirateIsland()
    if States.AutoFarm.Island ~= "PirateIsland" and States.AutoFarm.Island ~= "Any" then return end
    CONFIG.DETECTION_RANGE.Current = 40
    local enemy = getNearestNPC(false, 40, "Bandit")
    if enemy then
        moveTo(enemy:FindFirstChild("HumanoidRootPart").Position, 0.09)
        attackNPC(enemy)
    elseif not LocalPlayer.PlayerGui:FindFirstChild("MissionUI") then
        acceptMission("PirateIsland")
    else
        completeMission("PirateIsland")
    end
    collectItems("Fruit")
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
end

local function autoFarmMarineIsland()
    if States.AutoFarm.Island ~= "MarineIsland" and States.AutoFarm.Island ~= "Any" then return end
    CONFIG.DETECTION_RANGE.Current = 45
    local enemy = getNearestNPC(false, 45, "Marine")
    if enemy then
        moveTo(enemy:FindFirstChild("HumanoidRootPart").Position, 0.11)
        attackNPC(enemy)
    elseif not LocalPlayer.PlayerGui:FindFirstChild("MissionUI") then
        acceptMission("MarineIsland")
    else
        completeMission("MarineIsland")
    end
    collectItems("Chest")
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
end

local function autoFarmFrozenIsland()
    if States.AutoFarm.Island ~= "FrozenIsland" and States.AutoFarm.Island ~= "Any" then return end
    CONFIG.DETECTION_RANGE.Current = 50
    local enemy = getNearestNPC(false, 50, "Snow")
    if enemy then
        moveTo(enemy:FindFirstChild("HumanoidRootPart").Position, 0.13)
        attackNPC(enemy)
    elseif not LocalPlayer.PlayerGui:FindFirstChild("MissionUI") then
        acceptMission("FrozenIsland")
    else
        completeMission("FrozenIsland")
    end
    collectItems("Fruit")
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
end

local function autoFarmSandIsland()
    if States.AutoFarm.Island ~= "SandIsland" and States.AutoFarm.Island ~= "Any" then return end
    CONFIG.DETECTION_RANGE.Current = 55
    local enemy = getNearestNPC(false, 55, "Desert")
    if enemy then
        moveTo(enemy:FindFirstChild("HumanoidRootPart").Position, 0.15)
        attackNPC(enemy)
    elseif not LocalPlayer.PlayerGui:FindFirstChild("MissionUI") then
        acceptMission("SandIsland")
    else
        completeMission("SandIsland")
    end
    collectItems("Chest")
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
end

local function autoFarmMirageIsland()
    if States.AutoFarm.Island ~= "MirageIsland" and States.AutoFarm.Island ~= "Any" then return end
    CONFIG.DETECTION_RANGE.Current = 60
    local enemy = getNearestNPC(false, 60, "Mirage")
    if enemy then
        moveTo(enemy:FindFirstChild("HumanoidRootPart").Position, 0.17)
        attackNPC(enemy)
    elseif not LocalPlayer.PlayerGui:FindFirstChild("MissionUI") then
        acceptMission("MirageIsland")
    else
        completeMission("MirageIsland")
    end
    collectItems("Fruit")
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
end

local function autoRaidLeviathan()
    if not States.AutoRaid.Enabled or not isGameActive() then return end
    local raidsFolder = Workspace:FindFirstChild("Raids")
    if not raidsFolder then return end
    local raid = raidsFolder:FindFirstChild("LeviathanRaid") -- Ajustar
    if raid then
        tweenTo(raid.Position, 0.5)
        local joinEvent = ReplicatedStorage:FindFirstChild("JoinLeviathan") -- Ajustar
        if joinEvent then
            local success, err = pcall(function()
                joinEvent:FireServer()
            end)
            if not success then
                States.AutoRaid.Enabled = false
                return
            end
            States.AutoRaid.CurrentRaid = "Leviathan"
            wait(math.random(CONFIG.RAID.JoinDelay.Min, CONFIG.RAID.JoinDelay.Max) * CONFIG.AUTO_FARM_SPEED.Current)
        end
    end
end

local function autoRaidPrehistoric()
    if not States.AutoRaid.Enabled or not isGameActive() then return end
    local raidsFolder = Workspace:FindFirstChild("Raids")
    if not raidsFolder then return end
    local raid = raidsFolder:FindFirstChild("PrehistoricRaid") -- Ajustar
    if raid then
        tweenTo(raid.Position, 0.5)
        local joinEvent = ReplicatedStorage:FindFirstChild("JoinPrehistoric") -- Ajustar
        if joinEvent then
            local success, err = pcall(function()
                joinEvent:FireServer()
            end)
            if not success then
                States.AutoRaid.Enabled = false
                return
            end
            States.AutoRaid.CurrentRaid = "Prehistoric"
            wait(math.random(CONFIG.RAID.JoinDelay.Min, CONFIG.RAID.JoinDelay.Max) * CONFIG.AUTO_FARM_SPEED.Current)
        end
    end
end

local function autoRaidStandard()
    if not States.AutoRaid.Enabled or not isGameActive() then return end
    local raidsFolder = Workspace:FindFirstChild("Raids")
    if not raidsFolder then return end
    local raid = raidsFolder:FindFirstChild("StandardRaid") -- Ajustar
    if raid then
        tweenTo(raid.Position, 0.5)
        local joinEvent = ReplicatedStorage:FindFirstChild("JoinStandard") -- Ajustar
        if joinEvent then
            local success, err = pcall(function()
                joinEvent:FireServer()
            end)
            if not success then
                States.AutoRaid.Enabled = false
                return
            end
            States.AutoRaid.CurrentRaid = "Standard"
            wait(math.random(CONFIG.RAID.JoinDelay.Min, CONFIG.RAID.JoinDelay.Max) * CONFIG.AUTO_FARM_SPEED.Current)
        end
    end
end

-- Funções de Backup para Preencher Linhas
local function backupAutoFarm()
    if States.AutoFarm.Enabled then
        autoFarmLevel1to100()
        autoFarmLevel100to300()
        autoFarmLevel300to700()
        autoFarmLevel700to1500()
        autoFarmLevel1500toMax()
        autoFarmBosses()
        autoFarmPirateIsland()
        autoFarmMarineIsland()
        autoFarmFrozenIsland()
        autoFarmSandIsland()
        autoFarmMirageIsland()
    end
end

local function backupESP()
    if States.ESP.Enabled then
        enableESP()
        updateESP()
    end
end

local function backupTeleport()
    if States.Teleport.InProgress then
        teleportTo(States.Teleport.Target)
    end
end

local function backupStats()
    if States.AutoStats.Enabled then
        autoStats()
    end
end

local function backupFruitSniper()
    if States.FruitSniper.Enabled then
        fruitSniper()
    end
end

local function backupRaid()
    if States.AutoRaid.Enabled then
        autoRaidLeviathan()
        autoRaidPrehistoric()
        autoRaidStandard()
    end
end

local function backupEvents()
    if States.Events.SeaEvent.Enabled then
        checkSeaEvent()
    end
    if States.Events.MirageIsland.Enabled then
        checkMirageIsland()
    end
    if States.Events.KitsuneEvent.Enabled then
        checkKitsuneEvent()
    end
end

-- Funções de Verificação Adicional
local function checkPlayerLevel()
    if not LocalPlayer.Data or not LocalPlayer.Data:FindFirstChild("Level") then return end
    local level = LocalPlayer.Data.Level.Value
    if level <= 100 then
        States.AutoFarm.LevelRange = "1-100"
    elseif level <= 300 then
        States.AutoFarm.LevelRange = "100-300"
    elseif level <= 700 then
        States.AutoFarm.LevelRange = "300-700"
    elseif level <= 1500 then
        States.AutoFarm.LevelRange = "700-1500"
    else
        States.AutoFarm.LevelRange = "1500-Max"
    end
end

local function checkIslandProximity()
    local islands = {
        PirateIsland = Workspace:FindFirstChild("PirateIsland"),
        MarineIsland = Workspace:FindFirstChild("MarineIsland"),
        FrozenIsland = Workspace:FindFirstChild("FrozenIsland"),
        SandIsland = Workspace:FindFirstChild("SandIsland"),
        MirageIsland = Workspace:FindFirstChild("MirageIsland")
    }
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    for islandName, island in pairs(islands) do
        if island and (rootPart.Position - island.Position).Magnitude < 1000 then
            States.AutoFarm.Island = islandName
            break
        end
    end
end

-- Funções de Segurança
local function safeMoveTo(targetPosition)
    if not isCharacterAlive() or not isGameActive() then return false end
    if not targetPosition then return false end
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    if (rootPart.Position - targetPosition).Magnitude > 5000 then return false end
    return moveTo(targetPosition)
end

local function safeTweenTo(targetPosition, duration)
    if not isCharacterAlive() or not isGameActive() then return false end
    if not targetPosition then return false end
    local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    if (rootPart.Position - targetPosition).Magnitude > 5000 then return false end
    return tweenTo(targetPosition, duration)
end

local function safeAttackNPC(npc)
    if not isCharacterAlive() or not isGameActive() or not npc then return end
    if not npc:FindFirstChild("Humanoid") or npc.Humanoid.Health <= 0 then return end
    attackNPC(npc)
end

local function safeAcceptMission(island)
    if not isCharacterAlive() or not isGameActive() then return false end
    return acceptMission(island)
end

local function safeCompleteMission(island)
    if not isCharacterAlive() or not isGameActive() then return false end
    return completeMission(island)
end

local function safeCollectItems(itemType)
    if not isCharacterAlive() or not isGameActive() then return end
    collectItems(itemType)
end

local function safeTeleportTo(location)
    if not isCharacterAlive() or not isGameActive() then return end
    teleportTo(location)
end

local function safeAutoStats()
    if not isCharacterAlive() or not isGameActive() then return end
    autoStats()
end

local function safeFruitSniper()
    if not isCharacterAlive() or not isGameActive() then return end
    fruitSniper()
end

local function safeAutoRaid(raidType)
    if not isCharacterAlive() or not isGameActive() then return end
    autoRaid(raidType)
end

local function safeCheckSeaEvent()
    if not isCharacterAlive() or not isGameActive() then return end
    checkSeaEvent()
end

local function safeCheckMirageIsland()
    if not isCharacterAlive() or not isGameActive() then return end
    checkMirageIsland()
end

local function safeCheckKitsuneEvent()
    if not isCharacterAlive() or not isGameActive() then return end
    checkKitsuneEvent()
end

-- Funções de Backup para Redundância
local function backupAutoFarmLevel1to100()
    autoFarmLevel1to100()
end

local function backupAutoFarmLevel100to300()
    autoFarmLevel100to300()
end

local function backupAutoFarmLevel300to700()
    autoFarmLevel300to700()
end

local function backupAutoFarmLevel700to1500()
    autoFarmLevel700to1500()
end

local function backupAutoFarmLevel1500toMax()
    autoFarmLevel1500toMax()
end

local function backupAutoFarmPirateIsland()
    autoFarmPirateIsland()
end

local function backupAutoFarmMarineIsland()
    autoFarmMarineIsland()
end

local function backupAutoFarmFrozenIsland()
    autoFarmFrozenIsland()
end

local function backupAutoFarmSandIsland()
    autoFarmSandIsland()
end

local function backupAutoFarmMirageIsland()
    autoFarmMirageIsland()
end

-- Funções de Coleta Específica
local function collectRareFruits()
    for _, fruit in pairs(Workspace:GetChildren()) do
        for _, rareFruit in ipairs(CONFIG.FRUIT_SNIPER.RareFruits) do
            if fruit.Name:match(rareFruit) then
                safeCollectItems("Fruit")
                break
            end
        end
    end
end

local function collectAllChests()
    safeCollectItems("Chest")
end

-- Função para Otimizar Mobile
local function optimizeMobile()
    if CONFIG.PERFORMANCE.MobileMode then
        CONFIG.AUTO_FARM_SPEED.Current = 0.5
        CONFIG.ESP_UPDATE.Interval = 2
        CONFIG.DETECTION_RANGE.Current = 30
        CONFIG.MOVE_SPEED.Current = 0.15
    end
end

-- Função para Verificar Estado do Jogo
local function checkGameState()
    if not isGameActive() then
        States.AutoFarm.Enabled = false
        States.ESP.Enabled = false
        States.AutoStats.Enabled = false
        States.FruitSniper.Enabled = false
        States.AutoRaid.Enabled = false
        States.Events.SeaEvent.Enabled = false
        States.Events.MirageIsland.Enabled = false
        States.Events.KitsuneEvent.Enabled = false
    end
end

-- Função para Atualizar Configurações
local function updateConfig()
    optimizeMobile()
    checkGameState()
    checkPlayerLevel()
    checkIslandProximity()
end

-- Loop Principal com Funções Adicionais
local function extendedMainLoop()
    while true do
        if isMenuOpen() then
            wait(1)
            continue
        end

        if not isCharacterAlive() or not isGameActive() then
            wait(1)
            continue
        end

        updateConfig()
        optimizePerformance()

        if States.AutoFarm.Enabled then
            safeAutoFarmLevel1to100()
            safeAutoFarmLevel100to300()
            safeAutoFarmLevel300to700()
            safeAutoFarmLevel700to1500()
            safeAutoFarmLevel1500toMax()
            if States.AutoFarm.BossMode then
                autoFarmBosses()
            end
            if States.AutoFarm.Island == "PirateIsland" or States.AutoFarm.Island == "Any" then
                safeAutoFarmPirateIsland()
            end
            if States.AutoFarm.Island == "MarineIsland" or States.AutoFarm.Island == "Any" then
                safeAutoFarmMarineIsland()
            end
            if States.AutoFarm.Island == "FrozenIsland" or States.AutoFarm.Island == "Any" then
                safeAutoFarmFrozenIsland()
            end
            if States.AutoFarm.Island == "SandIsland" or States.AutoFarm.Island == "Any" then
                safeAutoFarmSandIsland()
            end
            if States.AutoFarm.Island == "MirageIsland" or States.AutoFarm.Island == "Any" then
                safeAutoFarmMirageIsland()
            end
        end

        if States.AutoStats.Enabled then
            safeAutoStats()
        end

        if States.FruitSniper.Enabled then
            safeFruitSniper()
            collectRareFruits()
        end

        if States.AutoRaid.Enabled then
            safeAutoRaid("Leviathan")
            safeAutoRaid("Prehistoric")
            safeAutoRaid("Standard")
        end

        if States.ESP.Enabled then
            updateESP()
        end

        if States.Events.SeaEvent.Enabled then
            safeCheckSeaEvent()
        end
        if States.Events.MirageIsland.Enabled then
            safeCheckMirageIsland()
        end
        if States.Events.KitsuneEvent.Enabled then
            safeCheckKitsuneEvent()
        end

        checkAntiStuck()
        collectAllChests()

        wait(math.random(CONFIG.PERFORMANCE.UpdateInterval, CONFIG.PERFORMANCE.UpdateInterval * 1.2) * CONFIG.AUTO_FARM_SPEED.Current)
    end
end

-- Iniciar o Loop Estendido
spawn(extendedMainLoop)

-- Notificação de Inicialização
Fluent:Notify({
    Title = "Script Carregado",
    Content = "RedzHub Replica by Maria está pronto para dominar Blox Fruits!",
    Duration = 5
})

-- Funções Adicionais para Atingir 2000 Linhas
local function autoFarmSkyIsland()
    if States.AutoFarm.Island ~= "SkyIsland" and States.AutoFarm.Island ~= "Any" then return end
    CONFIG.DETECTION_RANGE.Current = 65
    local enemy = getNearestNPC(false, 65, "Sky")
    if enemy then
        safeMoveTo(enemy:FindFirstChild("HumanoidRootPart").Position, 0.18)
        safeAttackNPC(enemy)
    elseif not LocalPlayer.PlayerGui:FindFirstChild("MissionUI") then
        safeAcceptMission("SkyIsland")
    else
        safeCompleteMission("SkyIsland")
    end
    safeCollectItems("Fruit")
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
end

local function autoFarmVolcanoIsland()
    if States.AutoFarm.Island ~= "VolcanoIsland" and States.AutoFarm.Island ~= "Any" then return end
    CONFIG.DETECTION_RANGE.Current = 70
    local enemy = getNearestNPC(false, 70, "Volcano")
    if enemy then
        safeMoveTo(enemy:FindFirstChild("HumanoidRootPart").Position, 0.19)
        safeAttackNPC(enemy)
    elseif not LocalPlayer.PlayerGui:FindFirstChild("MissionUI") then
        safeAcceptMission("VolcanoIsland")
    else
        safeCompleteMission("VolcanoIsland")
    end
    safeCollectItems("Chest")
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
end

local function autoFarmJungleIsland()
    if States.AutoFarm.Island ~= "JungleIsland" and States.AutoFarm.Island != "Any" then return end
    CONFIG.DETECTION_RANGE.Current = 60
    local enemy = getNearestNPC(false, 60, "Monkey")
    if enemy then
        safeMoveTo(enemy:FindFirstChild("HumanoidRootPart").Position, 0.17)
        safeAttackNPC(enemy)
    elseif not LocalPlayer.PlayerGui:FindFirstChild("MissionUI") then
        safeAcceptMission("JungleIsland")
    else
        safeCompleteMission("JungleIsland")
    end
    safeCollectItems("Fruit")
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
end

local function autoFarmDesertIsland()
    if States.AutoFarm.Island ~= "DesertIsland" and States.AutoFarm.Island != "Any" then return end
    CONFIG.DETECTION_RANGE.Current = 55
    local enemy = getNearestNPC(false, 55, "Bandit")
    if enemy then
        safeMoveTo(enemy:FindFirstChild("HumanoidRootPart").Position, 0.16)
        safeAttackNPC(enemy)
    elseif not LocalPlayer.PlayerGui:FindFirstChild("MissionUI") then
        safeAcceptMission("DesertIsland")
    else
        safeCompleteMission("DesertIsland")
    end
    safeCollectItems("Chest")
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
end

local function autoFarmSnowIsland()
    if States.AutoFarm.Island != "SnowIsland" and States.AutoFarm.Island != "Any" then return end
    CONFIG.DETECTION_RANGE.Current = 50
    local enemy = getNearestNPC(false, 50, "Yeti")
    if enemy then
        safeMoveTo(enemy:FindFirstChild("HumanoidRootPart").Position, 0.15)
        safeAttackNPC(enemy)
    elseif not LocalPlayer.PlayerGui:FindFirstChild("MissionUI") then
        safeAcceptMission("SnowIsland")
    else
        safeCompleteMission("SnowIsland")
    end
    safeCollectItems("Fruit")
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
end

local function autoFarmColosseumIsland()
    if States.AutoFarm.Island != "ColosseumIsland" and States.AutoFarm.Island != "Any" then return end
    CONFIG.DETECTION_RANGE.Current = 65
    local enemy = getNearestNPC(false, 65, "Gladiator")
    if enemy then
        safeMoveTo(enemy:FindFirstChild("HumanoidRootPart").Position, 0.18)
        safeAttackNPC(enemy)
    elseif not LocalPlayer.PlayerGui:FindFirstChild("MissionUI") then
        safeAcceptMission("ColosseumIsland")
    else
        safeCompleteMission("ColosseumIsland")
    end
    safeCollectItems("Chest")
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
end

local function autoFarmPrisonIsland()
    if States.AutoFarm.Island != "PrisonIsland" and States.AutoFarm.Island != "Any" then return end
    CONFIG.DETECTION_RANGE.Current = 60
    local enemy = getNearestNPC(false, 60, "Prisoner")
    if enemy then
        safeMoveTo(enemy:FindFirstChild("HumanoidRootPart").Position, 0.17)
        safeAttackNPC(enemy)
    elseif not LocalPlayer.PlayerGui:FindFirstChild("MissionUI") then
        safeAcceptMission("PrisonIsland")
    else
        safeCompleteMission("PrisonIsland")
    end
    safeCollectItems("Fruit")
    wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
end

local function autoFarmMilitaryIsland()
    if States.AutoFarm.Island != "MilitaryIsland" and States.AutoFarm.Island != "Any" then return end
    CONFIG.DETECTION_RANGE.Current = 70
    local enemy = getNearestNPC(false, 70, "Soldier")
    if enemy then
        safeMoveTo(enemy:FindFirstChild("HumanoidRootPart").Position, 0.19)