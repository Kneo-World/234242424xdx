local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

print("==================================================")
print("=== [SUPER DETAILED SKIN CHANGER LOGS] ACTIVE ===")
print("==================================================")

local SKINS = {
    Knife = {
        Name = "Icebreaker",
        MeshId = "rbxassetid://4738598711",
        TextureId = "rbxassetid://4738598920"
    },
    Gun = {
        Name = "Harvester",
        MeshId = "rbxassetid://7800847534",
        TextureId = "rbxassetid://7800847683"
    }
}

local processedItems = {}

local function logAndApplyMesh(parentObj, skinData, category)
    if not parentObj or not skinData then return end

    local targetPart = parentObj:IsA("BasePart") and parentObj or parentObj:FindFirstChild("Handle") or parentObj:FindFirstChildWhichIsA("BasePart", true)
    
    if not targetPart then
        print(string.format("[LOG-WARN] [%s] Не найден Part/Handle у объекта: %s", category, parentObj:GetFullName()))
        return
    end

    local meshObj = targetPart:FindFirstChildOfClass("SpecialMesh") or targetPart:FindFirstChildWhichIsA("DataModelMesh")

    -- Логируем событие при первичном обнаружении предмета
    if not processedItems[parentObj] then
        processedItems[parentObj] = true
        print(string.format("\n[TARGET FOUND] Найдено оружие категории '%s'!", category))
        print(" -> Имя объекта:", parentObj.Name)
        print(" -> Путь:", parentObj:GetFullName())
        print(" -> Целевой Part:", targetPart.Name, "(" .. targetPart.ClassName .. ")")
        
        if meshObj then
            print(" -> Найден Mesh-объект:", meshObj.Name, "(" .. meshObj.ClassName .. ")")
            print("    [Было] MeshId:", meshObj.MeshId)
            print("    [Было] TextureId:", meshObj.TextureId)
        else
            print(" -> Внутренний Mesh не найден, создаем новый SpecialMesh...")
        end
    end

    -- Применяем текстуру к Tool
    if parentObj:IsA("Tool") and parentObj.TextureId ~= skinData.TextureId then
        parentObj.TextureId = skinData.TextureId
        print(" -> [Tool Icon Updated]:", skinData.TextureId)
    end

    -- Замена на MeshPart
    if targetPart:IsA("MeshPart") then
        if targetPart.MeshId ~= skinData.MeshId then
            targetPart.MeshId = skinData.MeshId
            if skinData.TextureId then targetPart.TextureID = skinData.TextureId end
            print(" [✓ SUCCESS] Заменен MeshPart на", skinData.Name)
        end
    end

    -- Замена на SpecialMesh
    if meshObj then
        if meshObj.MeshId ~= skinData.MeshId then
            meshObj.MeshId = skinData.MeshId
            if skinData.TextureId then meshObj.TextureId = skinData.TextureId end
            meshObj.Scale = Vector3.new(1, 1, 1)
            print(" [✓ SUCCESS] Заменен SpecialMesh на", skinData.Name)
        end
    else
        local newMesh = Instance.new("SpecialMesh")
        newMesh.Name = "Mesh"
        newMesh.MeshId = skinData.MeshId
        if skinData.TextureId then newMesh.TextureId = skinData.TextureId end
        newMesh.Parent = targetPart
        print(" [✓ SUCCESS] Создан и прикреплен новый SpecialMesh:", skinData.Name)
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

local function runScan()
    local char = LocalPlayer.Character
    if not char then return end

    -- 1. Инвентарь и руки
    local containers = {
        ["Backpack"] = LocalPlayer:FindFirstChild("Backpack"),
        ["Character (Руки)"] = char
    }

    for name, container in pairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    local itemName = item.Name:lower()
                    if itemName:find("knife") or item:FindFirstChild("Knife") then
                        logAndApplyMesh(item, SKINS.Knife, name .. " -> Knife")
                    elseif itemName:find("gun") or item:FindFirstChild("Gun") then
                        logAndApplyMesh(item, SKINS.Gun, name .. " -> Gun")
                    end
                end
            end
        end
    end

    -- 2. Спина/Пояс
    local weaponDisplays = Workspace:FindFirstChild("WeaponDisplays")
    if weaponDisplays then
        for _, display in ipairs(weaponDisplays:GetChildren()) do
            if isMyDisplay(display) then
                local dispName = display.Name:lower()
                if dispName:find("knife") then
                    logAndApplyMesh(display, SKINS.Knife, "WeaponDisplays -> Knife")
                elseif dispName:find("gun") then
                    logAndApplyMesh(display, SKINS.Gun, "WeaponDisplays -> Gun")
                end
            end
        end
    end
end

-- Отслеживание экипировки в реальном времени
local function setupListeners(char)
    if not char then return end
    print("[EVENT LISTENER] Подключен к персонажу:", char.Name)
    
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            print("\n[EVENT] Персонаж взял в руки предмет:", child.Name)
            task.wait(0.05)
            runScan()
        end
    end)
end

if LocalPlayer.Character then setupListeners(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(setupListeners)

-- Постоянная фоновая проверка
task.spawn(function()
    while task.wait(0.2) do
        pcall(runScan)
    end
end)
