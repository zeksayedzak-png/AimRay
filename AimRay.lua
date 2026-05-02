local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Laith Scripts | MVS",
    LoadingTitle = "Murders Vs Sheriffs",
    LoadingSubtitle = "By: Laith Scripts",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "LaithScripts",
        FileName = "MVSConfig"
    }
})

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TeamsService = game:GetService("Teams")
local UserInputService = game:GetService("UserInputService")

-- Variables
local AimbotEnabled = false
local TeamCheck = true
local SelectedTeams = {}
local ExcludedPlayers = {}
local AimbotRadius = 200
local CircleColor = Color3.fromRGB(255, 0, 0)
local TargetPart = "Head"

local ESPEnabled = false
local enemyXrayEnabled = true -- Default X-ray on
local enemyFillTransparency = 0.5
local enemyOutlineTransparency = 0

local playerHighlights = {}
local enemyColor = Color3.fromRGB(255, 0, 0) -- Red for enemies
local teammateColor = Color3.fromRGB(0, 255, 0) -- Green for teammates
local neutralColor = Color3.fromRGB(255, 255, 255)
local customTeammates = {}
local customTeammateColor = Color3.fromRGB(0, 162, 255)

local TeamDropdown
local PlayerDropdown

-- Aimbot FOV Circle
local AimbotCircle = Drawing.new("Circle")
AimbotCircle.Visible = false
AimbotCircle.Thickness = 2
AimbotCircle.NumSides = 100
AimbotCircle.Radius = AimbotRadius
AimbotCircle.Color = CircleColor
AimbotCircle.Filled = false

-- Functions
local function GetTeamNames()
    local names = {}
    for _, team in ipairs(TeamsService:GetTeams()) do table.insert(names, team.Name) end
    table.sort(names)
    return names
end

local function GetPlayerNames()
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then table.insert(names, player.Name) end
    end
    table.sort(names)
    return names
end

local function getTeamColor(player)
    if table.find(customTeammates, player.Name) then return customTeammateColor end
    if player == LocalPlayer then return Color3.fromRGB(255, 255, 255) end
    
    if LocalPlayer.Team and player.Team then
        if LocalPlayer.Team == player.Team then
            return teammateColor
        else
            return enemyColor
        end
    end
    return neutralColor
end

local function createHighlight(player)
    if player == LocalPlayer then return end
    
    local highlight = { main = nil, nameTag = nil }
    
    local function setupCharacter(character)
        if not character then return end
        if highlight.main then highlight.main:Destroy() end
        
        local isEnemy = (player.Team ~= LocalPlayer.Team)
        
        highlight.main = Instance.new("Highlight")
        highlight.main.Name = "ESP_" .. player.UserId
        highlight.main.Adornee = character
        highlight.main.FillColor = getTeamColor(player)
        -- X-Ray Logic:
        highlight.main.FillTransparency = (isEnemy and enemyXrayEnabled) and enemyFillTransparency or 0.8
        highlight.main.OutlineColor = getTeamColor(player)
        highlight.main.OutlineTransparency = (isEnemy and enemyXrayEnabled) and enemyOutlineTransparency or 0
        
        -- DepthMode.AlwaysOnTop هو ما يجعلها X-ray
        highlight.main.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.main.Enabled = ESPEnabled
        highlight.main.Parent = character
        
        local head = character:FindFirstChild("Head")
        if head then
            local nameTag = Instance.new("BillboardGui")
            nameTag.Name = "NameTag_" .. player.UserId
            nameTag.Adornee = head
            nameTag.AlwaysOnTop = true
            nameTag.Size = UDim2.new(0, 100, 0, 20)
            nameTag.StudsOffset = Vector3.new(0, 3, 0)
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, 0, 1, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.Name
            nameLabel.TextColor3 = getTeamColor(player)
            nameLabel.TextStrokeTransparency = 0
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 14
            nameLabel.Parent = nameTag
            
            nameTag.Parent = head
            highlight.nameTag = nameTag
            nameTag.Enabled = ESPEnabled
        end
    end
    
    if player.Character then setupCharacter(player.Character) end
    player.CharacterAdded:Connect(setupCharacter)
    playerHighlights[player] = highlight
