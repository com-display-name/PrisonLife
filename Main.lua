-- i quit coding this so i can do other things
-- some things might not work well but you can prob fix it


-- getgenv().IsDebugging = true

if not game:IsLoaded() then 
    game.Loaded:Wait()
    task.wait(1)
end
local IsLoading = true
local LoadingStartTime = tick()


local Players = cloneref(game:GetService("Players"))
local Teams = cloneref(game:GetService("Teams"))
local Lighting = cloneref(game:GetService("Lighting"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local HTTPService = cloneref(game:GetService("HttpService"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local StarterGui = cloneref(game:GetService("StarterGui"))
local Debris = cloneref(game:GetService("Debris"))
local TweenService = cloneref(game:GetService("TweenService"))
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer
local TextChatService = cloneref(game:GetService("TextChatService"))


local RemoteEvents = {
    Melee = ReplicatedStorage:WaitForChild("meleeEvent"),
    Arrest = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ArrestPlayer"),
    InteractItem =  ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("InteractWithItem"),
    RequestTeamChange = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RequestTeamChange"),
    GiverPressed = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GiverPressed"),
    MessageReceived = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("MessageReceived")
}

local Functions = {
    Reload = filtergc("function", {Name = "reload"}, true),
    castRay = filtergc("function", {Name = "castRay"}, true),
    CreateBulletTracer = filtergc("function", {Name = "createBullet"}, true),
    CreateTaserTracer = filtergc("function", {Name = "createTaser"}, true),
    CreateSniperTracer = filtergc("function", {Name = "createSniper"}, true)
}
local debugging = getgenv().IsDebugging and getgenv().IsDebugging == true

if getgenv().RanPLScript then

    StarterGui:SetCore("SendNotification", {
        Title = "Already executed",
        Text = "Please rejoin to execute again",
        Duration = 5, 
    })
    pcall(function()
        
        local ImageURL = request({
            Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. LP.UserId .. "&size=150x150&format=Png&isCircular=false",
            Method = "GET"
        })

        local FinalURL
        if ImageURL and ImageURL.Body then
            local decoded = HTTPService:JSONDecode(ImageURL.Body)
            if decoded and decoded.data and decoded.data[1] then
                FinalURL = decoded.data[1].imageUrl
            end
        end
        
    -- dont bother sending stuff to the webhook, server is deleted
        --[[ request({
            Url = "https://discord.com/api/webhooks/1541849938894262378/_pbA7kftReIvZQztxkjkO3JbbdZxw2UCL1uizg26gQm70sPS4GPcCrzvMXe2ioLq3pb9",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HTTPService:JSONEncode({
                content = nil,
                embeds = {
                    {
                        description = "Username: " .. LP.Name .. "\nUserID: " .. LP.UserId .."\nExecutor: " .. (identifyexecutor and identifyexecutor() or "Unknown"),
                        color = debugging and 6579400 or 6579300,
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
                        footer = {
                            text = "Type: " .. (debugging and "Debug" or "Normal")
                        },
                        author = {
                            name = "Double exec Log:"
                        },
                        thumbnail = {
                            url = FinalURL
                        }
                    }
                },
                attachments = {}
            })
        }) -- Exec Logs ]]
    end)
    return
else
    -- dont bother sending stuff to the webhook, server is deleted
    getgenv().RanPLScript = true
    pcall(function()
        local ImageURL = request({
            Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. LP.UserId .. "&size=150x150&format=Png&isCircular=false",
            Method = "GET"
        })

        local FinalURL
        if ImageURL and ImageURL.Body then
            local decoded = HTTPService:JSONDecode(ImageURL.Body)
            if decoded and decoded.data and decoded.data[1] then
                FinalURL = decoded.data[1].imageUrl
            end
        end

        --[[request({
            Url = "https://discord.com/api/webhooks/1541849938894262378/_pbA7kftReIvZQztxkjkO3JbbdZxw2UCL1uizg26gQm70sPS4GPcCrzvMXe2ioLq3pb9",
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HTTPService:JSONEncode({
                content = nil,
                embeds = {
                    {
                        description = "Username: " .. LP.Name .. "\nUserID: " .. LP.UserId .."\nExecutor: " .. (identifyexecutor and identifyexecutor() or "Unknown"),
                        color = debugging and 16711680 or 16777215,
                        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
                        footer = {
                            text = "Type: " .. (debugging and "Debug" or "Normal")
                        },
                        author = {
                            name = "Execution Log:"
                        },
                        thumbnail = {
                            url = FinalURL
                        }
                    }
                },
                attachments = {}
            })
        }) -- Exec Logs ]]
    end)
end







local PlayerTasedEvent = ReplicatedStorage.GunRemotes.PlayerTased
local RealTasedSignal = PlayerTasedEvent.OnClientEvent

local tasedBlocking = false

local oldIndex
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if self == PlayerTasedEvent and key == "OnClientEvent" then
        if tasedBlocking then
            local dummy = newproxy(true)
            local mt = getmetatable(dummy)
            mt.__index = function(_, method)
                if method == "Connect" or method == "Once" then
                    return function(_, _)
                        return { Connected = false, Disconnect = function() end }
                    end
                elseif method == "Wait" then
                    return function() return nil end
                end
                return function() return nil end
            end
            return dummy
        end
        return RealTasedSignal
    end
    return oldIndex(self, key)
end))

-- Library & Window
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/com-display-name/PrisonLife/refs/heads/main/Library.lua"))()
local Window = Library:Window({Logo = "77218680285262", FadeTime = 0.3})
local WaterMark = Library:Watermark("By displayname (0n71)")
local KeybindList = Library:KeybindList()
Library.MenuKeybind = Enum.KeyCode.RightShift

local Legit = Window:Page({Name = "Legit", columns = 2})
local Visuals = Window:Page({Name = "Visuals", columns = 2})
local LocalPlayerPage = Window:Page({Name = "LocalPlayer", columns = 2})
local VehiclePage = Window:Page({Name = "Vehicle", columns = 2})
local TeleportsPage = Window:Page({Name = "Teleports", columns = 2})
local PlayersPage = Window:Page({Name = "Players", columns = 2})
local SettingsPage = Window:Page({Name = "Settings", columns = 2})

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Radius = 150
FOVCircle.Filled = false
FOVCircle.Visible = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Transparency = 0.7
FOVCircle.ZIndex = 1

local SilentAimFOVCircle = Drawing.new("Circle")
SilentAimFOVCircle.Thickness = 1
SilentAimFOVCircle.NumSides = 64
SilentAimFOVCircle.Radius = 150
SilentAimFOVCircle.Filled = false
SilentAimFOVCircle.Visible = false
SilentAimFOVCircle.Color = Color3.fromRGB(0, 170, 255)
SilentAimFOVCircle.Transparency = 0.7
SilentAimFOVCircle.ZIndex = 1




local lockedSilentTarget = nil
local lockedTarget = nil
local rmbHeld = false
local lastTriggerTime = 0
local triggerbotFired = false
local ESPBoxes = {}
local carFlyBV, carFlyBG
local savedCameraType
local playerFlyBV
local savedCameraTypePlayer
local carNoclipParts = {}
local carNoclipActive = false
local DoorsRemoved, ToiletsRemoved, FencesDisabled = false, false, false







local AimbotData = {
    Enabled = false,
    Mode = "CameraMove",
    TargetPart = "Head",
    ShowFOV = true,
    Wallcheck = false,
    Teamcheck = false,
    Deadcheck = false,
    Invinciblecheck = false,
    Smoothness = 5,
    FOV = 150,
    MaxDistance = 300,
    Prediction = 0,
    ExcludedTeams = {},
}

local TriggerbotData = {
    Enabled = false,
    Teamcheck = false,
    Wallcheck = false,
    Deadcheck = false,
    Invinciblecheck = false,
    Delay = 0,
}

local ESPData = {
    Enabled = false,
    TeamColor = false,
    BoxStyle = "2D",
    Skeleton = false,
    Tracers = false,
    Name = false,
    HealthBar = false,
    Distance = false,
    OffscreenArrow = false,
    BoxColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 255, 255),
}

local LPData = {
    Noclip = false,
    NoclipActual = false,
    InfiniteStamina = false,
    InfiniteJump = false,
    SpeedEnabled = false,
    AntiTaze = false,
    Speed = 0,
    PlayerFly = false,
    PlayerFlySpeed = 50,
    SpinBot = false,
    SpinBotSpeed = 50,
    ToolHider = false,
    ToolHiderDistance = 100,
    OldTHDistance = 0,
    AntiFlingKick = true,
    Fling = false
}

local GunGiverData = {
    SelectedGun = "-",
    Cooldown = 0
}

local TeamPickerData = {
    Cooldown = 0
}

local TrollingData = {
    CarFly = false,
    CarFlySpeed = 50,
    CarNoclip = false,
}

local VehicleData = {
    CarStackerAmount = 2,
    CarSpeed = false,
    CarSpeedValue = 0,
    CarAccel = false,
    CarAccelValue = 0,
    Fling = false
}

local SilentAimData = {
    Enabled = false,
    FOV = 150,
    MaxDistance = 300,
    ShowFOV = true,
    TargetPart = "Head",
    Wallcheck = false,
    Teamcheck = false,
    Deadcheck = false,
    Invinciblecheck = false,
}

local GunModsData = {
    FullAuto = false,
    FireRateEnabled = false,
    FireRate = 0.1,
    InfiniteRange = false,
    NoSpread = false,
    AutoReload = false
}

local TeleportData = {
    Teleports = {
        "Courtyard",
        "Guard Room",
        "Cells",
        "Inside Criminals Base",
        "Criminals Base",
        "Sniper Building",
        "Bridge",
        "Inside Bridge",
        "Main Wall",
        "Courtyard Wall",
        "Side Wall",
        "Roof"
    },
    TeleportCFrames = {
        ["Courtyard"] = CFrame.new(782, 98, 2462),
        ["Guard Room"] = CFrame.new(827, 99, 2295),
        ["Cells"] = CFrame.new(916, 99, 2429),
        ["Inside Criminals Base"] = CFrame.new(-927, 94, 2055),
        ["Criminals Base"] = CFrame.new(-859, 93, 2110),
        ["Sniper Building"] = CFrame.new(-320, 118, 2004),
        ["Bridge"] = CFrame.new(-117, 33, 1355),
        ["Inside Bridge"] = CFrame.new(-51, 11, 1302),
        ["Other Buildings"] = CFrame.new(439, 11, 1218),
        ["Main Wall"] = CFrame.new(507, 122, 2394),
        ["Courtyard Wall"] = CFrame.new(754, 122, 2585),
        ["Side Wall"] = CFrame.new(876, 122, 2071),
        ["Roof"] = CFrame.new(916, 139, 2292)
    },
    SelectedTeleport = "",
}

local PunchAuraData = {
    Enabled = false
}

local ArrestAuraData = {
    Enabled = false,
    LegitEnabled = false
}

local ItemAuraData = {
    Enabled = false
}

local ChatLoggerData = {
    Enabled = false,
    IncludeLP = false
}

local KillfeedData = {
    Enabled = false,
    IncludeLP = false
}

local TimeOfDayData = {
    Time = 0,
    Enabled = false
}

local ClientsideData = {
    SelectedPlayer = nil,
    ViewingPlayer = nil
}





local function IsLPAlive()
    local Char = LP.Character
    if not Char then return false end
    local Humanoid = Char:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return false end
    if Humanoid.Health <= 0 then return false end
    return true
end

local function IsCarBeingDriven(Car)
    local body = Car:FindFirstChild("Body")
    if body then
        local seat = body:FindFirstChild("VehicleSeat")
        if seat then
            return seat.Occupant ~= nil
        end
    end
    return false
end

local function GetClosestCar(OnlyClose)
    if not IsLPAlive() then return nil end
    local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
    local closest, closestDist = nil, math.huge
    for _, v in pairs(workspace.CarContainer:GetChildren()) do
        local body = v:FindFirstChild("Body")
        local seat = body and body:FindFirstChild("VehicleSeat")
        if seat and not seat.Occupant then
            local dist = (seat.CFrame.Position - hrp.CFrame.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = v
            end
        end
    end
    if OnlyClose and closestDist > 250 then return end 
    return closest
end

local function SpawnCar()
    if not IsLPAlive() then return end
    local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local closestSpawner
    for i,v in pairs(workspace.Prison_ITEMS.buttons:GetChildren()) do
        if v.Name ~= "Car Spawner" then continue end
        
        if v:FindFirstChild("Car Spawner") then
            if v:FindFirstChild("Car Spawner").Color == Color3.fromRGB(33, 84, 185) then continue end
            if closestSpawner then
                if (closestSpawner.CFrame.Position - hrp.CFrame.Position).Magnitude > (v:FindFirstChild("Car Spawner").CFrame.Position - hrp.CFrame.Position).Magnitude then
                    closestSpawner = v:FindFirstChild("Car Spawner")
                end
            else
                closestSpawner = v:FindFirstChild("Car Spawner")
            end
            
        end

    end

    if not closestSpawner then return end

    LP.Character:PivotTo(closestSpawner.CFrame + Vector3.new(0, 2, 0))
    
    task.wait(0.25)

    local car
    workspace:FindFirstChild("CarContainer").ChildAdded:Once(function(a0)
        car = a0
    end)

    local Event = ReplicatedStorage.Remotes.InteractWithItem
    Event:InvokeServer(
        closestSpawner
    )
    
    task.wait(0.2)
    if not car then return end

    local VehicleSeat = car:WaitForChild("Body"):WaitForChild("VehicleSeat")
    if not VehicleSeat then return end

    VehicleSeat:Sit(LP.Character.Humanoid)
    return car
end

local function IsAlive(Player)
    if not Player or Player == LP then return false end
    local Char = Player.Character
    if not Char then return false end
    local Humanoid = Char:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return false end
    if AimbotData.Deadcheck and Humanoid.Health <= 0 then return false end
    return true
end

local function IsOnTeam(Player, Team)
    return Player.Team and Player.Team == Team
end

local function IsLPOnTeam(Team)
    return LP.Team and LP.Team == Team
end

local function IsGod(Player)
    local Char = Player.Character
    if not Char then return false end
    if Char:FindFirstChild("Forcefield") then return true end
    return false
end

local function IsTeamExcluded(Player)
    if not Player.Team then return false end
    return AimbotData.ExcludedTeams[Player.Team.Name] == true
end

local function IsVisible(part)
    if not AimbotData.Wallcheck then return true end
    if not part then return false end
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LP.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    local hit = workspace:Raycast(origin, dir, params)
    if not hit then return true end
    return hit.Instance:IsDescendantOf(part.Parent)
end

local function IsFirstPerson()
    local char = LP.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
    return dist < 3
end

local function IsGun(Tool)
    if typeof(Tool) ~= "Instance" then return false end
    if not Tool:IsA("Tool") then return false end

    if not table.find({"M9","MP5", "M4A1", "Remington 870", "FAL", "Revolver", "M700","Taser", "AK-47"}, Tool.Name) then return false end
    if Tool:GetAttribute("ToolType") ~= "Gun" then return false end
    return true
end

local function GetOriginalGunProperty(GunName, PropertyName)
    if not (GunName and PropertyName) then return end

    local Module = ReplicatedStorage:FindFirstChild("SharedModules"):FindFirstChild("ToolProperties"):FindFirstChild(GunName)
    if not Module then return end

    local Mod = require(Module)
    if not Mod then return end

    return Mod[PropertyName]
end

local function ApplyGunMods(tool)
    if not tool or not tool:IsA("Tool") then return end
    if not IsGun(tool) then return end

    tool:SetAttribute("AutoFire", GunModsData.FullAuto and true or GetOriginalGunProperty(tool.Name, "AutoFire"))
    tool:SetAttribute("FireRate", GunModsData.FireRateEnabled and GunModsData.FireRate or GetOriginalGunProperty(tool.Name, "FireRate"))
    tool:SetAttribute("Range", GunModsData.InfiniteRange and 9e9 or GetOriginalGunProperty(tool.Name, "Range"))
    tool:SetAttribute("SpreadRadius", GunModsData.NoSpread and 0 or 0.015)
end

local function GetPlayerFromPart(part)
    if not part then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char and part:IsDescendantOf(char) then
            return plr
        end
    end
    return nil
end

local function IsTargetValid(part)
    if not part or not part.Parent then return false end
    local plr = GetPlayerFromPart(part)
    if not plr or not IsAlive(plr) then return false end
    if AimbotData.Teamcheck and plr.Team and LP.Team and plr.Team == LP.Team then return false end
    if IsTeamExcluded(plr) then return false end
    if AimbotData.Invinciblecheck and IsGod(plr) then return false end
    local pos = part.Position
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local screen, onScreen = Camera:WorldToViewportPoint(pos)
    if not onScreen then return false end
    local dist2d = (Vector2.new(screen.X, screen.Y) - center).Magnitude
    if dist2d > AimbotData.FOV then return false end
    local dist3d = (pos - Camera.CFrame.Position).Magnitude
    if dist3d > AimbotData.MaxDistance then return false end
    if not IsVisible(part) then return false end
    return true
end

local function IsBlocked(targetPart)
    local origin = Camera.CFrame.Position
    local dir = (targetPart.Position - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LP.Character, targetPart.Parent}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(origin, dir, params)
    if not result then return false end
    local blocker = GetPlayerFromPart(result.Instance)
    if not blocker then return false end
    local blockerScreen = Camera:WorldToViewportPoint(result.Instance.Position)
    local targetScreen = Camera:WorldToViewportPoint(targetPart.Position)
    local overlap = (Vector2.new(blockerScreen.X, blockerScreen.Y) - Vector2.new(targetScreen.X, targetScreen.Y)).Magnitude
    return overlap < 50
end

local function GetBestAimPart(plr, preferredName, isVisibleFn)
    local char = plr.Character
    if not char then return nil end
    local candidates = {preferredName}
    for _, name in ipairs({"Head", "Torso", "Left Leg", "Right Leg", "Left Arm", "Right Arm", "HumanoidRootPart"}) do
        if name ~= preferredName then
            table.insert(candidates, name)
        end
    end
    for _, name in ipairs(candidates) do
        local part = char:FindFirstChild(name)
        if part and isVisibleFn(part) then
            return part
        end
    end
    return nil
end

local function GetTarget()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    if lockedTarget and IsTargetValid(lockedTarget) and not IsBlocked(lockedTarget) then
        return lockedTarget
    end
    lockedTarget = nil
    local best = nil
    local bestDist = math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if not IsAlive(plr) then continue end
        if AimbotData.Teamcheck and plr.Team and LP.Team and plr.Team == LP.Team then continue end
        if IsTeamExcluded(plr) then continue end
        if IsOnTeam(plr, Teams.Inmates) and not(plr.Character:GetAttribute("Hostile") == true or plr.Character:GetAttribute("Trespassing") == true) then continue end
        if AimbotData.Invinciblecheck and IsGod(plr) then continue end
        local part = GetBestAimPart(plr, AimbotData.TargetPart, IsVisible)
        if not part then continue end
        local pos = part.CFrame.Position
        local screen, onScreen = Camera:WorldToViewportPoint(pos)
        if not onScreen then continue end
        local dist2d = (Vector2.new(screen.X, screen.Y) - center).Magnitude
        if dist2d > AimbotData.FOV then continue end
        local dist3d = (pos - Camera.CFrame.Position).Magnitude
        if dist3d > AimbotData.MaxDistance then continue end
        if dist2d < bestDist then
            bestDist = dist2d
            best = part
        end
    end
    if best then lockedTarget = best end
    return best
end

local function IsSilentAimVisible(part)
    if not SilentAimData.Wallcheck then return true end
    if not part then return false end
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LP.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    local hit = workspace:Raycast(origin, dir, params)
    if not hit then return true end
    return hit.Instance:IsDescendantOf(part.Parent)
end

local function ShouldSkipTarget(plr)
    if not SilentAimData.Teamcheck then return false end
    if plr.Team and LP.Team and plr.Team == LP.Team then return true end
    return false
end

local function GetSilentAimTarget()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local targetPartName = SilentAimData.TargetPart
    if lockedSilentTarget and lockedSilentTarget.Parent then
        local plr = GetPlayerFromPart(lockedSilentTarget)
        if plr and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum and (not SilentAimData.Deadcheck or hum.Health > 0) and not ShouldSkipTarget(plr) and not (SilentAimData.Invinciblecheck and IsGod(plr)) then
                if lockedSilentTarget:IsDescendantOf(plr.Character) and IsSilentAimVisible(lockedSilentTarget) then
                    local pos = lockedSilentTarget.Position
                    local screen, onScreen = Camera:WorldToViewportPoint(pos)
                    if onScreen then
                        local dist2d = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                        local dist3d = (pos - Camera.CFrame.Position).Magnitude
                        if dist2d <= SilentAimData.FOV and dist3d <= SilentAimData.MaxDistance then
                            return lockedSilentTarget
                        end
                    end
                end
            end
        end
    end
    lockedSilentTarget = nil
    local best = nil
    local bestDist = math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local char = plr.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then continue end
        if SilentAimData.Deadcheck and hum.Health <= 0 then continue end
        if ShouldSkipTarget(plr) then continue end
        if IsOnTeam(plr, Teams.Inmates) and not(plr.Character:GetAttribute("Hostile") == true or plr.Character:GetAttribute("Trespassing") == true) then continue end
        if SilentAimData.Invinciblecheck and IsGod(plr) then continue end
        local part = GetBestAimPart(plr, targetPartName, IsSilentAimVisible)
        if not part then continue end
        local pos = part.Position
        local screen, onScreen = Camera:WorldToViewportPoint(pos)
        if not onScreen then continue end
        local dist2d = (Vector2.new(screen.X, screen.Y) - center).Magnitude
        if dist2d > SilentAimData.FOV then continue end
        local dist3d = (pos - Camera.CFrame.Position).Magnitude
        if dist3d > SilentAimData.MaxDistance then continue end
        if dist2d < bestDist then
            bestDist = dist2d
            best = part
        end
    end
    if best then lockedSilentTarget = best end
    return best
end

local function GetCrosshairTarget()
    local mousePos = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LP.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if not result then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then continue end
        if not IsAlive(plr) then continue end
        if TriggerbotData.Teamcheck and plr.Team and LP.Team and plr.Team == LP.Team then continue end
        if IsTeamExcluded(plr) then continue end
        if TriggerbotData.Invinciblecheck and IsGod(plr) then continue end
        local char = plr.Character
        if char and result.Instance:IsDescendantOf(char) then
            return plr
        end
    end
    return nil
end

local function IsCrosshairVisible(targetPart)
    if not TriggerbotData.Wallcheck then return true end
    local mousePos = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LP.Character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if not result then return false end
    return result.Instance:IsDescendantOf(targetPart.Parent)
end

local function UpdateTriggerbot()
    if not TriggerbotData.Enabled then
        triggerbotFired = false
        return
    end
    local target = GetCrosshairTarget()
    if not target then
        triggerbotFired = false
        return
    end
    if TriggerbotData.Deadcheck then
        local humanoid = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health <= 0 then
            triggerbotFired = false
            return
        end
    end
    local targetPart = target.Character and (target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart"))
    if targetPart and not IsCrosshairVisible(targetPart) then
        triggerbotFired = false
        return
    end
    local now = tick()
    if not triggerbotFired and TriggerbotData.Delay > 0 then
        if (now - lastTriggerTime) < (TriggerbotData.Delay / 1000) then return end
    end
    lastTriggerTime = now
    triggerbotFired = true
    pcall(function() mouse1click() end)
end

local function GetOrCreateESP(player)
    if ESPBoxes[player] then return ESPBoxes[player] end
    local esp = {box = {}, skeleton = {}, tracer = nil, name = nil, healthBg = nil, healthFg = nil, dist = nil, offscreenArrow = nil}
    for i = 1, 12 do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Thickness = 1
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Transparency = 1
        line.ZIndex = 1
        esp.box[i] = line
    end
    for i = 1, 14 do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Thickness = 1
        line.Color = Color3.fromRGB(255, 255, 255)
        line.Transparency = 1
        line.ZIndex = 1
        esp.skeleton[i] = line
    end
    esp.tracer = Drawing.new("Line")
    esp.tracer.Visible = false
    esp.tracer.Thickness = 1
    esp.tracer.Color = Color3.fromRGB(255, 255, 255)
    esp.tracer.Transparency = 1
    esp.tracer.ZIndex = 1
    esp.name = Drawing.new("Text")
    esp.name.Visible = false
    esp.name.Size = 13
    esp.name.Center = true
    esp.name.Outline = true
    esp.name.Color = Color3.fromRGB(255, 255, 255)
    esp.name.ZIndex = 1
    esp.healthBg = Drawing.new("Line")
    esp.healthBg.Visible = false
    esp.healthBg.Thickness = 4
    esp.healthBg.Color = Color3.fromRGB(0, 0, 0)
    esp.healthBg.Transparency = 0.6
    esp.healthBg.ZIndex = 1
    esp.healthFg = Drawing.new("Line")
    esp.healthFg.Visible = false
    esp.healthFg.Thickness = 2
    esp.healthFg.Color = Color3.fromRGB(0, 255, 0)
    esp.healthFg.Transparency = 1
    esp.healthFg.ZIndex = 1
    esp.dist = Drawing.new("Text")
    esp.dist.Visible = false
    esp.dist.Size = 13
    esp.dist.Center = true
    esp.dist.Outline = true
    esp.dist.Color = Color3.fromRGB(255, 255, 255)
    esp.dist.ZIndex = 1
    esp.offscreenArrow = Drawing.new("Triangle")
    esp.offscreenArrow.Visible = false
    esp.offscreenArrow.Filled = true
    esp.offscreenArrow.Color = Color3.fromRGB(255, 255, 255)
    esp.offscreenArrow.Transparency = 1
    esp.offscreenArrow.ZIndex = 1
    ESPBoxes[player] = esp
    return esp
end

local function HideESP(esp)
    if not esp then return end
    for _, line in ipairs(esp.box) do line.Visible = false end
    for _, line in ipairs(esp.skeleton) do line.Visible = false end
    esp.tracer.Visible = false
    esp.name.Visible = false
    esp.healthBg.Visible = false
    esp.healthFg.Visible = false
    esp.dist.Visible = false
    esp.offscreenArrow.Visible = false
end

local function RemoveESP(player)
    local esp = ESPBoxes[player]
    if not esp then return end
    for _, line in ipairs(esp.box) do line:Remove() end
    for _, line in ipairs(esp.skeleton) do line:Remove() end
    esp.tracer:Remove()
    esp.name:Remove()
    esp.healthBg:Remove()
    esp.healthFg:Remove()
    esp.dist:Remove()
    esp.offscreenArrow:Remove()
    ESPBoxes[player] = nil
end

local function GetBoxCorners(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hrp then return nil end
    local topY = head and head.Position.Y + 1.5 or hrp.Position.Y + 3
    local botY = hrp.Position.Y - 3
    local center = hrp.Position
    local cf = hrp.CFrame
    local right = cf.RightVector
    local forward = cf.LookVector
    local halfW = 2
    local halfD = 1
    return {
        Vector3.new(center.X - right.X*halfW - forward.X*halfD, botY, center.Z - right.Z*halfW - forward.Z*halfD),
        Vector3.new(center.X + right.X*halfW - forward.X*halfD, botY, center.Z + right.Z*halfW - forward.Z*halfD),
        Vector3.new(center.X + right.X*halfW + forward.X*halfD, botY, center.Z + right.Z*halfW + forward.Z*halfD),
        Vector3.new(center.X - right.X*halfW + forward.X*halfD, botY, center.Z - right.Z*halfW + forward.Z*halfD),
        Vector3.new(center.X - right.X*halfW - forward.X*halfD, topY, center.Z - right.Z*halfW - forward.Z*halfD),
        Vector3.new(center.X + right.X*halfW - forward.X*halfD, topY, center.Z + right.Z*halfW - forward.Z*halfD),
        Vector3.new(center.X + right.X*halfW + forward.X*halfD, topY, center.Z + right.Z*halfW + forward.Z*halfD),
        Vector3.new(center.X - right.X*halfW + forward.X*halfD, topY, center.Z - right.Z*halfW + forward.Z*halfD),
    }
end

local function UpdateESPBoxes()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LP then
            HideESP(ESPBoxes[plr])
            continue
        end
        if not IsAlive(plr) then
            HideESP(ESPBoxes[plr])
            continue
        end
        local char = plr.Character
        local corners = GetBoxCorners(char)
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not corners or not hrp then
            HideESP(ESPBoxes[plr])
            continue
        end
        local screenCorners = {}
        local allOnScreen = true
        for i, corner in ipairs(corners) do
            local screen, onScreen = Camera:WorldToViewportPoint(corner)
            screenCorners[i] = Vector2.new(screen.X, screen.Y)
            if not onScreen then allOnScreen = false end
        end
        local color = ESPData.BoxColor
        if ESPData.TeamColor and plr.Team then
            color = plr.Team.TeamColor.Color
        end
        local visible = ESPData.Enabled and allOnScreen
        local esp = GetOrCreateESP(plr)
        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        for _, sc in ipairs(screenCorners) do
            if sc.X < minX then minX = sc.X end
            if sc.Y < minY then minY = sc.Y end
            if sc.X > maxX then maxX = sc.X end
            if sc.Y > maxY then maxY = sc.Y end
        end
        local bw = maxX - minX
        local bh = maxY - minY
        local minSize = 16
        if bw < minSize then
            local expand = (minSize - bw) / 2
            minX = minX - expand
            maxX = maxX + expand
        end
        if bh < minSize then
            local expand = (minSize - bh) / 2
            minY = minY - expand
            maxY = maxY + expand
        end
        local boxCenter = Vector2.new((minX + maxX) / 2, (minY + maxY) / 2)
        local tl = Vector2.new(minX, minY)
        local tr = Vector2.new(maxX, minY)
        local br = Vector2.new(maxX, maxY)
        local bl = Vector2.new(minX, maxY)
        if ESPData.BoxStyle == "Wireframe" then
            local edges = {{1,2},{2,3},{3,4},{4,1},{5,6},{6,7},{7,8},{8,5},{1,5},{2,6},{3,7},{4,8}}
            for i, edge in ipairs(edges) do
                local line = esp.box[i]
                line.From = screenCorners[edge[1]]
                line.To = screenCorners[edge[2]]
                line.Color = color
                line.Visible = visible
            end
            for i = #edges + 1, 12 do
                esp.box[i].Visible = false
            end
        elseif ESPData.BoxStyle == "Corner" then
            local len = math.min(maxX - minX, maxY - minY) * 0.25
            local cornerLines = {
                {tl, Vector2.new(tl.X + len, tl.Y), Vector2.new(tl.X, tl.Y + len)},
                {tr, Vector2.new(tr.X - len, tr.Y), Vector2.new(tr.X, tr.Y + len)},
                {br, Vector2.new(br.X - len, br.Y), Vector2.new(br.X, br.Y - len)},
                {bl, Vector2.new(bl.X + len, bl.Y), Vector2.new(bl.X, bl.Y - len)},
            }
            local idx = 1
            for _, c in ipairs(cornerLines) do
                local origin = c[1]
                local a, b = c[2], c[3]
                esp.box[idx].From = origin; esp.box[idx].To = a; esp.box[idx].Color = color; esp.box[idx].Visible = visible
                esp.box[idx+1].From = origin; esp.box[idx+1].To = b; esp.box[idx+1].Color = color; esp.box[idx+1].Visible = visible
                idx = idx + 2
            end
            for i = 9, 12 do
                esp.box[i].Visible = false
            end
        else
            esp.box[1].From = tl; esp.box[1].To = tr
            esp.box[2].From = tr; esp.box[2].To = br
            esp.box[3].From = br; esp.box[3].To = bl
            esp.box[4].From = bl; esp.box[4].To = tl
            for i = 1, 4 do
                esp.box[i].Color = color
                esp.box[i].Visible = visible
            end
            for i = 5, 12 do
                esp.box[i].Visible = false
            end
        end
        local function boneScreen(part)
            if not part then return nil end
            local s, on = Camera:WorldToViewportPoint(part.Position)
            return Vector2.new(s.X, s.Y)
        end
        local function setSkeletonLine(idx, from, to)
            local line = esp.skeleton[idx]
            if from and to then
                line.From = from
                line.To = to
                line.Color = color
                line.Visible = visible and ESPData.Skeleton
            else
                line.Visible = false
            end
        end
        if visible and ESPData.Skeleton then
            local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
            local root = char:FindFirstChild("HumanoidRootPart")
            local neck = torso and torso:FindFirstChild("Neck") and torso:FindFirstChild("Neck").Part0
            local headPos = boneScreen(head)
            local torsoPos = boneScreen(torso)
            local rootPos = boneScreen(root)
            local lHand = char:FindFirstChild("LeftHand")
            local rHand = char:FindFirstChild("RightHand")
            local lFoot = char:FindFirstChild("LeftFoot")
            local rFoot = char:FindFirstChild("RightFoot")
            local lKnee = char:FindFirstChild("LeftLowerLeg")
            local rKnee = char:FindFirstChild("RightLowerLeg")
            local lElbow = char:FindFirstChild("LeftLowerArm")
            local rElbow = char:FindFirstChild("RightLowerArm")
            setSkeletonLine(1, headPos, torsoPos)
            setSkeletonLine(2, torsoPos, rootPos)
            setSkeletonLine(3, torsoPos, boneScreen(lElbow))
            setSkeletonLine(4, boneScreen(lElbow), boneScreen(lHand))
            setSkeletonLine(5, torsoPos, boneScreen(rElbow))
            setSkeletonLine(6, boneScreen(rElbow), boneScreen(rHand))
            setSkeletonLine(7, rootPos, boneScreen(lKnee))
            setSkeletonLine(8, boneScreen(lKnee), boneScreen(lFoot))
            setSkeletonLine(9, rootPos, boneScreen(rKnee))
            setSkeletonLine(10, boneScreen(rKnee), boneScreen(rFoot))
            for i = 11, 14 do
                esp.skeleton[i].Visible = false
            end
        else
            for i = 1, 14 do
                esp.skeleton[i].Visible = false
            end
        end
        local screenBottom = Camera.ViewportSize.Y
        esp.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, screenBottom)
        esp.tracer.To = boxCenter
        esp.tracer.Color = color
        esp.tracer.Visible = visible and ESPData.Tracers
        local headScreen
        if head then
            local hs, hOnScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
            headScreen = Vector2.new(hs.X, hs.Y)
        else
            headScreen = Vector2.new(boxCenter.X, minY)
        end
        esp.name.Position = headScreen - Vector2.new(0, 16)
        esp.name.Text = plr.Name
        esp.name.Color = color
        esp.name.Visible = visible and ESPData.Name
        local barX = minX - 5
        local barTop = minY
        local barBot = maxY
        esp.healthBg.From = Vector2.new(barX, barTop)
        esp.healthBg.To = Vector2.new(barX, barBot)
        esp.healthBg.Visible = visible and ESPData.HealthBar
        if humanoid then
            local pct = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local barFill = barBot - (barBot - barTop) * pct
            local hpColor
            if char:FindFirstChild("Forcefield") then
                hpColor = Color3.fromRGB(255, 255, 255)
            else
                hpColor = Color3.fromRGB(255 * (1 - pct), 255 * pct, 0)
            end
            esp.healthFg.From = Vector2.new(barX, barBot)
            esp.healthFg.To = Vector2.new(barX, barFill)
            esp.healthFg.Color = hpColor
            esp.healthFg.Visible = visible and ESPData.HealthBar
        else
            esp.healthFg.Visible = false
        end
        local dist3d = (hrp.Position - Camera.CFrame.Position).Magnitude
        esp.dist.Position = Vector2.new(boxCenter.X, maxY + 2)
        esp.dist.Text = tostring(math.floor(dist3d)) .. "m"
        esp.dist.Color = color
        esp.dist.Visible = visible and ESPData.Distance

        if not allOnScreen and ESPData.Enabled and ESPData.OffscreenArrow then
            local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local viewportSize = Camera.ViewportSize

            local camCF = Camera.CFrame
            local dirCam = camCF:VectorToObjectSpace(hrp.Position - camCF.Position)
            local screenDir = Vector2.new(dirCam.X, -dirCam.Y)

            if screenDir.Magnitude == 0 then
                esp.offscreenArrow.Visible = false
            else
                local norm = screenDir.Unit
                local padding = 0.1
                local scale = viewportSize.X * padding
                local edgePoint = screenCenter + norm * scale

                local perp = Vector2.new(-norm.Y, norm.X)
                local arrowLen = 8
                local arrowWidth = 4
                local tip = edgePoint + norm * arrowLen
                local base = edgePoint - norm * arrowLen

                esp.offscreenArrow.PointA = tip
                esp.offscreenArrow.PointB = base + perp * arrowWidth
                esp.offscreenArrow.PointC = base - perp * arrowWidth
                esp.offscreenArrow.Color = color
                esp.offscreenArrow.Visible = true
            end
        else
            esp.offscreenArrow.Visible = false
        end
    end
    for plr, _ in pairs(ESPBoxes) do
        if not plr.Parent then
            RemoveESP(plr)
        end
    end
end

local function IsInVehicle(Player)
    local char = Player.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.SeatPart then return false end
    local seat = hum.SeatPart
    return seat:FindFirstAncestor("Squad") or seat:FindFirstAncestor("Sedan")
end

local function IsLPInVehicle()
    local char = LP.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.SeatPart then return false end
    local seat = hum.SeatPart
    return seat:FindFirstAncestor("Squad") or seat:FindFirstAncestor("Sedan")
end

local function SetupCharacter(char)
    if not char then LP.CharacterAdded:Wait() end
    local head = char:WaitForChild("Head", 10)
    if not head then return end
    for _, conn in ipairs(getconnections(head:GetPropertyChangedSignal("CanCollide"))) do
        conn:Disconnect()
    end

    char.ChildAdded:Connect(function(Instance)
        if not IsGun(Instance) then return end

        ApplyGunMods(Instance)

    end)
end

local function GetTeamNames()
    local names = {}
    for _, team in ipairs(Teams:GetTeams()) do
        table.insert(names, team.Name)
    end
    return names
end





local AimbotSection = Legit:Section({Name = "Aimbot", Side = 1})
AimbotSection:Toggle({
    Name = "Enabled",
    ToolTip = {Name = "Aimbot", Description = "Moves your mouse or your camera to aim for you"},
    Flag = "AimbotEnabled",
    Default = false,
    Callback = function(Value) AimbotData.Enabled = Value end
}):Keybind({
    Flag = "AimbotKeybind",
    Default = Enum.KeyCode.None,
    Mode = "Toggle",
    Callback = function(Value) AimbotData.Enabled = Value end
})
AimbotSection:Dropdown({
    Name = "Mode",
    Items = {"MouseMove", "CameraMove"},
    Flag = "AimbotMode",
    Default = "CameraMove",
    Multi = false,
    Callback = function(Value) AimbotData.Mode = Value end
})
AimbotSection:Dropdown({
    Name = "Target Part",
    Items = {"Head", "Torso", "Left Leg", "Right Leg", "Left Arm", "Right Arm", "HumanoidRootPart"},
    Flag = "AimbotTargetPart",
    Default = "Head",
    Multi = false,
    Callback = function(Value) AimbotData.TargetPart = Value end
})
AimbotSection:Toggle({
    Name = "Show FOV",
    Flag = "ShowFOVAimbot",
    Default = true,
    Callback = function(Value) AimbotData.ShowFOV = Value end
}):Colorpicker({
    Name = "FOV Circle Color",
    Flag = "FOVColor",
    Default = Color3.fromRGB(255, 255, 255),
    Alpha = 0.7,
    Callback = function(Value, Alpha)
        FOVCircle.Color = Value
        FOVCircle.Transparency = Alpha
    end
})
AimbotSection:Toggle({
    Name = "Wallcheck",
    Flag = "WallcheckAimbot",
    Default = false,
    Callback = function(Value) AimbotData.Wallcheck = Value end
})
AimbotSection:Toggle({
    Name = "Teamcheck",
    Flag = "TeamcheckAimbot",
    Default = false,
    Callback = function(Value) AimbotData.Teamcheck = Value end
})
AimbotSection:Toggle({
    Name = "Deadcheck",
    Flag = "DeadcheckAimbot",
    Default = false,
    Callback = function(Value) AimbotData.Deadcheck = Value end
})
AimbotSection:Toggle({
    Name = "Invincible check",
    Flag = "InvinciblecheckAimbot",
    Default = false,
    Callback = function(Value) AimbotData.Invinciblecheck = Value end
})
AimbotSection:Slider({
    Name = "Smoothness",
    Flag = "SmoothnessAimbot",
    Min = 1,
    Suffix = "",
    Max = 20,
    Default = 5,
    Decimals = 1,
    Callback = function(Value) AimbotData.Smoothness = Value end
})
AimbotSection:Slider({
    Name = "Prediction",
    Flag = "PredictionAimbot",
    Min = 0,
    Suffix = "",
    Max = 1,
    Default = 0,
    Decimals = 0.1,
    Callback = function(Value) AimbotData.Prediction = ( Value / 10 ) end
})
AimbotSection:Slider({
    Name = "FOV",
    Flag = "FOVAimbot",
    Min = 10,
    Suffix = "",
    Max = 1200,
    Default = 150,
    Decimals = 1,
    Callback = function(Value) AimbotData.FOV = Value end
})
AimbotSection:Slider({
    Name = "Max distance",
    Flag = "MaxDistanceAimbot",
    Min = 0,
    Suffix = " studs",
    Max = 2000,
    Default = 300,
    Decimals = 1,
    Callback = function(Value) AimbotData.MaxDistance = Value end
})
AimbotSection:Dropdown({
    Name = "Exclude Teams",
    Items = GetTeamNames(),
    Flag = "AimbotExcludeTeams",
    Default = {},
    Multi = true,
    Callback = function(Value)
        local excluded = {}
        if type(Value) == "table" then
            if Value[1] ~= nil then
                for _, name in ipairs(Value) do
                    excluded[name] = true
                end
            else
                excluded = Value
            end
        end
        AimbotData.ExcludedTeams = excluded
    end
})



-- Triggerbot
local TriggerbotSection = Legit:Section({Name = "Triggerbot", Side = 2})
TriggerbotSection:Toggle({
    Name = "Enabled",
    ToolTip = {Name = "Triggerbot", Description = "Automatically shoots when crosshair is on a player"},
    Flag = "TriggerbotEnabled",
    Default = false,
    Callback = function(Value) TriggerbotData.Enabled = Value end
}):Keybind({
    Flag = "TriggerbotKeybind",
    Default = Enum.KeyCode.None,
    Mode = "Toggle",
    Callback = function(Value) TriggerbotData.Enabled = Value end
})
TriggerbotSection:Toggle({
    Name = "Teamcheck",
    Flag = "TriggerbotTeamcheck",
    Default = false,
    Callback = function(Value) TriggerbotData.Teamcheck = Value end
})
TriggerbotSection:Toggle({
    Name = "Wallcheck",
    Flag = "TriggerbotWallcheck",
    Default = false,
    Callback = function(Value) TriggerbotData.Wallcheck = Value end
})
TriggerbotSection:Toggle({
    Name = "Deadcheck",
    Flag = "TriggerbotDeadcheck",
    Default = false,
    Callback = function(Value) TriggerbotData.Deadcheck = Value end
})
TriggerbotSection:Toggle({
    Name = "Invincible check",
    Flag = "InvinciblecheckTriggerbot",
    Default = false,
    Callback = function(Value) TriggerbotData.Invinciblecheck = Value end
})
TriggerbotSection:Slider({
    Name = "Delay",
    Flag = "TriggerbotDelay",
    Min = 0,
    Suffix = " ms",
    Max = 300,
    Default = 0,
    Decimals = 1,
    Callback = function(Value) TriggerbotData.Delay = Value end
})



-- Silent Aim
local SilentAimSection = Legit:Section({Name = "Silent Aim", Side = 2})
SilentAimSection:Toggle({
    Name = "Enabled",
    ToolTip = {Name = "Silent Aim", Description = "Redirects bullets to the closest player"},
    Flag = "SilentAimEnabled",
    Default = false,
    Callback = function(Value) SilentAimData.Enabled = Value end
}):Keybind({
    Flag = "SilentAimKeybind",
    Default = Enum.KeyCode.None,
    Mode = "Toggle",
    Callback = function(Value) SilentAimData.Enabled = Value end
})
SilentAimSection:Slider({
    Name = "FOV",
    Flag = "SilentAimFOV",
    Min = 10,
    Suffix = "",
    Max = 1200,
    Default = 150,
    Decimals = 1,
    Callback = function(Value) SilentAimData.FOV = Value end
})
SilentAimSection:Slider({
    Name = "Max Distance",
    Flag = "SilentAimMaxDist",
    Min = 0,
    Suffix = " studs",
    Max = 2000,
    Default = 300,
    Decimals = 1,
    Callback = function(Value) SilentAimData.MaxDistance = Value end
})
SilentAimSection:Toggle({
    Name = "Show FOV",
    Flag = "ShowFOVSA",
    Default = true,
    Callback = function(Value) SilentAimData.ShowFOV = Value end
})
SilentAimSection:Dropdown({
    Name = "Target Part",
    Items = {"Head", "Torso", "Left Leg", "Right Leg", "Left Arm", "Right Arm", "HumanoidRootPart"},
    Flag = "SilentAimTargetPart",
    Default = "Head",
    Multi = false,
    Callback = function(Value) SilentAimData.TargetPart = Value end
})
SilentAimSection:Toggle({
    Name = "Wallcheck",
    Flag = "SilentAimWallcheck",
    Default = false,
    Callback = function(Value) SilentAimData.Wallcheck = Value end
})
SilentAimSection:Toggle({
    Name = "Teamcheck",
    Flag = "SilentAimTeamcheck",
    Default = false,
    Callback = function(Value) SilentAimData.Teamcheck = Value end
})
SilentAimSection:Toggle({
    Name = "Deadcheck",
    Flag = "SilentAimDeadcheck",
    Default = false,
    Callback = function(Value) SilentAimData.Deadcheck = Value end
})
SilentAimSection:Toggle({
    Name = "Invincible check",
    Flag = "InvinciblecheckSilentAim",
    Default = false,
    Callback = function(Value) SilentAimData.Invinciblecheck = Value end
})



local GunModsSection = Legit:Section({Name = "Gun mods", Side = 1})
GunModsSection:Toggle({
    Name = "No spread",
    Flag = "NoSpread",
    Default = false,
    Callback = function(Value)
        GunModsData.NoSpread = Value

        local Gun
        for index, Instance in pairs(LP.Character:GetChildren()) do
            if IsGun(Instance) then 
                Gun = Instance
                break
            end
        end
        if Gun and IsLPAlive() then
            LP.Character.Humanoid:UnequipTools()
            task.delay(0.05, function()
                if not IsLPAlive() then return end
                LP.Character.Humanoid:EquipTool(Gun)
            end)
        end

    end
})
GunModsSection:Toggle({
    Name = "Infinite Range",
    Flag = "InfiniteRange",
    Default = false,
    Callback = function(Value)
        GunModsData.InfiniteRange = Value

        local Gun
        for index, Instance in pairs(LP.Character:GetChildren()) do
            if IsGun(Instance) then 
                Gun = Instance
                break
            end
        end
        if Gun and IsLPAlive() then
            LP.Character.Humanoid:UnequipTools()
            task.delay(0.05, function()
                if not IsLPAlive() then return end
                LP.Character.Humanoid:EquipTool(Gun)
            end)
        end
    end
})
GunModsSection:Toggle({
    Name = "Full Auto",
    Flag = "FullAuto",
    Default = false,
    Callback = function(Value)
        GunModsData.FullAuto = Value
        
        local Gun
        for index, Instance in pairs(LP.Character:GetChildren()) do
            if IsGun(Instance) then 
                Gun = Instance
                break
            end
        end
        if Gun and IsLPAlive() then
            LP.Character.Humanoid:UnequipTools()
            task.delay(0.05, function()
                if not IsLPAlive() then return end
                LP.Character.Humanoid:EquipTool(Gun)
            end)
        end
    end
})
GunModsSection:Toggle({
    Name = "Auto Reload",
    Flag = "AutoReload",
    Default = false,
    Callback = function(Value)
        GunModsData.AutoReload = Value
    end
})
GunModsSection:Slider({
    Name = "Fire rate",
    Flag = "FireRate",
    Min = 0.045,
    Suffix = " sec",
    Max = 1,
    Default = 0.2,
    Decimals = 0.005,
    Callback = function(Value) 
        GunModsData.FireRate = Value 
    
        local Gun
        for index, Instance in pairs(LP.Character:GetChildren()) do
            if IsGun(Instance) then 
                Gun = Instance
                break
            end
        end
        if Gun and IsLPAlive() then
            LP.Character.Humanoid:UnequipTools()
            task.delay(0.05, function()
                if not IsLPAlive() then return end
                LP.Character.Humanoid:EquipTool(Gun)
            end)
        end
    end
})
GunModsSection:Toggle({
    Name = "Fire Rate Enabled",
    Flag = "FireRateEnabled",
    Default = false,
    Callback = function(Value)
        GunModsData.FireRateEnabled = Value

        local Gun
        for index, Instance in pairs(LP.Character:GetChildren()) do
            if IsGun(Instance) then 
                Gun = Instance
                break
            end
        end
        if Gun and IsLPAlive() then
            LP.Character.Humanoid:UnequipTools()
            task.delay(0.05, function()
                if not IsLPAlive() then return end
                LP.Character.Humanoid:EquipTool(Gun)
            end)
        end
    end
})



local KillfeedSection = Legit:Section({Name = "Killfeed", Side = 2})
KillfeedSection:Toggle({
    Name = "Enabled",
    Flag = "KillfeedEnabled",
    ToolTip = {Name = "Killfeed", Description = 'Supposed to be an upcoming "debug tool" for "admins only", but we can use it as a killfeed too! '},
    Default = false,
    Callback = function(Value) KillfeedData.Enabled = Value end
})
KillfeedSection:Toggle({
    Name = "Include yourself",
    Flag = "KillfeedIncludeLP",
    Default = false,
    Callback = function(Value) KillfeedData.IncludeLP = Value end
})








local ESPSection = Visuals:Section({Name = "ESP", Side = 1})
ESPSection:Toggle({
    Name = "Enabled",
    Flag = "ESPEnabled",
    Default = false,
    Callback = function(Value) ESPData.Enabled = Value end
}):Colorpicker({
    Name = "ESP Color",
    Flag = "ESPColor",
    Default = Color3.fromRGB(255, 255, 255),
    Alpha = 1,
    Callback = function(Value, Alpha) ESPData.BoxColor = Value end
})
ESPSection:Toggle({
    Name = "Team Color",
    Flag = "ESPTeamColor",
    Default = false,
    Callback = function(Value) ESPData.TeamColor = Value end
})
ESPSection:Dropdown({
    Name = "Box Style",
    Items = {"2D", "Corner", "Wireframe"},
    Flag = "ESPBoxStyle",
    Default = "2D",
    Multi = false,
    Callback = function(Value) ESPData.BoxStyle = Value end
})
ESPSection:Toggle({
    Name = "Skeleton",
    Flag = "ESPSkeleton",
    Default = false,
    Callback = function(Value) ESPData.Skeleton = Value end
})
ESPSection:Toggle({
    Name = "Tracers",
    Flag = "ESPTracers",
    Default = false,
    Callback = function(Value) ESPData.Tracers = Value end
})
ESPSection:Toggle({
    Name = "Name",
    Flag = "ESPName",
    Default = false,
    Callback = function(Value) ESPData.Name = Value end
})
ESPSection:Toggle({
    Name = "Health Bar",
    Flag = "ESPHealthBar",
    Default = false,
    Callback = function(Value) ESPData.HealthBar = Value end
})
ESPSection:Toggle({
    Name = "Distance",
    Flag = "ESPDistance",
    Default = false,
    Callback = function(Value) ESPData.Distance = Value end
})
ESPSection:Toggle({
    Name = "Offscreen Arrow",
    Flag = "ESPOffscreenArrow",
    Default = false,
    Callback = function(Value) ESPData.OffscreenArrow = Value end
})



local VisualSection = Visuals:Section({Name = "Visuals", Side = 2})
VisualSection:Toggle({
    Name = "Full bright",
    Flag = "FullBright",
    Default = false,
    Callback = function(Value) 
        Lighting.GlobalShadows = not Value
        Lighting.Ambient = Value and Color3.fromRGB(220,220,220) or Color3.fromRGB(110,110,110)
    end
})
VisualSection:Toggle({
    Name = "No Fog",
    Flag = "NoFog",
    Default = false,
    Callback = function(Value) 
        Lighting.FogEnd = Value and 9e9 or 1400
    end
})
VisualSection:Toggle({
    Name = "Inf Zoom",
    Flag = "InfZoom",
    Default = false,
    Callback = function(Value) 
        LP.CameraMaxZoomDistance = Value and 9e9 or 40 
    end
})
VisualSection:Toggle({
    Name = "Time of day",
    Flag = "Time",
    Default = false,
    Callback = function(Value) 
        TimeOfDayData.Enabled = Value
    end
})
VisualSection:Slider({
    Name = "Time",
    Flag = "TimeSlider",
    Min = 0,
    Suffix = "",
    Max = 24,
    Default = 12,
    Decimals = 1,
    Callback = function(Value) TimeOfDayData.Time = Value end
})



local TracerRecolorSection = Visuals:Section({Name = "Tracer Recolor", Side = 2})
TracerRecolorSection:Toggle({
    Name = "Bullets",
    Flag = "BulletTracerRecolorEnabled",
    Default = false,
    Callback = function(Value) 
        _G.BulletTracerRecolorEnabled = Value
    end
}):Colorpicker({
    Name = "Color",
    Flag = "BulletTracerColor",
    Default = Color3.fromRGB(245, 205, 48),
    Alpha = 0,
    Callback = function(Value)
        _G.BulletTracerColor = Value
    end
})
TracerRecolorSection:Toggle({
    Name = "Sniper",
    Flag = "SniperTracerRecolorEnabled",
    Default = false,
    Callback = function(Value) 
        _G.SniperTracerRecolorEnabled = Value
    end
}):Colorpicker({
    Name = "Color",
    Flag = "SniperTracerColor",
    Default = Color3.fromRGB(163, 162, 165),
    Alpha = 0,
    Callback = function(Value)
        _G.SniperTracerColor = Value
    end
})
TracerRecolorSection:Toggle({
    Name = "Taser",
    Flag = "TaserTracerRecolorEnabled",
    Default = false,
    Callback = function(Value) 
        _G.TaserTracerRecolorEnabled = Value
    end
}):Colorpicker({
    Name = "Color",
    Flag = "TaserTracerColor",
    Default = Color3.fromRGB(0, 234, 255),
    Alpha = 0,
    Callback = function(Value)
        _G.TaserTracerColor = Value
    end
})








local LPSection = LocalPlayerPage:Section({Name = "Player", Side = 1})
LPSection:Toggle({
    Name = "Noclip",
    Flag = "LPNoclip",
    Default = false,
    Callback = function(Value) LPData.Noclip = Value; LPData.NoclipActual = Value end
})
LPSection:Toggle({
    Name = "Infinite Stamina",
    Flag = "LPInfiniteStamina",
    Default = false,
    Callback = function(Value) LPData.InfiniteStamina = Value end
})
LPSection:Toggle({
    Name = "Infinite Jump",
    Flag = "LPInfiniteJump",
    Default = false,
    Callback = function(Value) LPData.InfiniteJump = Value end
})
LPSection:Slider({
    Name = "Speed",
    Flag = "LPSpeed",
    Min = 0,
    Suffix = "",
    ToolTip = {Name = "Risky", Description = "Setting this too high may flag the Anticheat and kick you."},
    Max = 50,
    Default = 0,
    Decimals = 1,
    Callback = function(Value) LPData.Speed = Value end
})
LPSection:Toggle({
    Name = "Speed Enabled",
    Flag = "LPSpeedEnabled",
    Default = false,
    Callback = function(Value) LPData.SpeedEnabled = Value end
})
LPSection:Toggle({
    Name = "Anti fling kick",
    Flag = "LPAntiFlingKick",
    Default = true,
    Callback = function(Value) LPData.AntiFlingKick = Value end
})
LPSection:Toggle({
    Name = "Anti Tase",
    Flag = "LPAntiTase",
    Default = false,
    Callback = function(Value) 
        LPData.AntiTaze = Value
        tasedBlocking = Value
        for _, conn in pairs(getconnections(RealTasedSignal)) do
            if Value then
                conn:Disable()
            else
                conn:Enable()
            end
        end
    end
})
LPSection:Toggle({
    Name = "Punch Aura",
    Flag = "PunchAuraEnabled",
    Default = false,
    Callback = function(Value) PunchAuraData.Enabled = Value end
})
LPSection:Slider({
    Name = "Tool Hider Distance",
    Flag = "ToolHiderDistance",
    Min = 10,
    Max = 1000,
    Suffix = "",
    Default = 100,
    Decimals = 10,
    Callback = function(Value) LPData.ToolHiderDistance = Value end
})
LPSection:Toggle({
    Name = "Hide tool [Weird]",
    Desc = "ToolHider",
    Flag = "ToolHider",
    Default = false,
    Callback = function(Value) 
        if IsLoading then return end
        if not IsLPAlive() then 

            Library:Notification("Tool Hider", "Only toggle this when you have a Tool equipped and youre alive!.", 5)
            return 
        end

        local Tool
        for i,v in pairs(LP.Character:GetChildren()) do
            if v:IsA("Tool") then
                Tool = v
            end
        end


        local ToolName = Tool.Name

        if Value then
            LPData.OldTHDistance = LPData.ToolHiderDistance
            if not Tool then 
                Library:Notification("Tool Hider", "Only toggle this when you have a Tool equipped!.", 5)
                return 
            end
            Tool.Grip += Vector3.new(0, -(LPData.ToolHiderDistance), 0)
            Tool.Grip *= CFrame.Angles( -(math.pi / 2), 0, 0)
            LP.Character.Humanoid:UnequipTools()
            LP.Character.Humanoid:EquipTool(LP.Backpack[ToolName])
        else
            if not Tool then 
                Library:Notification("Tool Hider", "Only toggle this when you have a Tool equipped!.", 5)
            end
            Tool.Grip += Vector3.new(0, LPData.OldTHDistance, 0)
            Tool.Grip *= CFrame.Angles( (math.pi / 2), 0, 0)
            LP.Character.Humanoid:UnequipTools()
            LP.Character.Humanoid:EquipTool(LP.Backpack[ToolName])
        end


        LPData.ToolHider = Value 
    end
})
LPSection:Slider({
    Name = "Spinbot speed",
    Flag = "SpinBotSpeed",
    Min = 10,
    Max = 200,
    Suffix = "",
    Default = 50,
    Decimals = 1,
    Callback = function(Value) LPData.SpinBotSpeed = Value end
})
LPSection:Toggle({
    Name = "Spinbot",
    Desc = "Spinny",
    Flag = "SpinBot",
    Default = false,
    Callback = function(Value) LPData.SpinBot = Value end
})
LPSection:Slider({
    Name = "Fly Speed",
    Flag = "PlayerFlySpeed",
    Min = 10,
    Max = 200,
    ToolTip = {Name = "Risky", Description = "Setting this too high may flag the Anticheat and kick you.\nUnder 26 is completely undetected tho."},
    Suffix = "",
    Default = 50,
    Decimals = 1,
    Callback = function(Value) LPData.PlayerFlySpeed = Value end
})
LPSection:Toggle({
    Name = "Player Fly",
    Desc = "Fly with WASD & QE",
    Flag = "PlayerFly",
    Default = false,
    ToolTip = {Name = "Risky", Description = "Setting this too high may flag the Anticheat and kick you."},
    Callback = function(Value) LPData.PlayerFly = Value end
}):Keybind({
    Flag = "PlayerFlyKeybind",
    Default = Enum.KeyCode.None,
    Mode = "Toggle",
    Callback = function(Value) LPData.PlayerFly = Value end
})



local GuardsSection = LocalPlayerPage:Section({Name = "Guards", Side = 2})
GuardsSection:Toggle({
    Name = "Arrest Aura",
    Flag = "ArrestAuratEnabled",
    Default = false,
    Callback = function(Value) ArrestAuraData.Enabled = Value end
})
GuardsSection:Toggle({
    Name = "Arrest Aura (Legit)",
    Flag = "ArrestAuraLegitEnabled",
    Default = false,
    Callback = function(Value) ArrestAuraData.LegitEnabled = Value end
})
GuardsSection:Button():Add("Arrest all [May not work]",  function()
    if not (IsLPAlive() and IsLPOnTeam(Teams.Guards)) then return end

    local function GetCar()
        for _, Car in pairs(workspace.CarContainer:GetChildren()) do
            if not IsCarBeingDriven(Car) then
                return Car
            end
        end
        return SpawnCar()
    end

    local function IsCarValid(car)
        return car and car.Parent and car:FindFirstChild("Body") and car:FindFirstChild("Body"):FindFirstChild("VehicleSeat")
    end

    local function GetSeat(car)
        if not IsCarValid(car) then return nil end
        return car:FindFirstChild("Body"):FindFirstChild("VehicleSeat")
    end

    local function SitInCar(car)
        local seat = GetSeat(car)
        if not seat then return nil end
        if not IsLPAlive() then return nil end
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return nil end
        if hum.SeatPart then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            task.wait(0.3)
        end
        LP.Character:PivotTo(seat.CFrame + Vector3.new(0, 2, 0))
        task.wait(0.1)
        seat:Sit(hum)
        task.wait(0.1)
        return seat
    end

    local function RecoverCar(car)
        if IsCarValid(car) then return car end
        return SpawnCar()
    end

    local Car = IsInVehicle(LP)
    if not IsCarValid(Car) then
        Car = GetCar()
    end
    local Seat = IsCarValid(Car) and SitInCar(Car) or nil
    for _, Player in pairs(Players:GetPlayers()) do

        if not IsLPAlive() then break end

        local TargetChar = Player.Character
        if not TargetChar then continue end
        local TargetHRP = TargetChar:FindFirstChild("HumanoidRootPart")
        if not TargetHRP then continue end

       local CanArrest = (IsOnTeam(ClientsideData.SelectedPlayer, Teams.Criminals) or (IsOnTeam(ClientsideData.SelectedPlayer, Teams.Inmates) and (ClientsideData.SelectedPlayer:GetAttribute("Hostile") and ClientsideData.SelectedPlayer:GetAttribute("Hostile") == true or ClientsideData.SelectedPlayer:GetAttribute("Trespassing") and ClientsideData.SelectedPlayer:GetAttribute("Trespassing") == true))) and not Char:FindFirstChildWhichIsA("ForceField")
        if not CanArrest then continue end

        local TargetsCar = IsInVehicle(Player)
        local WasInOtherCar = false

        if TargetsCar then

            local targetsBody = TargetsCar:FindFirstChild("Body")
            if not targetsBody then continue end

            local satDown = false
            for _, v in pairs(targetsBody:GetChildren()) do
                if not (v:IsA("Seat") or v:IsA("VehicleSeat")) then continue end
                if v.Occupant then continue end
                if not IsLPAlive() then break end
                local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                if not hum then break end
                if hum.SeatPart then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    task.wait(0.3)
                end
                LP.Character:PivotTo(v.CFrame + Vector3.new(1, 2, -4))
                task.wait(0.1)
                v:Sit(hum)
                satDown = true
                break
            end

            if satDown then
                for i = 1, 5 do
                    if not TargetChar or not TargetChar.Parent then break end
                    pcall(function() RemoteEvents.Arrest:InvokeServer(Player, 1) end)
                    pcall(function() RemoteEvents.InteractItem:InvokeServer(TargetHRP) end)
                    task.wait(0.1)
                end
                WasInOtherCar = true
            end

        else

            Car = RecoverCar(Car)
            if not IsCarValid(Car) then break end
            Seat = GetSeat(Car)
            if not Seat then break end

            if not IsLPInVehicle() then
                if not IsLPAlive() then break end
                local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.SeatPart then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                    task.wait(0.3)
                end
                Seat:Sit(LP.Character.Humanoid)
                task.wait(0.1)
            end

            for i = 1, 5 do
                if not IsLPAlive() then break end
                if not IsCarValid(Car) then
                    Car = RecoverCar(Car)
                    if not IsCarValid(Car) then break end
                    Seat = GetSeat(Car)
                    if not Seat then break end
                    if not IsLPInVehicle() then
                        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                        if hum and hum.SeatPart then
                            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                            task.wait(0.3)
                        end
                        Seat:Sit(LP.Character.Humanoid)
                        task.wait(0.1)
                    end
                end
                local pivotCF = Car:GetPivot()
                local seatCF = Seat.CFrame
                local offset = pivotCF:Inverse() * seatCF
                Car:PivotTo(CFrame.new(TargetHRP.CFrame.Position) * offset:Inverse())
                task.wait(0.1)
            end

            for i = 1, 5 do
                if not TargetChar or not TargetChar.Parent then break end
                pcall(function() RemoteEvents.Arrest:InvokeServer(Player, 1) end)
                pcall(function() RemoteEvents.InteractItem:InvokeServer(TargetHRP) end)
                task.wait(0.1)
            end

        end

        task.wait(6)

        if WasInOtherCar then
            WasInOtherCar = false
            for i = 1, 3 do
                LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                task.wait(0.05)
            end
            if not IsLPAlive() then break end
            Car = RecoverCar(Car)
            if IsCarValid(Car) then
                Seat = SitInCar(Car)
            end
        end

    end
    Library:Notification("Done!", "(Probably) Arrested everyone.", 5)
end)



local InmateCrimSection = LocalPlayerPage:Section({Name = "Inmate / Criminals", Side = 2})
local RemoverButtons = InmateCrimSection:Button()
RemoverButtons:Add("Remove all Doors",  function()
    if DoorsRemoved then return end
    DoorsRemoved = true
    for index, instance in pairs(workspace.Doors:GetChildren()) do
        instance:Destroy()
    end

    workspace.Doors.ChildAdded:Connect(function(inst)
        inst:Destroy()
    end)

end)
RemoverButtons:Add("Remove all Toilets",  function()
    if ToiletsRemoved then return end
    ToiletsRemoved = true
    for index, instance in pairs(workspace.Prison_Cellblock:GetDescendants()) do
        if instance.Name ~= "Toilet" then continue end
        instance.Parent.ChildAdded:Connect(function(inst)
            if inst.Name ~= "Toilet" then return end
            inst:Destroy()
        end)

        instance:Destroy()
    end
end)
InmateCrimSection:Toggle({
    Name = "Disable Fence damage",
    Flag = "ArrestAuraLegitEnabled",
    Default = false,
    Callback = function(Value) 
        FencesDisabled = Value
        for index, instance in pairs(workspace.Prison_Fences:GetDescendants()) do
            if instance.Name ~= "damagePart" then continue end
            instance.Parent.ChildAdded:Connect(function(inst)
                if inst.Name ~= "damagePart" then return end
                inst.CanTouch = not FencesDisabled
            end)

            instance.CanTouch = not FencesDisabled
        end
    end
})
InmateCrimSection:Toggle({
    Name = "Item aura",
    Flag = "ItemAuraEnabled",
    
    ToolTip = {Name = "Item Aura", Description = "Automatically picks up items like M9 and Keycard (Hammer and Knife soon)"},
    Default = false,
    Callback = function(Value) ItemAuraData.Enabled = Value end
})
InmateCrimSection:Dropdown({
    Name = "Gun",
    Items = {"MP5", "Remington 870"},
    Flag = "ESPBoxStyle",
    Default = "2D",
    Multi = true,
    Callback = function(Value) 
        if not Value then return end
        GunGiverData.SelectedGun = Value 
    end
})
InmateCrimSection:Button():Add("Get gun",  function()

    if (os.time() - GunGiverData.Cooldown) < 7 then 
         Library:Notification("On Cooldown!", "You need to wait " .. 7 - (TeamPickerData.Cooldown - os.time()) .. " seconds before trying again", 5)
        return
    end
    local OrigPos = LP.Character:GetPivot()

    for Index, GunName in pairs(GunGiverData.SelectedGun) do
        if GunName == "MP5" then
            LP.Character:PivotTo(CFrame.new(813.5, 100, 2229))
            task.wait(0.35)
        end
        if #GunGiverData.SelectedGun > 1 then
            task.wait(0.5)
        end
        if GunName == "Remington 870" then
            LP.Character:PivotTo(CFrame.new(819.75, 100, 2229))
            task.wait(0.35)
        end
    end

    LP.Character:PivotTo(OrigPos)
    TeamPickerData.Cooldown = os.time()

end)



local TeamPickerSection = LocalPlayerPage:Section({Name = "Team Picker", Side = 1})
TeamPickerSection:Button():Add("Join Guards",  function()
    if (os.time() - TeamPickerData.Cooldown) < 7 then 
         Library:Notification("On Cooldown!", "You need to wait " .. 7 - (TeamPickerData.Cooldown - os.time()) .. " seconds before trying again", 5)
        return
    end
    if IsLPOnTeam(Teams.Guards) then return end

    if IsLPOnTeam(Teams.Neutral) then

        RemoteEvents.RequestTeamChange:InvokeServer(
            Teams.Guards,
            1
        )
        TeamPickerData.Cooldown = os.time()
        return
    end


    RemoteEvents.RequestTeamChange:InvokeServer(
        Teams.Neutral,
        1
    )
    task.wait(1)
    RemoteEvents.RequestTeamChange:InvokeServer(
        Teams.Guards,
        1
    )
    TeamPickerData.Cooldown = os.time()
end)
TeamPickerSection:Button():Add("Join Inmates",  function()
    if (os.time() - TeamPickerData.Cooldown) < 7 then 
         Library:Notification("On Cooldown!", "You need to wait " .. 7 - (TeamPickerData.Cooldown - os.time()) .. " seconds before trying again", 5)
        return
    end
    if IsLPOnTeam(Teams.Inmates) then return end

    if IsLPOnTeam(Teams.Neutral) then

        RemoteEvents.RequestTeamChange:InvokeServer(
            Teams.Inmates,
            1
        )
        TeamPickerData.Cooldown = os.time()
        return
    end

    
    RemoteEvents.RequestTeamChange:InvokeServer(
        Teams.Neutral,
        1
    )
    task.wait(1)
    RemoteEvents.RequestTeamChange:InvokeServer(
        Teams.Inmates,
        1
    )
    TeamPickerData.Cooldown = os.time()
end)
TeamPickerSection:Button():Add("Join Criminals",  function()
    if (os.time() - TeamPickerData.Cooldown) < 7 then 
         Library:Notification("On Cooldown!", "You need to wait " .. 7 - (TeamPickerData.Cooldown - os.time()) .. " seconds before trying again", 5)
        return
    end
    if IsLPOnTeam(Teams.Criminals) then
         return 
    end

    if IsLPOnTeam(Teams.Inmates) then
        LP.Character:PivotTo(CFrame.new(461, 99, 2213))

        task.wait(1)


        LP.Character.Humanoid.Health = 0
         return 
    end

    if IsLPOnTeam(Teams.Neutral) then

        RemoteEvents.RequestTeamChange:InvokeServer(
            Teams.Inmates,
            1
        )
        TeamPickerData.Cooldown = os.time()

        task.wait(0.075)

        if not IsLPOnTeam(Teams.Inmates) then return end

        LP.Character:PivotTo(CFrame.new(461, 99, 2213))

        task.wait(1)

        LP.Character.Humanoid.Health = 0

        return
    end

    
    RemoteEvents.RequestTeamChange:InvokeServer(
        Teams.Neutral,
        1
    )
    task.wait(1)
    RemoteEvents.RequestTeamChange:InvokeServer(
        Teams.Inmates,
        1
    )

        task.wait(0.075)

        if not IsLPOnTeam(Teams.Inmates) then return end

        LP.Character:PivotTo(CFrame.new(461, 99, 2213))

        task.wait(1)

        LP.Character.Humanoid.Health = 0
    TeamPickerData.Cooldown = os.time()
end)







-- Trolling
local TrollingSection = VehiclePage:Section({Name = "Trolling", Side = 1})
TrollingSection:Toggle({
    Name = "Car Noclip",
    Desc = "Makes car pass through objects",
    Flag = "CarNoclip",
    Default = false,
    Callback = function(Value) 
        TrollingData.CarNoclip = Value 
        
    end
})
TrollingSection:Slider({
    Name = "Fly Speed",
    Flag = "CarFlySpeed",
    Min = 10,
    Max = 1000,
    Suffix = "",
    Default = 50,
    Decimals = 1,
    Callback = function(Value) TrollingData.CarFlySpeed = Value end
})
TrollingSection:Toggle({
    Name = "Car Fly",
    Desc = "Fly with WASD & QE",
    Flag = "CarFly",
    Default = false,
    Callback = function(Value) TrollingData.CarFly = Value end
}):Keybind({
    Flag = "CarFlyKeybind",
    Default = Enum.KeyCode.None,
    Mode = "Toggle",
    Callback = function(Value) TrollingData.CarFly = Value end
})
TrollingSection:Slider({
    Name = "Car Speed",
    Flag = "CarSpeedValue",
    Min = 10,
    Max = 600,
    Suffix = "",
    Default = 85,
    Decimals = 1,
    Callback = function(Value) VehicleData.CarSpeedValue = Value end
})
TrollingSection:Toggle({
    Name = "Car speed",
    Desc = "Speedy",
    Flag = "CarSpeed",
    Default = false,
    Callback = function(Value) VehicleData.CarSpeed = Value end
})
TrollingSection:Slider({
    Name = "Car Accel",
    Flag = "CarAccelValue",
    Min = 10,
    Max = 100,
    Suffix = "",
    Default = 50,
    Decimals = 1,
    Callback = function(Value) VehicleData.CarAccelValue = Value end
})
TrollingSection:Toggle({
    Name = "Car Accel",
    Desc = "Speedy",
    Flag = "CarAccel",
    Default = false,
    Callback = function(Value) VehicleData.CarAccel = Value end
})
TrollingSection:Toggle({
    Name = "Fling",
    Desc = "Kick people",
    Flag = "VehicleFling",
    Default = false,
    Callback = function(Value) VehicleData.Fling = Value end
})


local CarStuff = VehiclePage:Section({Name = "Car stuff", Side = 2})
local SpawnCarButton = CarStuff:Button()
SpawnCarButton:Add("Spawn car", function()
    SpawnCar()
end)
SpawnCarButton:Add("Enter closest car", function()
    local car = GetClosestCar()
    if not car then return end
    if not IsLPAlive() then return end

    local seat = car:FindFirstChild("Body"):FindFirstChild("VehicleSeat")
    LP.Character:PivotTo(seat.CFrame + Vector3.new(0, 2, 0))
    
    task.wait(0.15)

    seat:Sit(LP.Character.Humanoid)
end)



local CarOptions = CarStuff:Button()
CarOptions:Add("Bring closest car", function()
    if not IsLPAlive() then return end
    local car = GetClosestCar()
    if not car then return end

    local OrigPos = LP.Character:GetPivot()
    local seat = car:FindFirstChild("Body"):FindFirstChild("VehicleSeat")

    LP.Character:PivotTo(seat.CFrame)

    seat:Sit(LP.Character.Humanoid)

    task.wait(0.15)

    if not LP.Character then return end
    local hum = LP.Character:FindFirstChildOfClass("Humanoid")
    if not hum or not hum.SeatPart then return end

    local pivotCF = car:GetPivot()
    local seatCF = seat.CFrame
    local offset = pivotCF:Inverse() * seatCF
    car:PivotTo(CFrame.new(OrigPos.Position) * offset:Inverse())
end)
CarOptions:Add("Bring all cars",  function()
    if not IsLPAlive() then return end

    local OrigPos = LP.Character:GetPivot()
    local Cars = workspace.CarContainer:GetChildren()
    for Index, Car in pairs(Cars) do
        if IsCarBeingDriven(Car) then 
            table.remove(Cars, Index)
        end
    end

    for i,v in pairs(Cars) do
        v.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
    end
    task.wait(.15)



    for index, Car in pairs(Cars) do

        if not Car then continue end
        if not Car:FindFirstChild("Body") then return end

        LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        
        task.wait(0.035)
        
        local seat = Car:FindFirstChild("Body"):FindFirstChild("VehicleSeat")

        if LP.Character.Humanoid.SeatPart then
            LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
           task.wait(0.01)
        end


        seat:Sit(LP.Character.Humanoid)

        for i,v in pairs(Car:FindFirstChild("Body"):GetChildren()) do
            if typeof(v) == "Seat" then v.Disabled = true end
        end

        task.wait(0.55)

        if not LP.Character then return end
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if not hum or not hum.SeatPart then return end

        local pivotCF = Car:GetPivot()
        local seatCF = seat.CFrame
        local offset = pivotCF:Inverse() * seatCF
        Car:PivotTo(CFrame.new(OrigPos.Position) * offset:Inverse())
        OrigPos += Vector3.new(math.random(-5, 5), math.random(0, 3), math.random(-5, 5))

        task.wait(0.55)
        
    end
    for index, Car in pairs(Cars) do
        for i,v in pairs(Car:FindFirstChild("Body"):GetChildren()) do
            if typeof(v) == "Seat" then v.Disabled = false end
        end
    end
end)



local CarStackerSection = VehiclePage:Section({Name = "Car Stacker", Side = 2})
CarStackerSection:Slider({
    Name = "Amount of Cars",
    Flag = "CarAmount",
    Default = 2,
    Min = 0,
    Max = 5,
    Decimals = 1,
    Callback = function(Value)
        VehicleData.CarStackerAmount = Value
    end
})
CarStackerSection:Button():Add("Stack Cars",  function()
    if not IsLPAlive() then return end

    local OrigPos = LP.Character:GetPivot()
    local Cars = {}
    for _, Car in pairs(workspace.CarContainer:GetChildren()) do
        if not IsCarBeingDriven(Car) then
            table.insert(Cars, Car)
        end
    end

    local needed = VehicleData.CarStackerAmount - #Cars
    for _ = 1, needed do
        local newCar = SpawnCar()
        if newCar then
            table.insert(Cars, newCar)
            task.wait(0.25)
        end
    end

    if #Cars == 0 then return end

    local stackCount = math.min(#Cars, VehicleData.CarStackerAmount)

    for i = 1, stackCount do
        Cars[i].ModelStreamingMode = Enum.ModelStreamingMode.Persistent
    end
    task.wait(.15)

    for index = 1, stackCount do
        local Car = Cars[index]

        if not Car then continue end
        if not Car:FindFirstChild("Body") then return end

        LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        
        task.wait(0.035)
        
        local seat = Car:FindFirstChild("Body"):FindFirstChild("VehicleSeat")

        if LP.Character.Humanoid.SeatPart then
            LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
           task.wait(0.01)
        end

        seat:Sit(LP.Character.Humanoid)

        for i,v in pairs(Car:FindFirstChild("Body"):GetChildren()) do
            if typeof(v) == "Seat" then v.Disabled = true end
        end

        task.wait(0.55)

        if not LP.Character then return end
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if not hum or not hum.SeatPart then return end

        local pivotCF = Car:GetPivot()
        local seatCF = seat.CFrame
        local offset = pivotCF:Inverse() * seatCF

        for TPIndex = 0, 100 do
            Car:PivotTo(CFrame.new(OrigPos.Position) * offset:Inverse())
            task.wait(0.01)
        end
        
        OrigPos += Vector3.new(0, 5, 0)

        task.wait(0.55)
        
    end
    for index = 1, stackCount do
        local Car = Cars[index]
        for i,v in pairs(Car:FindFirstChild("Body"):GetChildren()) do
            if typeof(v) == "Seat" then v.Disabled = false end
        end
    end
end)







local Teleports = TeleportsPage:Section({Name = "Teleports", Side = 1})
Teleports:Dropdown({
    Name = "Select",
    Flag = "TeleportSelect",
    Items = TeleportData.Teleports,
    Default = "-",    
    Callback = function(Value)
        if not Value then return end
        TeleportData.SelectedTeleport = Value
    end
})
Teleports:Button():Add("Teleport", function()
    if not TeleportData.SelectedTeleport then return end

    if LP.Character.Humanoid.SeatPart and LP.Character.Humanoid.SeatPart.Name == "VehicleSeat" then 
        local Seat = LP.Character.Humanoid.SeatPart
        local Car = Seat:FindFirstAncestor("Squad") or Seat:FindFirstAncestor("Sedan")

        local pivotCF = Car:GetPivot()
        local seatCF = Seat.CFrame
        local offset = pivotCF:Inverse() * seatCF
        Car:PivotTo(CFrame.new(TeleportData.TeleportCFrames[TeleportData.SelectedTeleport].Position) * offset:Inverse())

        return
    end

    local HasCar = (function()
        local Car = GetClosestCar()
        if Car then
            local Body = Car:FindFirstChild("Body"); if not Body then return false end
            local Seat = Body:FindFirstChild("VehicleSeat"); if not Seat then return false end

            if Seat.Occupant then return end

            LP.Character:PivotTo(Seat.CFrame + Vector3.new(0, 2, 0))

            Seat:Sit(LP.Character.Humanoid)

            task.wait(0.2)

            local pivotCF = Car:GetPivot()
            local seatCF = Seat.CFrame
            local offset = pivotCF:Inverse() * seatCF
            Car:PivotTo(CFrame.new(TeleportData.TeleportCFrames[TeleportData.SelectedTeleport].Position) * offset:Inverse())
            return true
        end
        return false
    end)()

    if not HasCar then
        local Car = SpawnCar()
        if not Car then return end -- to even get this, what the HELL did you do

            local Seat = Car:FindFirstChild("Body"):FindFirstChild("VehicleSeat")
            local pivotCF = Car:GetPivot()
            local seatCF = Seat.CFrame
            local offset = pivotCF:Inverse() * seatCF
            Car:PivotTo(CFrame.new(TeleportData.TeleportCFrames[TeleportData.SelectedTeleport].Position) * offset:Inverse())
    end

end)








local ChatLogger = PlayersPage:Section({Name = "Chat Logger", Side = 1})
ChatLogger:Toggle({
    Name = "Chat Logger",
    Flag = "ChatLoggerEnabled",
    Default = false,
    Callback = function(Value) 
        ChatLoggerData.Enabled = Value 
        if Value then
            rconsolecreate()
            rconsolename("Chat Logger")
            rconsoleerr("Do NOT close the Chat logger by the X button - Use the toggle in the GUI.")
            rconsoleshow()
        else
            rconsoledestroy()
        end
    end
})
ChatLogger:Toggle({
    Name = "Include yourself",
    Flag = "IncludeLPEnabled",
    Default = false,
    Callback = function(Value) ChatLoggerData.IncludeLP = Value end
})

local PlayersSection = PlayersPage:Section({Name = "Players", Side = 1})
local PlayerSearch = PlayersSection:Searchbox({
    Name = "Player search",
    Flag = "PlayerSearch",
    Items = (function() 
        local players = {}
        for _Index, Player in pairs(Players:GetPlayers()) do
            if Player == LP then continue end
            table.insert(players, Player.Name)
        end
        return players
    end)(),
    Multi = false,
    Default = "",
    Callback = function(Value)
        ClientsideData.SelectedPlayer = Players[Value]
    end
})
PlayersSection:Button():Add("Send Fake kick Message",  function()
    if not ClientsideData.SelectedPlayer then return end
    firesignal(RemoteEvents.MessageReceived.OnClientEvent, ClientsideData.SelectedPlayer.Name .. " was kicked from the game")
end)
PlayersSection:Button():Add("Teleport to",  function()
    if not ClientsideData.SelectedPlayer then return end
    
    if not ClientsideData.SelectedPlayer then return end
    local Car = GetClosestCar()

    if not Car then Car = SpawnCar() end
    if not Car then return end

    local Char = ClientsideData.SelectedPlayer.Character
    if not Char then return end

    local Seat = Car:FindFirstChild("Body"):FindFirstChild("VehicleSeat")
    if not Seat then return end

    LP.Character:PivotTo(Seat.CFrame)
    Seat:Sit(LP.Character.Humanoid)

    task.wait(0.2)

    local pivotCF = Car:GetPivot()
    local seatCF = Seat.CFrame
    local offset = pivotCF:Inverse() * seatCF
    Car:PivotTo(Char.HumanoidRootPart.CFrame * offset:Inverse())
end)
PlayersSection:Button():Add("Arrest",  function()
    if not IsLPOnTeam(Teams.Guards) then return end
    if not IsAlive(ClientsideData.SelectedPlayer) then return end

    local Char = ClientsideData.SelectedPlayer.Character
    if not Char then return end

    local CanArrest = (IsOnTeam(ClientsideData.SelectedPlayer, Teams.Criminals) or (IsOnTeam(ClientsideData.SelectedPlayer, Teams.Inmates) and (ClientsideData.SelectedPlayer:GetAttribute("Hostile") and ClientsideData.SelectedPlayer:GetAttribute("Hostile") == true or ClientsideData.SelectedPlayer:GetAttribute("Trespassing") and ClientsideData.SelectedPlayer:GetAttribute("Trespassing") == true))) and not Char:FindFirstChildWhichIsA("ForceField")
    if not CanArrest then 
        Library:Notification("Failed to arrest", "Target is not arrestable.", 5)
        return
    end

    local TargetsCar = IsInVehicle(ClientsideData.SelectedPlayer)
    if not TargetsCar then
        local Car = GetClosestCar()
        if not Car then Car = SpawnCar() end
        if not Car then return end

        local Seat = Car:FindFirstChild("Body"):FindFirstChild("VehicleSeat")
        if not Seat then return end

        LP.Character:PivotTo(Seat.CFrame)
        Seat:Sit(LP.Character.Humanoid)

        task.wait(0.2)

        local pivotCF = Car:GetPivot()
        local seatCF = Seat.CFrame
        local offset = pivotCF:Inverse() * seatCF
        Car:PivotTo(Char.HumanoidRootPart.CFrame * offset:Inverse())

        task.wait(0.2)

        for i = 1, 5 do
            if not Char or not Char.Parent then break end
            pcall(function() RemoteEvents.Arrest:InvokeServer(ClientsideData.SelectedPlayer, 1) end)
            pcall(function() RemoteEvents.InteractItem:InvokeServer(Char.HumanoidRootPart) end)
            task.wait(0.1)
        end
    else

        local FreeSeat
        for i,v in pairs(TargetsCar:FindFirstChild("Body"):GetChildren()) do
            if not (v:IsA("Seat") or v:IsA("VehicleSeat")) then continue end
            if not v.Occupant then 
                FreeSeat = v 
                break
            end
        end
        if not FreeSeat then return end

        LP.Character:PivotTo(FreeSeat.CFrame)
        FreeSeat:Sit(LP.Character.Humanoid)

        for i = 1, 5 do
            if not Char or not Char.Parent then break end
            pcall(function() RemoteEvents.Arrest:InvokeServer(ClientsideData.SelectedPlayer, 1) end)
            pcall(function() RemoteEvents.InteractItem:InvokeServer(Char.HumanoidRootPart) end)
            task.wait(0.1)
        end

    end
end)
PlayersSection:Button():Add("Spectate",  function()
    if not ClientsideData.SelectedPlayer then return end
    
    if ClientsideData.ViewingPlayer == ClientsideData.SelectedPlayer then
        ClientsideData.ViewingPlayer = nil
        if IsLPAlive() then
            Camera.CameraSubject = LP.Character:FindFirstChild("Humanoid")
        end
        return
    end

    if not IsAlive(ClientsideData.SelectedPlayer) then return end

    ClientsideData.ViewingPlayer = ClientsideData.SelectedPlayer
    Camera.CameraSubject = ClientsideData.ViewingPlayer.Character:FindFirstChild("Humanoid")
end)





local ConfigsSection = SettingsPage:Section({Name = "Configs", Side = 1}) 
do
    local ConfigName
    local ConfigSelected

    local ConfigsSearchbox = ConfigsSection:Searchbox({
        Name = "SearchboxConfigs",
        Flag = "ConfigsSearchobx",
        Items = { },
        Multi = false,
        Callback = function(Value)
            ConfigSelected = Value
        end
    })

    ConfigsSection:Textbox({
        Name = "Config name", 
        Default = "", 
        Flag = "ConfigName", 
        Placeholder = "Enter text", 
        Callback = function(Value)
            ConfigName = Value
        end
    })

    local CreateAndDeleteButton = ConfigsSection:Button()

    CreateAndDeleteButton:Add("Create", function()
        if ConfigName and ConfigName ~= "" then
            if not isfile(Library.Folders.Configs .. "/" .. ConfigName .. ".json") then
                writefile(Library.Folders.Configs .. "/" .. ConfigName .. ".json", Library:GetConfig())
                Library:Notification("Success", "Created config "..ConfigName .. " succesfully", 5)
                Library:RefreshConfigsList(ConfigsSearchbox)
            else
                Library:Notification("Error", "Config with the name "..ConfigName .. " already exists", 5)
                return
            end
        end
    end)

    CreateAndDeleteButton:Add("Delete", function()
        if ConfigSelected then
            Library:DeleteConfig(ConfigSelected)
            Library:Notification("Success", "Deleted config "..ConfigSelected .. " succesfully", 5)
            Library:RefreshConfigsList(ConfigsSearchbox)
        end
    end)

    local LoadAndSaveButton = ConfigsSection:Button()    

    LoadAndSaveButton:Add("Load", function()
        if ConfigSelected then
            local Success, Result = Library:LoadConfig(readfile(Library.Folders.Configs .. "/" .. ConfigSelected))

            if Success then 
                Library:Notification("Success", "Loaded config "..ConfigSelected .. " succesfully", 5)
            else
                Library:Notification("Error", "Failed to load config "..ConfigSelected .. " report this to the devs:\n"..Result, 5)
            end
        end
    end)

    LoadAndSaveButton:Add("Save", function()
        if ConfigName and ConfigName ~= "" then
            writefile(Library.Folders.Configs .. "/" .. ConfigName .. ".json", Library:GetConfig())
            Library:Notification("Success", "Saved config "..ConfigName .. " succesfully", 5)
            Library:RefreshConfigsList(ConfigsSearchbox)
        end
    end)

    Library:RefreshConfigsList(ConfigsSearchbox)
end
local SettingsSection = SettingsPage:Section({Name = "Settings", Side = 2}) 
do
    SettingsSection:Toggle({
        Name = "Watermark",
        Flag = "Watermark",
        Default = true,
        Callback = function(Value)
            WaterMark:SetVisibility(Value)
        end
    })

    SettingsSection:Toggle({
        Name = "Keybind list",
        Flag = "Keybind list",
        Default = true,
        Callback = function(Value)
            KeybindList:SetVisibility(Value)
        end
    })

    SettingsSection:Label("UI Keybind"):Keybind({
        Name = "Menu keybind",
        Flag = "UIKeybind",
        Default = Library.MenuKeybind,
        Mode = "Toggle",
        Callback = function()
            Library.MenuKeybind = Library.Flags["UIKeybind"].Key
        end
    })
end

















































local old; old = hookfunction(Functions.castRay, newcclosure(function(...)
    if SilentAimData.Enabled then
        local Target = GetSilentAimTarget()
        if Target then
            return Target, Target.CFrame.Position
        end
    end
    return old(...)
end))
hookfunction(Functions.CreateBulletTracer or function(p1,p2) end, newcclosure(function(p1, p2)
    local Part = Instance.new("Part")
    Part.Name = "RayPart"
    Part.Material = Enum.Material.Neon
    Part.Anchored = true
    Part.Transparency = 0.5
    Part.formFactor = Enum.FormFactor.Custom
    Part.Size = Vector3.new(0.1, 0.1, (p1 - p2).magnitude)
    Part.CFrame = CFrame.new((p1 + p2) / 2, p2)
    Part.CanCollide = false
    Part.CanQuery = false
    Part.CanTouch = false
    Part.Color = _G.BulletTracerRecolorEnabled and _G.BulletTracerColor or Color3.fromRGB(245, 205, 48)
    Debris:AddItem(Part, 0.05)
    Part.Parent = workspace.CurrentCamera
end))
hookfunction(Functions.CreateTaserTracer or function(p1,p2) end, newcclosure(function(p1, p2)
    local Part = Instance.new("Part")
    Part.Name = "RayPart"
    Part.Material = Enum.Material.Neon
    Part.Anchored = true
    Part.Transparency = 0.5
    Part.formFactor = Enum.FormFactor.Custom
    Part.Size = Vector3.new(0.2, 0.2, (p1 - p2).magnitude)
    Part.CFrame = CFrame.new((p1 + p2) / 2, p2)
    Part.CanCollide = false
    Part.CanQuery = false
    Part.CanTouch = false
    Part.Color = _G.TaserTracerRecolorEnabled and _G.TaserTracerColor or Color3.fromRGB(0, 234, 255)
    Debris:AddItem(Part, 2)
    local v1 = Instance.new("SurfaceLight", Part)
    v1.Color = _G.TaserTracerRecolorEnabled and _G.TaserTracerColor or Color3.fromRGB(0, 234, 255)
    v1.Range = 7
    v1.Face = "Bottom"
    v1.Brightness = 5
    v1.Angle = 180
    local v2 = TweenService:Create(Part, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1})
    local v3 = TweenService:Create(v1, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Brightness = 0})
    v2:Play()
    v3:Play()
    Part.Parent = workspace.CurrentCamera
end))
hookfunction(Functions.CreateSniperTracer or function(p1,p2) end, newcclosure(function(p1, p2)
    local Part = Instance.new("Part")
    Part.Name = "RayPart"
    Part.Material = Enum.Material.Neon
    Part.Anchored = true
    Part.Transparency = 0.5
    Part.formFactor = Enum.FormFactor.Custom
    Part.Size = Vector3.new(0.17, 0.17, (p1 - p2).magnitude)
    Part.CFrame = CFrame.new((p1 + p2) / 2, p2)
    Part.CanCollide = false
    Part.CanQuery = false
    Part.CanTouch = false
    Part.Color = _G.SniperTracerRecolorEnabled and _G.SniperTracerColor or Color3.fromRGB(163, 162, 165)
    Debris:AddItem(Part, 4)
    TweenService:Create(Part, TweenInfo.new(2.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
    Part.Parent = workspace.CurrentCamera
end))










RunService.RenderStepped:Connect(function()

    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Position = center
    FOVCircle.Radius = AimbotData.FOV
    FOVCircle.Visible = AimbotData.Enabled and AimbotData.ShowFOV

    SilentAimFOVCircle.Position = center
    SilentAimFOVCircle.Radius = SilentAimData.FOV
    SilentAimFOVCircle.Visible = SilentAimData.Enabled and SilentAimData.ShowFOV

    UpdateESPBoxes()
    UpdateTriggerbot()


    if LPData.ToolHider then
        if IsLPAlive() then
            local Animator = LP.Character.Humanoid:FindFirstChild("Animator")
            for i,v in pairs(Animator:GetPlayingAnimationTracks()) do
                if v.Name == "ToolNoneAnim" or v.Name == "Animation" then
                    v:AdjustWeight(0.01, 0)
                end
            end
        end
    end





    if AimbotData.Enabled and not rmbHeld then
        local target = GetTarget()
        if target then
            local targetPos = target.Position
            if AimbotData.Prediction > 0 then
                local targetChar = target.Parent
                local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                local localChar = LP.Character
                local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
                if targetRoot and localRoot then
                    local targetVel = targetRoot.Velocity
                    local localVel = localRoot.Velocity
                    local diff = (targetVel - localVel) * AimbotData.Prediction
                    targetPos = targetPos + Vector3.new(diff.X, math.clamp(diff.Y, -2, 2), diff.Z)
                end
            end
            if AimbotData.Mode == "MouseMove" then
                if IsFirstPerson() then
                    local camPos = Camera.CFrame.Position
                    local goal = CFrame.lookAt(camPos, targetPos)
                    Camera.CFrame = Camera.CFrame:Lerp(goal, 1 / AimbotData.Smoothness)
                else
                    local screen = Camera:WorldToViewportPoint(targetPos)
                    local mousePos = UserInputService:GetMouseLocation()
                    local moveDelta = Vector2.new(screen.X, screen.Y) - mousePos
                    mousemoverel(
                        math.floor(moveDelta.X / (AimbotData.Smoothness > 5 and AimbotData.Smoothness or 5)),
                        math.floor(moveDelta.Y / (AimbotData.Smoothness > 5 and AimbotData.Smoothness or 5))
                    )
                end
            else
                local camPos = Camera.CFrame.Position
                local goal = CFrame.lookAt(camPos, targetPos)
                Camera.CFrame = Camera.CFrame:Lerp(goal, 1 / AimbotData.Smoothness)
            end
        end
    else
        lockedTarget = nil
    end







    if TrollingData.CarFly and IsLPInVehicle() then
        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            if carFlyBV then 
                carFlyBV:Destroy() 
                carFlyBV = nil 
            end
            if carFlyBG then 
                carFlyBG:Destroy() 
                carFlyBG = nil 
            end
            if savedCameraType then Camera.CameraType = savedCameraType savedCameraType = nil end
        else
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not savedCameraType then
                savedCameraType = Camera.CameraType
                Camera.CameraType = Enum.CameraType.Track
            end
            if not carFlyBV or not carFlyBV.Parent then
                carFlyBV = Instance.new("BodyVelocity")
                carFlyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                carFlyBV.P = 10000
                carFlyBV.Velocity = Vector3.zero
                carFlyBV.Parent = hrp
            end
            if not carFlyBG or not carFlyBG.Parent then
                carFlyBG = Instance.new("BodyGyro")
                carFlyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                carFlyBG.P = 10000
                carFlyBG.D = 500
                carFlyBG.Parent = hrp
            end
            carFlyBG.CFrame = Camera.CFrame
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then dir = dir - Vector3.new(0, 1, 0) end
            if dir.Magnitude > 0 then
                carFlyBV.Velocity = dir.Unit * TrollingData.CarFlySpeed
            else
                carFlyBV.Velocity = Vector3.zero
            end
        end
    else
        if carFlyBV then 
            carFlyBV:Destroy() 
            carFlyBV = nil 
        end
        if carFlyBG then 
            carFlyBG:Destroy() 
            carFlyBG = nil 
        end
        if savedCameraType then 
            Camera.CameraType = savedCameraType 
            savedCameraType = nil 
        end
    end








    if VehicleData.CarSpeed then
        local Car =  IsLPInVehicle()
        if Car then

            local LW = Car:FindFirstChild("LW")
            local RW = Car:FindFirstChild("RW")
            if RW and LW then
                LW:FindFirstChild("VS").MaxSpeed = VehicleData.CarSpeedValue
                RW:FindFirstChild("VS").MaxSpeed = VehicleData.CarSpeedValue
            end

        end
    end

    if VehicleData.CarAccel then
        local Car =  IsLPInVehicle()
        if Car then

            local LW = Car:FindFirstChild("LW")
            local RW = Car:FindFirstChild("RW")
            if RW and LW then
                if RW:FindFirstChild("VS").Torque == 2 and LW:FindFirstChild("VS").Torque == 2 then
                    LW:FindFirstChild("VS").Torque = VehicleData.CarAccelValue
                    RW:FindFirstChild("VS").Torque = VehicleData.CarAccelValue
                end
            end

        end
    end









    if LPData.PlayerFly and not IsLPInVehicle() then
        local char = LP.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then
            if playerFlyBV then 
                playerFlyBV:Destroy() 
                playerFlyBV = nil 
            end
            if savedCameraTypePlayer then 
                Camera.CameraType = savedCameraTypePlayer 
                savedCameraTypePlayer = nil 
            end
        else
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not savedCameraTypePlayer then
                savedCameraTypePlayer = Camera.CameraType
                Camera.CameraType = Enum.CameraType.Track
            end
            if not playerFlyBV or not playerFlyBV.Parent then
                playerFlyBV = Instance.new("BodyVelocity")
                playerFlyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                playerFlyBV.P = 10000
                playerFlyBV.Velocity = Vector3.zero
                playerFlyBV.Parent = hrp
            end
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then 
                dir = dir + Camera.CFrame.LookVector 
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then 
                dir = dir - Camera.CFrame.LookVector 
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then 
                dir = dir - Camera.CFrame.RightVector 
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then 
                dir = dir + Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then 
                dir = dir + Vector3.new(0, 1, 0) 
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then 
                dir = dir - Vector3.new(0, 1, 0)
            end
            if dir.Magnitude > 0 then
                playerFlyBV.Velocity = dir.Unit * LPData.PlayerFlySpeed
            else
                playerFlyBV.Velocity = Vector3.zero
            end
        end
    else
        if playerFlyBV then 
            playerFlyBV:Destroy()
            playerFlyBV = nil 
        end
        if savedCameraTypePlayer then 
            Camera.CameraType = savedCameraTypePlayer 
            savedCameraTypePlayer = nil 
        end
    end




----------





    if IsLPAlive() and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") and LPData.AntiFlingKick then
        if LP.Character.HumanoidRootPart.CFrame.Position.Y > 175 then
            Library:Notification("AntiAC", "Dont go too high.", 5)
            LP.Character.HumanoidRootPart.CFrame = CFrame.new(LP.Character.HumanoidRootPart.CFrame.Position.X, 170, LP.Character.HumanoidRootPart.CFrame.Position.Z)
        end
    end

end)

RunService.Stepped:Connect(function()



    if not IsLPAlive() then return end
    local head = LP.Character:WaitForChild("Head", 10)
    if not head then return end
    for _, conn in ipairs(getconnections(head:GetPropertyChangedSignal("CanCollide"))) do
        conn:Disconnect() --added this cuz obfuscation breaks it?
    end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    local head = char:FindFirstChild("Head")
    if head then head.CanCollide = not LPData.Noclip end
    local torso = char:FindFirstChild("Torso")
    if torso then torso.CanCollide = not LPData.Noclip end

        local antiJump = char:FindFirstChild("AntiJump")
        if antiJump and antiJump:IsA("LocalScript") then
            antiJump.Disabled = LPData.InfiniteStamina
        end

    if LPData.SpeedEnabled and not LPData.PlayerFly and (not IsLPInVehicle()) and hum.MoveDirection.Magnitude > 0 then
        hrp.CFrame = hrp.CFrame + (hum.MoveDirection * LPData.Speed / 200)
    end

    if LPData.SpinBot then
        hum.AutoRotate = false
        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(LPData.SpinBotSpeed / 10), 0)
    else
        hum.AutoRotate = true
    end

    if GunModsData.AutoReload then
        for i,v in pairs(LP.Character:GetChildren()) do
            if v:IsA("Tool") and IsGun(v) then
                if v:GetAttribute("CurrentAmmo") == 0 then
                    if v:GetAttribute("IsReloading") == false and v:GetAttribute("Local_ReloadSession") == 0 then
                        Functions.Reload() 
                    end
                end
            end
        end
    end

    if TrollingData.CarNoclip and IsLPInVehicle() then
        local seat = hum.SeatPart
        local root = seat:FindFirstAncestor("Squad") or seat:FindFirstAncestor("Sedan")
        if not root then return end
        for _, part in ipairs(root:GetDescendants()) do
            if part:IsA("BasePart") then
                if carNoclipParts[part] == nil then
                    carNoclipParts[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
        carNoclipActive = true
        LPData.Noclip = true
    else
        LPData.Noclip = LPData.NoclipActual
        if carNoclipActive then
            for part, val in pairs(carNoclipParts) do
                if part and part.Parent then
                    part.CanCollide = val
                end
            end
            carNoclipParts = {}
            carNoclipActive = false
        end
    end

end)

local punchAuraDebounce = {}
local arrestAuraDebounce = 0

TextChatService.MessageReceived:Connect(function(Message)
    if ChatLoggerData.Enabled then
        if Message.TextSource.UserId == LP.UserId and not ChatLoggerData.IncludeLP then return end

        local source = Message.TextSource
        local playerName = source and Players:GetNameFromUserIdAsync(source.UserId) or "SYSTEM"
        rconsoleerr(playerName)
        rconsoleprint(" : ")
        rconsoleinfo(Message.Text .. "\n")
    end
end)

RunService.Heartbeat:Connect(function()


    if ItemAuraData.Enabled and IsLPAlive() then
        local char = LP.Character
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local items = {workspace:FindFirstChild("M9"), workspace:FindFirstChild("Key card"), workspace:FindFirstChild("Hammer"), workspace:FindFirstChild("Crude Knife")}
            for _, item in ipairs(items) do
                if item and item:IsA("Model") then
                    local part = item:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local dist = (hrp.Position - part.Position).Magnitude
                        if dist <= 6 then
                            pcall(function()
                                RemoteEvents.GiverPressed:FireServer(item)
                            end)
                        end
                    end
                end
            end
        end
    end


    if PunchAuraData.Enabled and IsLPAlive() then
        local char = LP.Character
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr == LP then continue end
                if not IsAlive(plr) then continue end
                local targetChar = plr.Character
                local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                if not targetHRP then continue end

                local dist = (hrp.Position - targetHRP.Position).Magnitude
                if dist <= 5 then
                    local now = tick()
                    if not punchAuraDebounce[plr] or (now - punchAuraDebounce[plr]) >= 0.5 then
                        punchAuraDebounce[plr] = now
                        pcall(function()
                            RemoteEvents.Melee:FireServer(plr, 1, 1)
                        end)
                    end
                end
            end
        end
    end


    if ArrestAuraData.LegitEnabled then
        if not IsLPOnTeam(Teams.Guards) then return end
        local char = LP.Character
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then

    
            local now = tick()
            if (now - arrestAuraDebounce) >= 4 then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr == LP then continue end
                    if not IsAlive(plr) then continue end
                    local targetChar = plr.Character
                    local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                    if not targetHRP then continue end
                    local CanArrest = (IsOnTeam(ClientsideData.SelectedPlayer, Teams.Criminals) or (IsOnTeam(ClientsideData.SelectedPlayer, Teams.Inmates) and (ClientsideData.SelectedPlayer:GetAttribute("Hostile") and ClientsideData.SelectedPlayer:GetAttribute("Hostile") == true or ClientsideData.SelectedPlayer:GetAttribute("Trespassing") and ClientsideData.SelectedPlayer:GetAttribute("Trespassing") == true))) and not Char:FindFirstChildWhichIsA("ForceField")

                    local dist = (hrp.Position - targetHRP.Position).Magnitude
                    if dist <= 5 and CanArrest then
                        local HandCuffs = LP.Backpack:FindFirstChild("Handcuffs") or LP.Character:FindFirstChild("Handcuffs") -- if equipped
                        local HandCuffsEquipped = not (HandCuffs.Parent.Parent == LP)
                        
                        task.spawn(function()
                            if not HandCuffsEquipped then
                                LP.Character.Humanoid:UnequipTools() 

                                LP.Character.Humanoid:EquipTool(HandCuffs)

                                task.wait(0.12)
                            end
                            arrestAuraDebounce = now
                            if (hrp.Position - targetHRP.Position).Magnitude > 5 then
                                RemoteEvents.Arrest:InvokeServer(plr, 1)
                                RemoteEvents.InteractItem:InvokeServer(targetHRP)
                            end
                            task.wait(0.3)
                            LP.Character.Humanoid:UnequipTools() 
                        end)
                        break
                    end
                end
            end   
        end
    else
        if ArrestAuraData.Enabled and IsLPAlive() then
            if not IsLPOnTeam(Teams.Guards) then return end
            local char = LP.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local now = tick()
                if (now - arrestAuraDebounce) >= 4 then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr == LP then continue end
                        if not IsAlive(plr) then continue end
                        local targetChar = plr.Character
                        local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                        if not targetHRP then continue end
                        local CanArrest = (IsOnTeam(ClientsideData.SelectedPlayer, Teams.Criminals) or (IsOnTeam(ClientsideData.SelectedPlayer, Teams.Inmates) and (ClientsideData.SelectedPlayer:GetAttribute("Hostile") and ClientsideData.SelectedPlayer:GetAttribute("Hostile") == true or ClientsideData.SelectedPlayer:GetAttribute("Trespassing") and ClientsideData.SelectedPlayer:GetAttribute("Trespassing") == true))) and not Char:FindFirstChildWhichIsA("ForceField")

                        local dist = (hrp.Position - targetHRP.Position).Magnitude
                        if dist <= 5 and CanArrest then
                            arrestAuraDebounce = now
                            pcall(function()
                                RemoteEvents.Arrest:InvokeServer(plr, 1)
                                RemoteEvents.InteractItem:InvokeServer(targetHRP)
                            end)
                            break
                        end
                    end
                end
            end
        end
    end

end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rmbHeld = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        rmbHeld = false
    end
end)

UserInputService.JumpRequest:Connect(function()
    if not LPData.InfiniteJump then return end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)
Lighting:GetPropertyChangedSignal("TimeOfDay"):Connect(function() 
    if TimeOfDayData.Enabled then
        Lighting.TimeOfDay = TimeOfDayData.Time
    end
end)


ReplicatedStorage:FindFirstChild("Killfeed").ChildAdded:Connect(function(ChildInstance)
    if not ChildInstance:IsA("IntValue") then return end
    if not KillfeedData.Enabled then return end

    local KillfeedText = ChildInstance.Name

    local KillerName, KilledPerson, Gun = string.match(KillfeedText, "^.+ %(@(.+)%)  killed (.+) with (.+)$")
    if KillerName and KilledPerson and Gun then
        local article = Gun ~= "fists" and (string.match(Gun, "^[aeiouAEIOU]") and "an " or "a ") or ""
        if KillerName == LP.Name then
            KillfeedText = "You killed " .. KilledPerson .. " with " .. article .. Gun
        else
            local KillerDisplay = string.match(KillfeedText, "^(.+) %(") or KillerName
            KillfeedText = KillerDisplay .. " killed " .. KilledPerson .. " with " .. article .. Gun
        end
    end

    if string.find(KillfeedText, LP.Name) and not KillfeedData.IncludeLP then return end

    Library:Notification("Killfeed", KillfeedText, 5)

end)

LP.CharacterAdded:Connect(SetupCharacter)
if LP.Character then
    SetupCharacter(LP.Character)
end

LP.Backpack.ChildAdded:Connect(function(Instance)
    if not IsGun(Instance) then return end

    ApplyGunMods(Instance)

end)

Players.PlayerAdded:Connect(function() 
    local players = {}
    for _Index, Player in pairs(Players:GetPlayers()) do
        if Player == LP then continue end
        table.insert(players, Player.Name)
    end
    PlayerSearch:Refresh(players, false)
end)

Players.PlayerRemoving:Connect(function() 
    task.delay(0.1, function()
        local players = {}
        for _Index, Player in pairs(Players:GetPlayers()) do
            if Player == LP then continue end
            table.insert(players, Player.Name)
        end
        PlayerSearch:Refresh(players, false)
    end)
end)


task.spawn(function()
    while true do
        local vel, movel = nil, 0.1	

        local HumanoidRootPart = LP.Character:FindFirstChild("HumanoidRootPart")
        if VehicleData.Fling and IsLPInVehicle() and IsLPAlive() then
            RunService.Heartbeat:Wait()

            vel = HumanoidRootPart.Velocity
            HumanoidRootPart.Velocity = vel * 8000 + Vector3.new(0, 7000, 0)

            RunService.RenderStepped:Wait()

            if LP.Character and LP.Character.Parent and HumanoidRootPart and HumanoidRootPart.Parent then
                HumanoidRootPart.Velocity = vel
            end

            RunService.Stepped:Wait()
            if LP.Character and LP.Character.Parent and HumanoidRootPart and HumanoidRootPart.Parent then
                HumanoidRootPart.Velocity = vel + Vector3.new(0, movel, 0)
                movel = movel * -1
            end
        else
            task.wait()
        end
    end
end)




IsLoading = false
Library:Notification("Script loaded!", "Script loaded in " .. tostring(string.format("%.1f", tick() - LoadingStartTime))  .. "seconds.", 5)
