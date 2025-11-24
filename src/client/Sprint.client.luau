local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- CONFIG
local SPRINT_MULTIPLIER = 3.75
-- Set this to an animation id (number or string) to play while sprinting, or leave empty to skip animation.
local SPRINT_ANIMATION_ID = "619522386" -- e.g. "123456789"

local player = Players.LocalPlayer
local humanoid
local animator
local sprintTrack
local sprinting = false
local sprintLock = false -- when true, sprint stays on until toggled off
local originalWalkSpeed = 20
local diedConn

local function cleanupSprintTrack()
    if sprintTrack then
        pcall(function()
            sprintTrack:Stop()
        end)
        sprintTrack = nil
    end
end

local function setHumanoid(h)
    -- Disconnect prior died connection and cleanup track
    if diedConn then
        pcall(function() diedConn:Disconnect() end)
        diedConn = nil
    end
    cleanupSprintTrack()

    humanoid = h
    animator = nil
    if humanoid and humanoid.Parent then
        originalWalkSpeed = humanoid.WalkSpeed or originalWalkSpeed

        -- Ensure an Animator exists
        animator = humanoid:FindFirstChildOfClass("Animator")
        if not animator then
            local ok, newAnimator = pcall(function()
                local a = Instance.new("Animator")
                a.Parent = humanoid
                return a
            end)
            if ok then animator = newAnimator end
        end

        -- Load sprint animation if configured
        if SPRINT_ANIMATION_ID ~= "" and animator then
            local anim = Instance.new("Animation")
            local id = tostring(SPRINT_ANIMATION_ID)
            if id:match("rbxassetid://") then
                anim.AnimationId = id
            else
                anim.AnimationId = "rbxassetid://" .. id
            end
            anim.Priority = Enum.AnimationPriority.Action
            local ok, track = pcall(function()
                return animator:LoadAnimation(anim)
            end)
            if ok and track then
                sprintTrack = track
            else
                sprintTrack = nil
            end
        end

        -- reconnect died handler
        diedConn = humanoid.Died:Connect(function()
            -- stop sprinting on death
            if sprinting then
                sprinting = false
            end
            cleanupSprintTrack()
        end)
    end
end

local function startSprint()
    if humanoid and not sprinting then
        sprinting = true
        humanoid.WalkSpeed = originalWalkSpeed * SPRINT_MULTIPLIER
        if sprintTrack then
            pcall(function() sprintTrack:Play() end)
        end
    end
end

local function stopSprint()
    if humanoid and sprinting then
        sprinting = false
        humanoid.WalkSpeed = originalWalkSpeed
        cleanupSprintTrack()
    end
end

local function toggleSprintLock()
    sprintLock = not sprintLock
    if sprintLock then
        startSprint()
    else
        -- only stop if player isn't holding Shift
        local left = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
        local right = UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        if not left and not right then
            stopSprint()
        end
    end
end

local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if UserInputService:GetFocusedTextBox() then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
            toggleSprintLock()
        end
    end
end

local function onInputEnded(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
            -- only stop if sprint isn't locked on
            if not sprintLock then
                stopSprint()
            end
        end
    end
end

-- Hook up character/humanoid
if player.Character then
    setHumanoid(player.Character:FindFirstChild("Humanoid"))
end

player.CharacterAdded:Connect(function(char)
    local h = char:WaitForChild("Humanoid", 5)
    setHumanoid(h)
    -- If sprint lock was enabled, re-enable sprint
    if sprintLock then startSprint() end
end)

player.CharacterRemoving:Connect(function()
    stopSprint()
    humanoid = nil
    animator = nil
    cleanupSprintTrack()
    if diedConn then pcall(function() diedConn:Disconnect() end) end
    diedConn = nil
end)

-- Input listeners
UserInputService.InputBegan:Connect(onInputBegan)
UserInputService.InputEnded:Connect(onInputEnded)

