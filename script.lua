local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

print("=== [DIRECT MESH REPLACEMENT] Запуск ===")

-- Прямые ссылки на MeshId и TextureId скинов
local SKINS = {
    Knife = {
        MeshId = "rbxassetid://6022874136",  -- Icebreaker
        TextureId = "rbxassetid://6022874251"
    },
    Gun = {
        MeshId = "rbxassetid://7800847534",   -- Harvester
        TextureId = "rbxassetid://7800847683"
    }
}

-- Функция жесткой замены меша
local function replaceMesh(parentObj, skinData)
    if not parentObj or not skinData then return end

    -- Находим сам Part
    local targetPart = parentObj:IsA("BasePart") and parentObj or parentObj:FindFirstChild("Handle") or parentObj:FindFirstChildWhichIsA("BasePart", true)
    if not targetPart then return end

    -- 1. Если сам партик — MeshPart
    if targetPart:IsA("MeshPart") then
        targetPart.MeshId = skinData.MeshId
        if skinData.TextureId then targetPart.TextureID = skinData.TextureId end
        return
    end

    -- 2. Если внутри лежит дочерний Mesh (как GunDisplay -> Mesh на твоем скриншоте)
    local meshObj = targetPart:FindFirstChild("Mesh") 
        or targetPart:FindFirstChildOfClass("SpecialMesh") 
        or targetPart:FindFirstChildWhichIsA("DataModelMesh")

    if meshObj then
        meshObj.MeshId = skinData.MeshId
        if skinData.TextureId then 
            meshObj.TextureId = skinData.TextureId 
        end
    else
        -- Если меша не было вообще
        local newMesh = Instance.new("SpecialMesh")
        newMesh.Name = "Mesh"
        newMesh.MeshId = skinData.MeshId
        if skinData.TextureId then newMesh.TextureId = skinData.TextureId end
        newMesh.Parent = targetPart
    end
end

-- Проверка привязки дисплея на спине к твоему игроку
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

-- Перерисовка
local function applyVisuals()
    local char = LocalPlayer.Character
    if not char then return end

    -- А. Меняем предметы в Backpack (инвентарь быстрого доступа) и в руках
    local containers = {LocalPlayer:FindFirstChild("Backpack"), char}
    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    local nameLower = item.Name:lower()
                    if nameLower:find("knife") or item:FindFirstChild("Knife") then
                        item.TextureId = SKINS.Knife.TextureId
                        replaceMesh(item, SKINS.Knife)
                    elseif nameLower:find("gun") or item:FindFirstChild("Gun") then
                        item.TextureId = SKINS.Gun.TextureId
                        replaceMesh(item, SKINS.Gun)
                    end
                end
            end
        end
    end

    -- Б. Меняем модели на спине/поясе (Workspace.WeaponDisplays)
    local weaponDisplaysFolder = Workspace:FindFirstChild("WeaponDisplays")
    if weaponDisplaysFolder then
        for _, display in ipairs(weaponDisplaysFolder:GetChildren()) do
            if isMyDisplay(display) then
                local nameLower = display.Name:lower()
                if nameLower:find("knife") then
                    replaceMesh(display, SKINS.Knife)
                elseif nameLower:find("gun") then
                    replaceMesh(display, SKINS.Gun)
                end
            end
        end
    end
end

-- Запуск постоянной проверки (раз в 0.2 сек)
task.spawn(function()
    while task.wait(0.2) do
        pcall(applyVisuals)
    end
end)
