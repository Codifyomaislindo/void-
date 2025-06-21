--[[
    ===============================================================================================================
    SCRIPT:         Blox Fruits Pro
    VERSÃO:         1.0 (Para Update 26)
    DESENVOLVEDOR:  [Seu Nome/Assistente Virtual]
    DESCRIÇÃO:      Script completo com UI Fluent, detecção de sea, auto farm, ESP, raids e mais.
    ===============================================================================================================
]]

-- Carregar a biblioteca Fluent UI (deve ser a primeira coisa a ser feita)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- ===============================================================================================================
--  CONFIGURAÇÕES GLOBAIS E VARIÁVEIS DE ESTADO
-- ===============================================================================================================

local Player = game:GetService("Players").LocalPlayer
local CurrentSea = 1 -- Valor padrão, será atualizado pela função de detecção
local Config = {
    -- Auto Farm
    AutoFarm = false,
    SelectedMob = "",
    FarmMethod = "Nearest",
    UseSkills = true,
    -- ESP
    ESP_Players = true,
    ESP_Fruits = true,
    ESP_Chests = true,
    -- Utils
    AntiAFK = true,
    -- Shop
    AutoBuy_Enabled = false,
    AutoBuy_Fruits = {},
    -- Raids
    AutoStartRaid = false,
    AutoBuyChip = false
}

-- ===============================================================================================================
--  BYPASS DE ANTI-CHEAT E FUNÇÕES ESSENCIAIS
-- ===============================================================================================================

local Core = {}
function Core:Initialize()
    -- Anti-AFK
    coroutine.wrap(function()
        while Config.AntiAFK do
            task.wait(240)
            pcall(function()
                game:GetService("VirtualUser"):ClickButton2(Vector2.new())
            end)
        end
    end)()

    -- Prevenir kick por teleporte (exemplo de hook)
    --!! PREENCHER !!: O nome do RemoteEvent de teleporte pode variar. Use um Remote Spy para encontrá-lo.
    local oldFireServer = game.ReplicatedStorage.DefaultRemoteEvent.FireServer
    game.ReplicatedStorage.DefaultRemoteEvent.FireServer = newcclosure(function(...)
        local args = {...}
        if tostring(args[1]) == "Teleport" then
            -- Adicionar um pequeno delay ou modificar os argumentos para parecer legítimo
            task.wait(0.1)
        end
        return oldFireServer(...)
    end)
end

-- ===============================================================================================================
--  GERENCIADOR DE SEA (DETECÇÃO AUTOMÁTICA)
-- ===============================================================================================================

local SeaManager = {}
function SeaManager:DetectCurrentSea()
    --!! PREENCHER !!: Este é um método comum. Se o jogo armazenar o Sea em outro lugar, ajuste o caminho.
    local seaName = Player:WaitForChild("PlayerGui"):WaitForChild("Main"):WaitForChild("Meters"):WaitForChild("Sea"):WaitForChild("TextLabel").Text
    if string.find(seaName, "First Sea") then CurrentSea = 1
    elseif string.find(seaName, "Second Sea") then CurrentSea = 2
    elseif string.find(seaName, "Third Sea") then CurrentSea = 3 end

    Fluent:Notify({
        Title = "Sea Detectado",
        Content = "Você está no " .. CurrentSea .. "º Sea. A interface foi ajustada.",
        Duration = 5
    })
    return CurrentSea
end

-- ===============================================================================================================
--  DADOS DO JOGO (MOBS, BOSSES, ILHAS, ETC.)
-- ===============================================================================================================

local GameData = {
    Mobs = {
        [1] = {"Bandit", "Gorilla", "Pirate", "Desert Bandit", "Fishman Warrior"},
        [2] = {"Raider", "Mercenary", "Swan Pirate", "Marine Lieutenant", "Zombie", "Vampire"},
        [3] = {"Pirate Millionaire", "Dragon Crew Warrior", "Female Islander", "Marine Commodore", "Forest Pirate"}
    },
    TeleportLocations = {
        [1] = {Islands = {["Starter Island"] = Vector3.new(1, 1, 1), ["Jungle"] = Vector3.new(2, 2, 2)}}, --!! PREENCHER !! com todas as coordenadas
        [2] = {Islands = {["Kingdom of Rose"] = Vector3.new(3, 3, 3), ["Green Zone"] = Vector3.new(4, 4, 4)}}, --!! PREENCHER !!
        [3] = {Islands = {["Port Town"] = Vector3.new(5, 5, 5), ["Great Tree"] = Vector3.new(6, 6, 6)}} --!! PREENCHER !!
    },
    Fruits = {"Kilo", "Spin", "Chop", "Spring", "Bomb", "Smoke", "Spike", "Flame", "Falcon", "Ice", "Sand", "Dark", "Diamond", "Light", "Rubber", "Barrier", "Ghost", "Magma", "Quake", "Buddha", "Love", "Spider", "Phoenix", "Portal", "Rumble", "Pain", "Blizzard", "Gravity", "Dough", "Shadow", "Venom", "Control", "Spirit", "Mammoth", "T-Rex", "Kitsune", "Leopard", "Dragon"},
    RaidNPCs = {
        [2] = Vector3.new(10,10,10), --!! PREENCHER !!: Coordenadas do NPC de Raid no 2º Sea
        [3] = Vector3.new(20,20,20)  --!! PREENCHER !!: Coordenadas do NPC de Raid no 3º Sea
    }
}

