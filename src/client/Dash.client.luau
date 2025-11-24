local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- CONFIG
local DASH_KEY = Enum.KeyCode.Q
local DASH_SPEED = 480          -- studs/second applied during dash
local DASH_DURATION = 0.5         -- seconds the dash velocity is applied
local DASH_COOLDOWN = 1       -- seconds before player can dash again

local player = Players.LocalPlayer
local canDash = true
local dashing = false

local function getHumanoidRootPart()
    local char = player and player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = player and player.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Humanoid")
end

local function doDash()
    if not canDash or dashing then return end
    if UserInputService:GetFocusedTextBox() then return end

    local hrp = getHumanoidRootPart()
    local humanoid = getHumanoid()
    if not hrp or not humanoid then return end

    -- compute horizontal forward direction
    local look = hrp.CFrame.LookVector
    local forward = Vector3.new(look.X, 0, look.Z)
    if forward.Magnitude < 0.01 then
        forward = Vector3.new(0, 0, -100)
    else
        forward = forward.Unit
    end

    dashing = true
    canDash = false

    -- save original vertical velocity so we don't cancel jumps/falls
    local originalAV = hrp.AssemblyLinearVelocity
    local targetVel = forward * DASH_SPEED + Vector3.new(0, originalAV.Y, 0)

    -- apply dash velocity
    pcall(function()
        hrp.AssemblyLinearVelocity = targetVel
    end)

    -- restore velocity after duration (gentle stop)
    task.delay(DASH_DURATION, function()
        if hrp and hrp.Parent then
            -- reduce horizontal speed smoothly
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
            end)
        end
        dashing = false
    end)

    -- cooldown timer
    task.delay(DASH_COOLDOWN, function()
        canDash = true
    end)
end

-- Input binding
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == DASH_KEY then
        doDash()
    end
end)

-- Reset state on character changes
player.CharacterAdded:Connect(function(char)
    dashing = false
    canDash = true
end)

return nil
