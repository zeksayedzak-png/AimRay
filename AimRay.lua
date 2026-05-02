local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Laith Scripts",
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

local AimbotEnabled = false
local TeamCheck = true
local SelectedTeams = {}
local ExcludedPlayers = {}
local AimbotRadius = 200
local CircleColor = Color3.fromRGB(255, 0, 0)
local TargetPart = "Head"
local ESPEnabled = false
local HighlightEnabled = false
local VisualsTeamCheck = true

-- متغيرات الـ Xray الجديدة
local xrayEnabled = true 

local playerHighlights = {}
local highlightEnabled = false
local enemyColor = Color3.fromRGB(255, 50, 50) -- Red for enemies
local teammateColor = Color3.fromRGB(50, 255, 50) -- Green for teammates
local neutralColor = Color3.fromRGB(100, 150, 255) -- Blue for neutral
local customTeammates = {} 
local customTeammateColor = Color3.fromRGB(100, 150, 255)

local TeamDropdown
local PlayerDropdown

local AimbotCircle = Drawing.new("Circle")
AimbotCircle.Visible = false
AimbotCircle.Thickness = 2
AimbotCircle.NumSides = 100
AimbotCircle.Radius = AimbotRadius
AimbotCircle.Color = CircleColor
AimbotCircle.Filled = false
AimbotCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

local function GetTeamNames()
    local names = {}
    for _, team in ipairs(TeamsService:GetTeams()) do
        table.insert(names, team.Name)
    end
    table.sort(names)
    return names
end

local function GetPlayerNames()
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(names, player.Name)
        end
    end
    table.sort(names)
    return names
end

local function IsVisible(targetPart)
    local rayOrigin = Camera.CFrame.Position
    local rayDirection = (targetPart.Position - rayOrigin).Unit * 500
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    if result then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end
    return true
end

local function getTeamColor(player)
    if table.find(customTeammates, player.Name) then
        return customTeammateColor
    end
    
    if player == LocalPlayer then
        return Color3.fromRGB(255, 255, 255)
    end
    
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
        if highlight.nameTag then highlight.nameTag:Destroy() end
        
        highlight.main = Instance.new("Highlight")
        highlight.main.Name = "ESP_" .. player.UserId
        highlight.main.Adornee = character
        highlight.main.FillColor = getTeamColor(player)
        highlight.main.FillTransparency = 0.5 -- جعل اللون أوضح قليلاً للأعداء
        highlight.main.OutlineColor = Color3.new(1,1,1)
        highlight.main.OutlineTransparency = 0
        highlight.main.Enabled = highlightEnabled
        -- هنا خاصية الـ Xray (الرؤية خلف الجدران)
        highlight.main.DepthMode = xrayEnabled and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        highlight.main.Parent = character
        
        local head = character:FindFirstChild("Head")
        if head then
            local nameTag = Instance.new("BillboardGui")
            nameTag.Name = "NameTag_" .. player.UserId
            nameTag.Adornee = head
            nameTag.AlwaysOnTop = true
            nameTag.StudsOffset = Vector3.new(0, 2.5, 0)
            nameTag.MaxDistance = 0 
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "Label"
            nameLabel.Size = UDim2.new(0, 100, 0, 20)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.Name
            nameLabel.TextColor3 = getTeamColor(player)
            nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            nameLabel.TextStrokeTransparency = 0.2
            nameLabel.Font = Enum.Font.GothamMedium
            nameLabel.TextScaled = true
            nameLabel.Parent = nameTag
            
            nameTag.Parent = head
            highlight.nameTag = nameTag
            nameTag.Enabled = highlightEnabled
        end
    end
    
    if player.Character then
        setupCharacter(player.Character)
    end
    
    player.CharacterAdded:Connect(function(character)
        setupCharacter(character)
    end)
    
    playerHighlights[player] = highlight
end

local function removeHighlight(player)
    if playerHighlights[player] then
        local highlight = playerHighlights[player]
        if highlight.main then highlight.main:Destroy() end
        if highlight.nameTag then highlight.nameTag:Destroy() end
        playerHighlights[player] = nil
    end
