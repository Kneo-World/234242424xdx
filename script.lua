local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

print("=== [FIXED MESH SKIN CHANGER] Запущен! ===")

-- Проверенные рабочие Raw Asset ID для Roblox
local SKINS = {
    Knife = {
        MeshId = "rbxassetid://4738598711",     -- Icebreaker (Raw Mesh)
        TextureId = "rbxassetid://4738598920"  -- Icebreaker (Texture)
    },
    Gun = {
        MeshId = "rbxassetid://7800847534",     -- Harvester
        TextureId = "rbxassetid://7800847683"
    }
}

local function applyMesh(obj, skinData)
    if not obj or not skinData then return end

    local targetPart = obj:IsA("BasePart") and obj or obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart", true)
    if not targetPart then return end

    if targetPart:IsA("MeshPart") then
        targetPart.MeshId = skinData.MeshId
        if skinData.TextureId then targetPart.TextureID = skinData.TextureId end
    end

    local meshObj = targetPart:FindFirstChildOfClass("SpecialMesh") or targetPart:FindFirstChildWhichIsA("DataModelMesh")
    if meshObj then
        meshObj.MeshId = skinData.MeshId
        if skinData.TextureId then meshObj.TextureId = skinData.TextureId end
        -- Сброс масштаба, чтобы меш не пропадал
        meshObj.Scale = Vector3.new(1, 1, 1)
    else
        local newMesh = Instance.new("SpecialMesh")
        newMesh.Name = "Mesh"
        newMesh.MeshId = skinData.MeshId
        if skinData.TextureId then newMesh.TextureId = skinData.TextureId end
        newMesh.Parent = targetPart
    end
end

local function isMyDisplay(displayObj)
    local char = LocalPlayer.Character
    if not char then return false end

    for _, descendant in ipairs(displayObj:GetDescendants()) do
        if descendant:IsA("RigidConstraint") or descendant:IsA("Weld") or descendant:IsA("WeldConstraint") then
            local p0 = descendant:IsA("RigidConstraint") and descendant.Attachment0 or descendant.Part0
            local p1 = descendant:IsA("RigidConstraint") and descendant.Attachment1 or descendant.Part1
            if (p0 and p0:IsDescendantOf(char)) or (p1 and p1:IsDescendantOf(char)) then
                return true
            end
        end
    end
    return false
end

local function updateAll()
    local char = LocalPlayer.Character
    if not char then return end

    -- Проверка инвентаря и рук
    local containers = {LocalPlayer:FindFirstChild("Backpack"), char}
    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    local name = item.Name:lower()
                    if name:find("knife") or item:FindFirstChild("Knife") then
                        item.TextureId = SKINS.Knife.TextureId
                        applyMesh(item, SKINS.Knife)
                    elseif name:find("gun") or item:FindFirstChild("Gun") then
                        item.TextureId = SKINS.Gun.TextureId
                        applyMesh(item, SKINS.Gun)
                    end
                end
            end
        end
    end

    -- Проверка предметов на теле
    local weaponDisplays = Workspace:FindFirstChild("WeaponDisplays")
    if weaponDisplays then
        for _, display in ipairs(weaponDisplays:GetChildren()) do
            if isMyDisplay(display) then
                local name = display.Name:lower()
                if name:find("knife") then
                    applyMesh(display, SKINS.Knife)
                elseif name:find("gun") then
                    applyMesh(display, SKINS.Gun)
                end
            end
        end
    end
end

-- Постоянное обновление каждые 0.1 сек
task.spawn(function()
    while task.wait(0.1) do
        pcall(updateAll)
    end
end)
