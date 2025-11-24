local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local GROUP_NAME = "Players"

-- Create the collision group if it doesn't exist (ignore error if it already exists)
pcall(function()
    PhysicsService:CreateCollisionGroup(GROUP_NAME)
end)

-- Ensure players in the group don't collide with each other
pcall(function()
    PhysicsService:CollisionGroupSetCollidable(GROUP_NAME, GROUP_NAME, false)
end)

local function setCollisionGroup(character)
    if not character then
        return
    end

    -- Apply to existing parts
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            PhysicsService:SetPartCollisionGroup(part, GROUP_NAME)
        end
    end

    -- Ensure parts added later also get the collision group
    character.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("BasePart") then
            PhysicsService:SetPartCollisionGroup(descendant, GROUP_NAME)
        end
    end)
end

-- Apply to players that join and their characters
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        -- Wait for root part (optional) but don't yield indefinitely
        if character:FindFirstChild("HumanoidRootPart") == nil then
            character:WaitForChild("HumanoidRootPart")
        end
        setCollisionGroup(character)
    end)
end)

-- Apply to players already in the game (useful when script reloads)
for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        setCollisionGroup(player.Character)
    end
    player.CharacterAdded:Connect(function(character)
        if character:FindFirstChild("HumanoidRootPart") == nil then
            character:WaitForChild("HumanoidRootPart")
        end
        setCollisionGroup(character)
    end)
end