end

local function updateAllESP()
    for player, highlight in pairs(playerHighlights) do
        local isEnemy = (player.Team ~= LocalPlayer.Team)
        if highlight.main then
            highlight.main.Enabled = ESPEnabled
            highlight.main.FillColor = getTeamColor(player)
            highlight.main.OutlineColor = getTeamColor(player)
            if isEnemy and enemyXrayEnabled then
                highlight.main.FillTransparency = enemyFillTransparency
                highlight.main.OutlineTransparency = enemyOutlineTransparency
            end
        end
        if highlight.nameTag then
            highlight.nameTag.Enabled = ESPEnabled
            local label = highlight.nameTag:FindFirstChildWhichIsA("TextLabel")
            if label then label.TextColor3 = getTeamColor(player) end
        end
    end
end

-- Tabs
local AimbotTab = Window:CreateTab("Aimbot", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)

-- Aimbot Elements (القديمة نفسها)
AimbotTab:CreateToggle({
    Name = "Aimbot Toggle",
    CurrentValue = false,
    Callback = function(Value)
        AimbotEnabled = Value
        AimbotCircle.Visible = Value
    end,
})

AimbotTab:CreateSlider({
    Name = "Aimbot Radius",
    Range = {50, 1000},
    Increment = 10,
    CurrentValue = 200,
    Callback = function(Value)
        AimbotRadius = Value
        AimbotCircle.Radius = Value
    end,
})

-- Visuals Elements (المحدثة مع X-ray)
VisualsTab:CreateToggle({
    Name = "Master ESP Toggle",
    CurrentValue = false,
    Callback = function(Value)
        ESPEnabled = Value
        updateAllESP()
    end,
})

VisualsTab:CreateToggle({
    Name = "Enemy X-ray (Red Highlight)",
    CurrentValue = true,
    Callback = function(Value)
        enemyXrayEnabled = Value
        updateAllESP()
    end,
})

VisualsTab:CreateSlider({
    Name = "X-ray Fill Intensity",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0.5,
    Callback = function(Value)
        enemyFillTransparency = Value
        updateAllESP()
    end,
})

VisualsTab:CreateColorPicker({
    Name = "Enemy Color (X-ray)",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(Color)
        enemyColor = Color
        updateAllESP()
    end
})

VisualsTab:CreateColorPicker({
    Name = "Teammate Color",
    Color = Color3.fromRGB(0, 255, 0),
    Callback = function(Color)
        teammateColor = Color
        updateAllESP()
    end
})

-- Logic Loop
RunService.RenderStepped:Connect(function()
    AimbotCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    if AimbotEnabled then
        local ClosestPlayer = nil
        local ShortestDistance = AimbotRadius
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                if TeamCheck and player.Team == LocalPlayer.Team then continue end
                
                local part = player.Character:FindFirstChild(TargetPart)
                if part then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                        if distance < ShortestDistance then
                            ShortestDistance = distance
                            ClosestPlayer = player
                        end
                    end
                end
            end
        end
        
        if ClosestPlayer and ClosestPlayer.Character then
            local target = ClosestPlayer.Character:FindFirstChild(TargetPart)
            if target then
                Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, target.Position)
            end
        end
    end
end)

-- Initialize
for _, player in ipairs(Players:GetPlayers()) do createHighlight(player) end
Players.PlayerAdded:Connect(createHighlight)
Players.PlayerRemoving:Connect(function(player)
    if playerHighlights[player] then
        if playerHighlights[player].main then playerHighlights[player].main:Destroy() end
        if playerHighlights[player].nameTag then playerHighlights[player].nameTag:Destroy() end
        playerHighlights[player] = nil
    end
end)

Rayfield:LoadConfiguration()