end

local function updateAllHighlightColors()
    for player, highlight in pairs(playerHighlights) do
        if highlight.main then
            highlight.main.FillColor = getTeamColor(player)
            highlight.main.OutlineColor = Color3.new(1,1,1)
            -- تحديث وضع Xray
            highlight.main.DepthMode = xrayEnabled and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        end
        if highlight.nameTag then
            local label = highlight.nameTag:FindFirstChild("Label")
            if label then
                label.TextColor3 = getTeamColor(player)
            end
        end
    end
end

local function toggleHighlights()
    highlightEnabled = not highlightEnabled
    for player, highlight in pairs(playerHighlights) do
        if highlight.main then
            highlight.main.Enabled = highlightEnabled
        end
        if highlight.nameTag then
            highlight.nameTag.Enabled = highlightEnabled
        end
    end
end

RunService.RenderStepped:Connect(function()
    if not highlightEnabled then return end
    
    for player, highlight in pairs(playerHighlights) do
        if highlight.nameTag and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head and highlight.nameTag.Enabled then
                local distance = (head.Position - Camera.CFrame.Position).Magnitude
                local nameLabel = highlight.nameTag:FindFirstChild("Label")
                if nameLabel then
                    local scaleFactor = math.clamp(distance / 100, 0.5, 2.0)
                    local calculatedSize = math.clamp(100 * scaleFactor, 80, 150)
                    highlight.nameTag.Size = UDim2.new(0, calculatedSize, 0, calculatedSize * 0.2)
                end
            end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightBracket then
        toggleHighlights()
    end
end)

local function GetClosestPlayer()
    local ClosestPlayer = nil
    local ShortestDistance = AimbotRadius
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 and not table.find(ExcludedPlayers, player.Name) then
            if TeamCheck and player.Team == LocalPlayer.Team then
                continue
            end
            if #SelectedTeams > 0 and not table.find(SelectedTeams, player.Team.Name) then
                continue
            end
            local part = player.Character:FindFirstChild(TargetPart)
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen and IsVisible(part) then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                    if distance < ShortestDistance then
                        ShortestDistance = distance
                        ClosestPlayer = player
                    end
                end
            end
        end
    end
    return ClosestPlayer
end

local AimbotConnection
AimbotConnection = RunService.RenderStepped:Connect(function()
    if not AimbotEnabled then return end
    
    local closest = GetClosestPlayer()
    if closest and closest.Character then
        local targetPart = closest.Character:FindFirstChild(TargetPart)
        if targetPart then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
        end
    end
    AimbotCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end)

local function UpdateCircle()
    AimbotCircle.Radius = AimbotRadius
    AimbotCircle.Color = CircleColor
    AimbotCircle.Visible = AimbotEnabled
end

-- ==========================================
-- الأقسام (Tabs) كما هي بدون أي تغيير في الوظائف
-- ==========================================

local AimbotTab = Window:CreateTab("Aimbot", 4483362458)

AimbotTab:CreateToggle({
    Name = "Aimbot Toggle",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(Value)
        AimbotEnabled = Value
        UpdateCircle()
    end,
})

TeamDropdown = AimbotTab:CreateDropdown({
    Name = "Select Teams for Aimbot (Multiple)",
    Options = GetTeamNames(),
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "SelectedTeams",
    Callback = function(Options)
        SelectedTeams = Options
    end,
})

AimbotTab:CreateButton({
    Name = "  Refresh Teams List",
    Callback = function()
        local newOptions = GetTeamNames()
        TeamDropdown:Refresh(newOptions)
    end,
})

PlayerDropdown = AimbotTab:CreateDropdown({
    Name = "Exclude Players (Multiple)",
    Options = GetPlayerNames(),
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "ExcludedPlayers",
    Callback = function(Options)
        ExcludedPlayers = Options
    end,
})

AimbotTab:CreateButton({
    Name = "  Refresh Players List",
    Callback = function()
        local newOptions = GetPlayerNames()
        PlayerDropdown:Refresh(newOptions)
    end,
})

