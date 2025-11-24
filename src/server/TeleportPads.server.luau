local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Configure the exact names of your spawn parts here
local PAD_A_NAME = "Home Spawn 1"
local PAD_B_NAME = "Home Spawn 2"
local COOLDOWN_SECONDS = 2

local padA = Workspace:FindFirstChild(PAD_A_NAME)
local padB = Workspace:FindFirstChild(PAD_B_NAME)

if not padA or not padB then
    warn("TeleportPads: Could not find both pads. Expected names:", PAD_A_NAME, PAD_B_NAME)
    return
end

local lastTeleport = {} -- maps userId -> timestamp

local function getPlayerFromPart(part)
    local current = part
    while current do
        local player = Players:GetPlayerFromCharacter(current)
        if player then
            return player, player.Character
        end
        current = current.Parent
    end
    return nil, nil
end

local function tryTeleport(player, character, targetPad)
    if not player or not character or not targetPad then
        return
    end

    local uid = player.UserId
    local now = os.clock()
    if lastTeleport[uid] and now - lastTeleport[uid] < COOLDOWN_SECONDS then
        return
    end

    lastTeleport[uid] = now

    -- Attempt to move the player's HumanoidRootPart (or PrimaryPart)
    local hrp = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    if not hrp then
        warn("TeleportPads: character has no HumanoidRootPart/PrimaryPart for", player.Name)
        return
    end

    -- place player slightly above the pad to avoid getting stuck
    local targetCFrame = targetPad.CFrame + Vector3.new(0, 3, 0)
    pcall(function()
        hrp.CFrame = targetCFrame
    end)
end

padA.Touched:Connect(function(hit)
    local player, character = getPlayerFromPart(hit)
    if player then
        tryTeleport(player, character, padB)
    end
end)

padB.Touched:Connect(function(hit)
    local player, character = getPlayerFromPart(hit)
    if player then
        tryTeleport(player, character, padA)
    end
end)

-- Optional: cleanup old entries occasionally
task.spawn(function()
    while true do
        local now = os.clock()
        for uid, t in pairs(lastTeleport) do
            if now - t > COOLDOWN_SECONDS * 5 then
                lastTeleport[uid] = nil
            end
        end
        task.wait(COOLDOWN_SECONDS * 2)
    end
end)