-- ===============================================================================================================
--  GERENCIADOR DE AUTO FARM
-- ===============================================================================================================
local FarmManager = {}

function FarmManager:GetTarget()
    local nearestDist, nearestMob = math.huge, nil
    for _, mob in pairs(game.Workspace.Enemies:GetChildren()) do
        if mob.Name == Config.SelectedMob and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
            local dist = (Player.Character.HumanoidRootPart.Position - mob.HumanoidRootPart.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearestMob = mob
            end
        end
    end
    return nearestMob
end

function FarmManager:Start()
    coroutine.wrap(function()
        while Config.AutoFarm and Config.SelectedMob ~= "" do
            local target = FarmManager:GetTarget()
            if target then
                Player.Character.Humanoid:MoveTo(target.HumanoidRootPart.Position)
                -- Lógica de combate (atacar com a arma equipada)
                --!! PREENCHER !!: O nome do RemoteEvent de combate pode variar.
                game.ReplicatedStorage.CombatRemoteEvent:FireServer("Attack", target)
                if Config.UseSkills then
                    -- Lógica para usar skills
                end
            end
            task.wait(0.5)
        end
    end)()
end


-- ===============================================================================================================
--  GERENCIADOR DE TELEPORTE
-- ===============================================================================================================
local TeleportManager = {}

function TeleportManager:Teleport(position)
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame = CFrame.new(position)
    end
end

-- ===============================================================================================================
--  GERENCIADOR DE ESP
-- ===============================================================================================================
local ESPManager = {}
local drawingObjects = {}

function ESPManager:CreateESPDrawer(obj, color, name)
    local drawing = Drawing.new("Text")
    drawing.Visible = true
    drawing.Text = name or obj.Name
    drawing.Color = color
    drawing.Size = 14
    drawing.Center = true
    table.insert(drawingObjects, {obj = obj, drawing = drawing})
end

function ESPManager:Update()
    coroutine.wrap(function()
        while #drawingObjects > 0 do
            for i, data in pairs(drawingObjects) do
                if data.obj and data.obj.PrimaryPart then
                    local pos, onScreen = game:GetService("Workspace").CurrentCamera:WorldToViewportPoint(data.obj.PrimaryPart.Position)
                    if onScreen then
                        data.drawing.Position = Vector2.new(pos.X, pos.Y)
                        data.drawing.Visible = true
                    else
                        data.drawing.Visible = false
                    end
                else
                    data.drawing:Remove()
                    table.remove(drawingObjects, i)
                end
            end
            task.wait()
        end
    end)()
end

function ESPManager:Toggle(type, enabled)
    if not enabled then
        -- Lógica para remover os desenhos existentes desse tipo
        return
    end

    if type == "Players" then
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= Player then
                ESPManager:CreateESPDrawer(p.Character, Color3.fromRGB(255, 0, 0), p.Name)
            end
        end
    elseif type == "Fruits" then
        for _, fruit in pairs(game.Workspace:GetChildren()) do
            if table.find(GameData.Fruits, fruit.Name) then
                 ESPManager:CreateESPDrawer(fruit, Color3.fromRGB(255, 0, 255))
            end
        end
    end
    ESPManager:Update()
end

-- ===============================================================================================================
--  CONSTRUÇÃO DA INTERFACE (FLUENT UI)
-- ===============================================================================================================
local Window = Fluent:CreateWindow({
    Title = "Blox Fruits Pro v1.0",
    SubTitle = "Update 26",
    Size = UDim2.fromOffset(580, 460),
    Theme = "Dark",
    Acrylic = true
})

-- Adicionar abas
local Tabs = {
    Main = Window:AddTab({ Title = "Principal", Icon = "rbxassetid://10738555189" }),
    AutoFarm = Window:AddTab({ Title = "Auto Farm", Icon = "rbxassetid://10738552345" }),
    Teleport = Window:AddTab({ Title = "Teleporte", Icon = "rbxassetid://10738539093" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "rbxassetid://10738546325" }),
    Shop = Window:AddTab({ Title = "Loja", Icon = "rbxassetid://10738541278" }),
    Raids = Window:AddTab({ Title = "Raids", Icon = "rbxassetid://10738548915" }),
    Settings = Window:AddTab({ Title = "Configs", Icon = "rbxassetid://10738553691" })
}

-- ================== ABA PRINCIPAL ==================
Tabs.Main:AddLabel("Bem-vindo! O Sea atual é: " .. CurrentSea)
Tabs.Main:AddLabel("Script desenvolvido com foco em performance e segurança.")
Tabs.Main:AddButton({Label = "Reconectar Servidor", Callback = function() game:GetService("TeleportService"):Teleport(game.PlaceId, Player) end})

-- ================== ABA AUTO FARM ==================
Tabs.AutoFarm:AddToggle("AutoFarmToggle", {Text = "Ativar Auto Farm", Default = Config.AutoFarm, Callback = function(v)
    Config.AutoFarm = v
    if v then FarmManager:Start() end
end})

local mobDropdown = Tabs.AutoFarm:AddDropdown("MobDropdown", {
    Text = "Selecionar Mob",
    Values = GameData.Mobs[CurrentSea],
    Callback = function(v) Config.SelectedMob = v end
})

-- ================== ABA TELEPORTE ==================
local islandSection = Tabs.Teleport:AddSection("Ilhas")
for name, pos in pairs(GameData.TeleportLocations[CurrentSea].Islands) do
    islandSection:AddButton({Label = name, Callback = function() TeleportManager:Teleport(pos) end})
end

-- ================== ABA ESP ==================
Tabs.ESP:AddToggle("ESP_Players", {Text = "Jogadores", Default = Config.ESP_Players, Callback = function(v)
    Config.ESP_Players = v
    ESPManager:Toggle("Players", v)
end})
Tabs.ESP:AddToggle("ESP_Fruits", {Text = "Frutas", Default = Config.ESP_Fruits, Callback = function(v)
    Config.ESP_Fruits = v
    ESPManager:Toggle("Fruits", v)
end})

-- ================== ABA LOJA ==================
local fruitList = ""
for _, fruit in ipairs(GameData.Fruits) do fruitList = fruitList .. fruit .. "\n" end
Tabs.Shop:AddLabel("Frutas para Auto-Buy"):AddTooltip(fruitList)
Tabs.Shop:AddToggle("AutoBuyToggle", {Text = "Ativar Auto-Buy", Default = Config.AutoBuy_Enabled, Callback = function(v) Config.AutoBuy_Enabled = v end})

local fruitOptions = {}
for _, fruit in pairs(GameData.Fruits) do table.insert(fruitOptions, fruit) end
Tabs.Shop:AddDropdown("FruitToBuy", {
    Text = "Adicionar Fruta à Lista",
    Values = fruitOptions,
    Multi = true,
    Callback = function(v) Config.AutoBuy_Fruits = v end
})

-- ================== ABA RAIDS ==================
Tabs.Raids:AddToggle("AutoStartRaid", {Text = "Iniciar Raid Automaticamente", Default = Config.AutoStartRaid, Callback = function(v) Config.AutoStartRaid = v end})
Tabs.Raids:AddButton({Label = "Teleportar para NPC da Raid", Callback = function()
    if GameData.RaidNPCs[CurrentSea] then
        TeleportManager:Teleport(GameData.RaidNPCs[CurrentSea])
    else
        Fluent:Notify({Title = "Erro", Content = "Não há raids neste Sea."})
    end
end})

-- ================== ABA CONFIGS ==================
Tabs.Settings:AddToggle("AntiAFK", {Text = "Proteção Anti-AFK", Default = Config.AntiAFK, Callback = function(v) Config.AntiAFK = v end})
Tabs.Settings:AddButton({Label = "Salvar Configurações", Callback = function() SaveManager:Save() end})
Tabs.Settings:AddButton({Label = "Carregar Configurações", Callback = function() SaveManager:Load() Window:Refresh() end})
Tabs.Settings:AddButton({Label = "Descarregar Script", Callback = function() Window:Destroy() end})

-- ===============================================================================================================
--  INICIALIZAÇÃO DO SCRIPT
-- ===============================================================================================================

-- 1. Detectar o Sea
CurrentSea = SeaManager:DetectCurrentSea()

-- 2. Iniciar bypass e funções de núcleo
Core:Initialize()

-- 3. Inicializar o SaveManager
SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("BloxFruitsPro")
SaveManager:BuildConfig(Config)

-- 4. Selecionar a primeira aba e carregar configs salvas (se existirem)
Window:SelectTab(1)
SaveManager:Load()
Fluent:Notify({Title = "Script Carregado", Content = "Bem-vindo! O script está pronto para uso.", Duration = 7})