AimbotTab:CreateToggle({
    Name = "Team Check (Ignore Own Team)",
    CurrentValue = true,
    Flag = "TeamCheck",
    Callback = function(Value)
        TeamCheck = Value
    end,
})

AimbotTab:CreateToggle({
    Name = "Wall Check (Ignore Walls)",
    CurrentValue = true,
    Flag = "WallCheck",
    Callback = function(Value)
        _G.WallCheckEnabled = Value
    end,
})

AimbotTab:CreateSlider({
    Name = "Aimbot Radius",
    Range = {50, 1000},
    Increment = 10,
    Suffix = "px",
    CurrentValue = 200,
    Flag = "AimbotRadius",
    Callback = function(Value)
        AimbotRadius = Value
        UpdateCircle()
    end,
})

AimbotTab:CreateColorPicker({
    Name = "Circle Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "CircleColor",
    Callback = function(Color)
        CircleColor = Color
        UpdateCircle()
    end
})

AimbotTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso"},
    CurrentOption = {"Head"},
    MultipleOptions = false,
    Flag = "TargetPart",
    Callback = function(Option)
        TargetPart = Option[1]
    end,
})

-- ==========================================
-- تعديلات قسم Visuals لإضافة الـ Xray
-- ==========================================

local VisualsTab = Window:CreateTab("Visuals", 4483362458)

VisualsTab:CreateToggle({
    Name = "Toggle ESP (Right Bracket Key)",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(Value)
        if highlightEnabled ~= Value then
            toggleHighlights()
        end
        ESPEnabled = Value
    end,
})

-- إضافة زر الـ Xray الجديد هنا
VisualsTab:CreateToggle({
    Name = "Xray (See Enemies Through Walls)",
    CurrentValue = true,
    Flag = "XrayToggle",
    Callback = function(Value)
        xrayEnabled = Value
        updateAllHighlightColors() -- تحديث فوري للألوان والشفافية
    end,
})

local customTeammateDropdown = VisualsTab:CreateDropdown({
    Name = "Select Custom Teammates (Multiple)",
    Options = GetPlayerNames(),
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "CustomTeammates",
    Callback = function(Options)
        customTeammates = Options
        updateAllHighlightColors()
    end,
})

VisualsTab:CreateButton({
    Name = "  Refresh Players List",
    Callback = function()
        local newOptions = GetPlayerNames()
        customTeammateDropdown:Refresh(newOptions)
    end,
})

VisualsTab:CreateColorPicker({
    Name = "Enemy Color (Xray Color)",
    Color = Color3.fromRGB(255, 50, 50),
    Flag = "EnemyColor",
    Callback = function(Color)
        enemyColor = Color
        updateAllHighlightColors()
    end,
})

VisualsTab:CreateColorPicker({
    Name = "Teammate Color",
    Color = Color3.fromRGB(50, 255, 50),
    Flag = "TeammateColor",
    Callback = function(Color)
        teammateColor = Color
        updateAllHighlightColors()
    end,
})

VisualsTab:CreateColorPicker({
    Name = "Neutral Player Color",
    Color = Color3.fromRGB(100, 150, 255),
    Flag = "NeutralColor",
    Callback = function(Color)
        neutralColor = Color
        updateAllHighlightColors()
    end,
})

-- ==========================================
-- قسم الـ Misc كما هو
-- ==========================================

local MiscTab = Window:CreateTab("Misc", 4483362458)

MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

_G.WallCheckEnabled = true

local oldIsVisible = IsVisible
IsVisible = function(targetPart)
    if not _G.WallCheckEnabled then return true end
    return oldIsVisible(targetPart)
end

for _, player in pairs(Players:GetPlayers()) do
    createHighlight(player)
end

Players.PlayerAdded:Connect(function(player)
    createHighlight(player)
end)

Players.PlayerRemoving:Connect(function(player)
    removeHighlight(player)
end)

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(updateAllHighlightColors)

Rayfield:LoadConfiguration()
