local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

print("=== [FORCE CLONE SKIN CHANGER] START ===")

-- Ищем оригинальные подгруженные модели в памяти самой игры MM2
local function getGameWeaponModel(weaponName)
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v.Name:lower() == weaponName:lower() and (v:IsA("Model") or v:IsA("BasePart")) then
            return v
        end
    end
    return nil
end

local function attachFakeSkin(toolObj, skinName)
    if not toolObj then return end
    local handle = toolObj:FindFirstChild("Handle") or toolObj:FindFirstChildWhichIsA("BasePart", true)
    if not handle then return end

    -- Если уже прикрепили кастомный скин — пропускаем
    if handle:FindFirstChild("CustomVisualSkin") then return end

    -- Делаем дефолтный нож/пест невидимым
    handle.Transparent = 1
    for _, child in ipairs(handle:GetChildren()) do
        if child:IsA("SpecialMesh") or child:IsA("Decal") or child:IsA("Texture") then
            child.Parent = nil -- Удаляем старый меш
        end
    end

    -- Ищем модель скина в репозитории игры
    local sourceModel = getGameWeaponModel(skinName)
    if sourceModel then
        local clone = sourceModel:Clone()
        clone.Name = "CustomVisualSkin"

        if clone:IsA("Model") then
            local primary = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart", true)
            if primary then
                for _, part in ipairs(clone:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        part.Massless = true
                    end
                end
                
                -- Привариваем к Handle
                local weld = Instance.new("WeldConstraint")
                weld.Part0 = handle
                weld.Part1 = primary
                weld.Parent = primary
                
                clone:Parent(handle)
                print("[✓ SUCCESS] Вшита модель:", skinName, "в", toolObj.Name)
            end
        elseif clone:IsA("BasePart") then
            clone.CanCollide = false
            clone.Massless = true
            
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = handle
            weld.Part1 = clone
            weld.Parent = clone
            
            clone.Parent = handle
            print("[✓ SUCCESS] Вшит Part:", skinName, "в", toolObj.Name)
        end
    else
        print("[WARN] Модель", skinName, "не найдена в ReplicatedStorage игры!")
    end
end

-- Проверка рук и Backpack
local function scanAndApply()
    local char = LocalPlayer.Character
    if not char then return end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local targets = {backpack, char}

    for _, container in ipairs(targets) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    local name = item.Name:lower()
                    if name:find("knife") or item:FindFirstChild("Knife") then
                        attachFakeSkin(item, "Icebreaker")
                    elseif name:find("gun") or item:FindFirstChild("Gun") then
                        attachFakeSkin(item, "Harvester")
                    end
                end
            end
        end
    end
end

-- Запуск цикла проверки
task.spawn(function()
    while task.wait(0.3) do
        pcall(scanAndApply)
    end
end)
