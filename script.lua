local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")

local LocalPlayer = Players.LocalPlayer

print("=== [REAL WORKING ASSET SKIN CHANGER] ===")

-- Готовые рабочие Asset ID 3D-моделей ножей и пестов
local SKINS_DATA = {
    Knife = {
        AssetId = 4738598711, -- Icebreaker (Model Asset ID)
        FallbackMesh = "rbxassetid://4738598711",
        TextureId = "rbxassetid://4738598920"
    },
    Gun = {
        AssetId = 7800847534, -- Harvester
        FallbackMesh = "rbxassetid://7800847534",
        TextureId = "rbxassetid://7800847683"
    }
}

local function forceApplyVisual(toolObj, skinConfig)
    if not toolObj or not toolObj:IsA("Tool") then return end
    
    local handle = toolObj:FindFirstChild("Handle") or toolObj:FindFirstChildWhichIsA("BasePart", true)
    if not handle then return end

    -- Защита от дублирования
    if handle:FindFirstChild("CustomVisualSkinApplied") then return end

    -- Попытка 1: Пробуем загрузить 3D-модель через InsertService
    local loadedModel = nil
    pcall(function()
        loadedModel = InsertService:LoadAsset(skinConfig.AssetId)
    end)

    if loadedModel then
        local meshPart = loadedModel:FindFirstChildWhichIsA("MeshPart", true) or loadedModel:FindFirstChildWhichIsA("BasePart", true)
        if meshPart then
            handle.Transparent = 1
            for _, child in ipairs(handle:GetChildren()) do
                if child:IsA("SpecialMesh") or child:IsA("Decal") then
                    child:Destroy()
                end
            end

            local newPart = meshPart:Clone()
            newPart.Name = "CustomVisualSkinApplied"
            newPart.CFrame = handle.CFrame
            newPart.CanCollide = false
            newPart.Anchored = false
            newPart.Parent = handle

            local weld = Instance.new("WeldConstraint")
            weld.Part0 = handle
            weld.Part1 = newPart
            weld.Parent = newPart

            print("[✓ SUCCESS] Загружена и вшита полноценная 3D-модель для", toolObj.Name)
            return
        end
    end

    -- Попытка 2: Если InsertService заблокирован сервером, меняем текстуру и подменяем Mesh напрямую
    print("[INFO] Используем прямой метод подмены Mesh...")
    local mesh = handle:FindFirstChildOfClass("SpecialMesh")
    if not mesh then
        mesh = Instance.new("SpecialMesh")
        mesh.Name = "CustomVisualSkinApplied"
        mesh.Parent = handle
    else
        mesh.Name = "CustomVisualSkinApplied"
    end

    mesh.MeshId = skinConfig.FallbackMesh
    mesh.TextureId = skinConfig.TextureId
    toolObj.TextureId = skinConfig.TextureId
    
    print("[✓ SUCCESS] Обновлен MeshId и TextureId для", toolObj.Name)
end

local function scanInventory()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")

    local containers = {backpack, char}
    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    local name = item.Name:lower()
                    if name:find("knife") or item:FindFirstChild("Knife") then
                        forceApplyVisual(item, SKINS_DATA.Knife)
                    elseif name:find("gun") or item:FindFirstChild("Gun") then
                        forceApplyVisual(item, SKINS_DATA.Gun)
                    end
                end
            end
        end
    end
end

-- Авто-отслеживание при взятии оружия в руки
if LocalPlayer.Character then
    LocalPlayer.Character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
            scanInventory()
        end
    end)
end

task.spawn(function()
    while task.wait(0.5) do
        pcall(scanInventory)
    end
end)
