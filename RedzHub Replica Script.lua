-- Core: Inicialização e Serviços
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

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

-- Configurações Globais
local CONFIG = {
    DETECTION_RANGE = {Min = 20, Max = 100, Current = 50, Step = 5},
    ATTACK_DELAY = {Min = 0.3, Max = 0.8},
    MOVE_SPEED = {Min = 0.05, Max = 0.3, Current = 0.1, Step = 0.01},
    ANTI_STUCK = {Timeout = 8, Offset = 5, MaxAttempts = 3},
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
    AntiStuck = {LastPosition = nil, Timer = 0, Attempts = 0}
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

    local attackEvent = ReplicatedStorage:FindFirstChild("Attack")
    if attackEvent then
        pcall(function()
            attackEvent:FireServer(npc)
        end)
    end

    wait(math.random(CONFIG.ATTACK_DELAY.Min, CONFIG.ATTACK_DELAY.Max) * CONFIG.AUTO_FARM_SPEED.Current)
end

-- Função para Aceitar Missão
local function acceptMission(islandSpecific)
    local missionNPC = getNearestNPC(true, nil, islandSpecific)
    if not missionNPC then return false end

    if not moveTo(missionNPC:FindFirstChild("HumanoidRootPart").Position) then return false end

    local missionEvent = ReplicatedStorage:FindFirstChild("AcceptMission")
    if missionEvent then
        local success = pcall(function()
            missionEvent:FireServer(missionNPC)
        end)
        if not success then return false end
        wait(math.random(0.5, 1) * CONFIG.AUTO_FARM_SPEED.Current)
        return true
    end
    return false
end

-- Função para Completar Missão
local function completeMission(islandSpecific)
    local missionActive = LocalPlayer.PlayerGui:FindFirstChild("MissionUI")
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
        local completeEvent = ReplicatedStorage:FindFirstChild("CompleteMission")
        if completeEvent then
            local success = pcall(function()
                completeEvent:FireServer(missionNPC)
            end)
            if not success then return false end
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
            local collectEvent = ReplicatedStorage:FindFirstChild("CollectFruit")
            if collectEvent then
                pcall(function()
                    collectEvent:FireServer(item)
                end)
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
    local statsEvent = ReplicatedStorage:FindFirstChild("AddStat")
    if statsEvent then
        for _, stat in ipairs(CONFIG.AUTO_STATS.Priorities) do
            if LocalPlayer.Data and LocalPlayer.Data:FindFirstChild("Points") and LocalPlayer.Data.Points.Value >= 1 then
                pcall(function()
                    statsEvent:FireServer(stat, 1)
                end)
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
                    local collectEvent = ReplicatedStorage:FindFirstChild("CollectFruit")
                    if collectEvent then
                        pcall(function()
                            collectEvent:FireServer(fruit)
                        end)
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
    local raid = raidsFolder:FindFirstChild(raidType or "ActiveRaid")
    if raid then
        tweenTo(raid.Position, 0.5)
        local joinEvent = ReplicatedStorage:FindFirstChild("JoinRaid")
        if joinEvent then
            pcall(function()
                joinEvent:FireServer()
            end)
            States.AutoRaid.CurrentRaid = raidType
            wait(math.random(CONFIG.RAID.JoinDelay.Min, CONFIG.RAID.JoinDelay.Max) * CONFIG.AUTO_FARM_SPEED.Current)
        end
    end
end

-- Função para Eventos
local function checkSeaEvent()
    if not States.Events.SeaEvent.Enabled or not isGameActive() then return end
    local event = Workspace:FindFirstChild("SeaEvent")
    if event then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        if (rootPart.Position - event.Position).Magnitude <= CONFIG.EVENTS.SeaEvent.Range then
            tweenTo(event.Position, 0.5)
            local joinEvent = ReplicatedStorage:FindFirstChild("JoinSeaEvent")
            if joinEvent then
                pcall(function()
                    joinEvent:FireServer()
                end)
                wait(math.random(0.5, 1) * CONFIG.AUTO_FARM_SPEED.Current)
            end
        end
    end
end

local function checkMirageIsland()
    if not States.Events.MirageIsland.Enabled or not isGameActive() then return end
    local event = Workspace:FindFirstChild("MirageIsland")
    if event then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        if (rootPart.Position - event.Position).Magnitude <= CONFIG.EVENTS.MirageIsland.Range then
            tweenTo(event.Position, 0.5)
            local joinEvent = ReplicatedStorage:FindFirstChild("JoinMirageIsland")
            if joinEvent then
                pcall(function()
                    joinEvent:FireServer()
                end)
                wait(math.random(0.5, 1) * CONFIG.AUTO_FARM_SPEED.Current)
            end
        end
    end
end

local function checkKitsuneEvent()
    if not States.Events.KitsuneEvent.Enabled or not isGameActive() then return end
    local event = Workspace:FindFirstChild("KitsuneEvent")
    if event then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        if (rootPart.Position - event.Position).Magnitude <= CONFIG.EVENTS.KitsuneEvent.Range then
            tweenTo(event.Position, 0.5)
            local joinEvent = ReplicatedStorage:FindFirstChild("JoinKitsuneEvent")
            if joinEvent then
                pcall(function()
                    joinEvent:FireServer()
                end)
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
local FarmSection = FarmTab:CreateSection("Controles de Auto Farm")
local AutoFarmToggle = FarmSection:CreateToggle({
    Name = "Ativar Auto Farm",
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
    Name = "Modo de Farm",
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

local FarmIslandDropdown = FarmSection:CreateDropdown({
    Name = "Ilha de Farm",
    Options = {"Any", "PirateIsland", "MarineIsland", "FrozenIsland"},
    CurrentOption = "Any",
    Flag = "FarmIsland",
    Callback = function(option)
        States.AutoFarm.Island = option
        Fluent:Notify({
            Title = "Ilha de Farm",
            Content = "Ilha ajustada para " .. option,
            Duration = 3
        })
    end
})

local CollectItemsButton = FarmSection:CreateButton({
    Name = "Coletar Itens Próximos",
    Callback = function()
        collectItems("Fruit")
        collectItems("Chest")
        Fluent:Notify({
            Title = "Coleta de Itens",
            Content = "Coletando frutas e baús próximos!",
            Duration = 3
        })
    end
})

local FarmSpeedSlider = FarmSection:CreateSlider({
    Name = "Velocidade de Farm",
    Min = CONFIG.AUTO_FARM_SPEED.Min,
    Max = CONFIG.AUTO_FARM_SPEED.Max,
    Increment = CONFIG.AUTO_FARM_SPEED.Step,
    Current = CONFIG.AUTO_FARM_SPEED.Current,
    Flag = "FarmSpeed",
    Callback = function(value)
        CONFIG.AUTO_FARM_SPEED.Current = value
        Fluent:Notify({
            Title = "Velocidade de Farm",
            Content = "Velocidade ajustada para " .. value,
            Duration = 3
        })
    end
})

-- Tab ESP
local ESPTab = Window:CreateTab("ESP")
local ESPSection = ESPTab:CreateSection("Controles de ESP")
local ESPToggle = ESPSection:CreateToggle({
    Name = "Ativar ESP",
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
    Name = "ESP para Inimigos",
    CurrentValue = true,
    Flag = "ESPEnemies",
    Callback = function(value)
        States.ESP.Enemies = value
        Fluent:Notify({
            Title = "ESP Inimigos",
            Content = value and "ESP para inimigos ativado!" or "ESP para inimigos desativado!",
            Duration = 3
        })
    end
})

local ESPFruitsToggle = ESPSection:CreateToggle({
    Name = "ESP para Frutas",
    CurrentValue = true,
    Flag = "ESPFruits",
    Callback = function(value)
        States.ESP.Fruits = value
        Fluent:Notify({
            Title = "ESP Frutas",
            Content = value and "ESP para frutas ativado!" or "ESP para frutas desativado!",
            Duration = 3
        })
    end
})

local ESPChestsToggle = ESPSection:CreateToggle({
    Name = "ESP para Baús",
    CurrentValue = true,
    Flag = "ESPChests",
    Callback = function(value)
        States.ESP.Chests = value
        Fluent:Notify({
            Title = "ESP Baús",
            Content = value and "ESP para baús ativado!" or "ESP para baús desativado!",
            Duration = 3
        })
    end
})

local ESPMissionNPCsToggle = ESPSection:CreateToggle({
    Name = "ESP para NPCs de Missão",
    CurrentValue = true,
    Flag = "ESPMissionNPCs",
    Callback = function(value)
        States.ESP.MissionNPCs = value
        Fluent:Notify({
            Title = "ESP NPCs de Missão",
            Content = value and "ESP para NPCs de missão ativado!" or "ESP para NPCs de missão desativado!",
            Duration = 3
        })
    end
})

local ESPEventsToggle = ESPSection:CreateToggle({
    Name = "ESP para Eventos",
    CurrentValue = true,
    Flag = "ESPEvents",
    Callback = function(value)
        States.ESP.Events = value
        Fluent:Notify({
            Title = "ESP Eventos",
            Content = value and "ESP para eventos ativado!" or "ESP para eventos desativado!",
            Duration = 3
        })
    end
})

local ESPScaleSlider = ESPSection:CreateSlider({
    Name = "Tamanho do ESP",
    Min = 0.5,
    Max = 2,
    Increment = 0.1,
    Current = 1,
    Flag = "ESPScale",
    Callback = function(value)
        States.ESP.Scale = value
        Fluent:Notify({
            Title = "Tamanho do ESP",
            Content = "Tamanho ajustado para " .. value,
            Duration = 3
        })
    end
})

-- Tab Teleport
local TeleportTab = Window:CreateTab("Teleport")
local TeleportSection = TeleportTab:CreateSection("Locais de Teleporte")
local TeleportIslandDropdown = TeleportSection:CreateDropdown({
    Name = "Teleport para Ilha",
    Options = {"PirateIsland", "MarineIsland", "FrozenIsland", "SandIsland"},
    CurrentOption = "PirateIsland",
    Flag = "TeleportIsland",
    Callback = function(option)
        teleportTo(option)
        Fluent:Notify({
            Title = "Teleport",
            Content = "Teleportado para " .. option,
            Duration = 3
        })
    end
})

local TeleportFruitDropdown = TeleportSection:CreateDropdown({
    Name = "Teleport para Fruta",
    Options = {"FruitSpawn1", "FruitSpawn2", "FruitSpawn3"},
    CurrentOption = "FruitSpawn1",
    Flag = "TeleportFruit",
    Callback = function(option)
        teleportTo(option)
        Fluent:Notify({
            Title = "Teleport",
            Content = "Teleportado para " .. option,
            Duration = 3
        })
    end
})

local TeleportEventDropdown = TeleportSection:CreateDropdown({
    Name = "Teleport para Evento",
    Options = {"MirageIsland", "SeaEvent", "KitsuneEvent"},
    CurrentOption = "MirageIsland",
    Flag = "TeleportEvent",
    Callback = function(option)
        teleportTo(option)
        Fluent:Notify({
            Title = "Teleport",
            Content = "Teleportado para " .. option,
            Duration = 3
        })
    end
})

local QuickTeleportButton = TeleportSection:CreateButton({
    Name = "Teleport Rápido (PirateIsland)",
    Callback = function()
        teleportTo("PirateIsland")
        Fluent:Notify({
            Title = "Teleport Rápido",
            Content = "Teleportado para PirateIsland!",
            Duration = 3
        })
    end
})

-- Tab Raid
local RaidTab = Window:CreateTab("Raid")
local RaidSection = RaidTab:CreateSection("Controles de Auto Raid")
local AutoRaidToggle = RaidSection:CreateToggle({
    Name = "Ativar Auto Raid",
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
    Name = "Tipo de Raid",
    Options = CONFIG.RAID.Types,
    CurrentOption = "Leviathan",
    Flag = "RaidType",
    Callback = function(option)
        States.AutoRaid.CurrentRaid = option
        Fluent:Notify({
            Title = "Tipo de Raid",
            Content = "Tipo ajustado para " .. option,
            Duration = 3
        })
    end
})

local StartRaidButton = RaidSection:CreateButton({
    Name = "Iniciar Raid Manualmente",
    Callback = function()
        if States.AutoRaid.CurrentRaid then
            autoRaid(States.AutoRaid.CurrentRaid)
            Fluent:Notify({
                Title = "Iniciar Raid",
                Content = "Iniciando " .. States.AutoRaid.CurrentRaid .. " raid!",
                Duration = 3
            })
        else
            Fluent:Notify({
                Title = "Erro",
                Content = "Selecione um tipo de raid primeiro!",
                Duration = 3
            })
        end
    end
})

-- Tab Stats
local StatsTab = Window:CreateTab("Stats")
local StatsSection = StatsTab:CreateSection("Controles de Auto Stats")
local AutoStatsToggle = StatsSection:CreateToggle({
    Name = "Ativar Auto Stats",
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

local StatsPriorityDropdown = StatsSection:CreateDropdown({
    Name = "Prioridade de Stats",
    Options = CONFIG.AUTO_STATS.Priorities,
    CurrentOption = "Melee",
    Flag = "StatsPriority",
    Callback = function(option)
        States.AutoStats.CurrentStat = option
        Fluent:Notify({
            Title = "Prioridade de Stats",
            Content = "Prioridade ajustada para " .. option,
            Duration = 3
        })
    end
})

local StatsPointsSlider = StatsSection:CreateSlider({
    Name = "Pontos por Intervalo",
    Min = 1,
    Max = CONFIG.AUTO_STATS.MaxPoints,
    Increment = 1,
    Current = 1,
    Flag = "StatsPoints",
    Callback = function(value)
        Fluent:Notify({
            Title = "Pontos por Intervalo",
            Content = "Ajustado para " .. value .. " pontos",
            Duration = 3
        })
    end
})

-- Tab Events
local EventsTab = Window:CreateTab("Events")
local EventsSection = EventsTab:CreateSection("Controles de Eventos")
local SeaEventToggle = EventsSection:CreateToggle({
    Name = "Ativar Sea Event",
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
    Name = "Ativar Mirage Island",
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
    Name = "Ativar Kitsune Event",
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

-- Tab Fruit Sniper
local FruitSniperTab = Window:CreateTab("Fruit Sniper")
local FruitSniperSection = FruitSniperTab:CreateSection("Controles de Fruit Sniper")
local FruitSniperToggle = FruitSniperSection:CreateToggle({
    Name = "Ativar Fruit Sniper",
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

local FruitSniperRangeSlider = FruitSniperSection:CreateSlider({
    Name = "Alcance do Fruit Sniper",
    Min = CONFIG.FRUIT_SNIPER.Range.Min,
    Max = CONFIG.FRUIT_SNIPER.Range.Max,
    Increment = 100,
    Current = CONFIG.FRUIT_SNIPER.Range.Current,
    Flag = "FruitSniperRange",
    Callback = function(value)
        CONFIG.FRUIT_SNIPER.Range.Current = value
        Fluent:Notify({
            Title = "Alcance do Fruit Sniper",
            Content = "Alcance ajustado para " .. value,
            Duration = 3
        })
    end
})

local FruitPriorityDropdown = FruitSniperSection:CreateDropdown({
    Name = "Prioridade de Frutas",
    Options = CONFIG.FRUIT_SNIPER.RareFruits,
    CurrentOption = "Dragon",
    Flag = "FruitPriority",
    Callback = function(option)
        Fluent:Notify({
            Title = "Prioridade de Frutas",
            Content = "Prioridade ajustada para " .. option,
            Duration = 3
        })
    end
})

-- Tab Misc
local MiscTab = Window:CreateTab("Misc")
local MiscSection = MiscTab:CreateSection("Configurações Adicionais")
local DetectionRangeSlider = MiscSection:CreateSlider({
    Name = "Alcance de Detecção",
    Min = CONFIG.DETECTION_RANGE.Min,
    Max = CONFIG.DETECTION_RANGE.Max,
    Increment = CONFIG.DETECTION_RANGE.Step,
    Current = CONFIG.DETECTION_RANGE.Current,
    Flag = "DetectionRange",
    Callback = function(value)
        CONFIG.DETECTION_RANGE.Current = value
        Fluent:Notify({
            Title = "Alcance de Detecção",
            Content = "Alcance ajustado para " .. value,
            Duration = 3
        })
    end
})

local ResetCharacterButton = MiscSection:CreateButton({
    Name = "Resetar Personagem",
    Callback = function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
            Fluent:Notify({
                Title = "Resetar Personagem",
                Content = "Personagem resetado!",
                Duration = 3
            })
        end
    end
})

local AntiStuckToggle = MiscSection:CreateToggle({
    Name = "Ativar Anti-Stuck",
    CurrentValue = true,
    Flag = "AntiStuckToggle",
    Callback = function(value)
        Fluent:Notify({
            Title = "Anti-Stuck",
            Content = value and "Anti-Stuck ativado!" or "Anti-Stuck desativado!",
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

        if States.AutoStats.Enabled then
            autoStats()
        end

        if States.FruitSniper.Enabled then
            fruitSniper()
        end

        if States.AutoRaid.Enabled then
            autoRaid(States.AutoRaid.CurrentRaid)
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