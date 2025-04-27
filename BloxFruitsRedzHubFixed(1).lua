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
if not success then
    success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/main.lua"))()
    end)
    if not success then
        error("Falha ao carregar a biblioteca Fluent. Verifique sua conexão ou a URL.")
    end
end
Fluent = result
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
    return humanoid and humanoid.Health > 0
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
    Options = {"All", "Level 1-100", "Level 100-300", "Level 300-700", "Bosses"},
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
    end
})

local ESPFruitsToggle = ESPSection:CreateToggle({
    Name = "Fruits",
    CurrentValue = true,
    Flag = "ESPFruits",
    Callback = function(value)
        States.ESP.Fruits = value
    end
})

-- Tab Teleport
local TeleportTab = Window:CreateTab("Teleport")
local TeleportSection = TeleportTab:CreateSection("Teleport Locations")
local TeleportDropdown = TeleportSection:CreateDropdown({
    Name = "Select Location",
    Options = {"PirateIsland", "MarineIsland", "FrozenIsland"},
    CurrentOption = "PirateIsland",
    Callback = function(option)
        teleportTo(option)
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
            if States.AutoFarm.BossMode then
                autoFarmBosses()
            end
        end

        if States.ESP.Enabled then
            updateESP()
        end

        checkAntiStuck()

        wait(math.random(0.1, 0.3) * CONFIG.AUTO_FARM_SPEED.Current)
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