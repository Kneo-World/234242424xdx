local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

print("==========================================")
print("=== [DEEP DEBUGGER & MESH REPLACER] ===")
print("==========================================")

-- Данные скинов для подмены
local TARGET_SKINS = {
    Knife = {
        Name = "Icebreaker",
        MeshId = "rbxassetid://6022874136",
        TextureId = "rbxassetid://6022874251"
    },
    Gun = {
        Name = "Harvester",
        MeshId = "rbxassetid://7800847534",
        TextureId = "rbxassetid://7800847683"
    }
}

-- Функция полного логирования структуры объекта
local function debugAndReplace(toolObj, skinData, category)
    print("\n--- [АНАЛИЗ ПРЕДМЕТА]:", toolObj.Name, "(" .. category .. ") ---")
    print("Путь к предмету:", toolObj:GetFullName())

    -- Меняем иконку у самого Tool
    if toolObj:IsA("Tool") then
        print("[Tool] Исходная TextureId:", toolObj.TextureId)
        toolObj.TextureId = skinData.TextureId
        print("[Tool] Новая TextureId установлена:", toolObj.TextureId)
    end

    local descendants = toolObj:GetDescendants()
    print("Всего под-объектов внутри:", #descendants)

    local foundMesh = false

    for i, child in ipairs(descendants) do
        print(string.format(" [%d] Класс: %-15s | Имя: %-15s | Путь: %s", i, child.ClassName, child.Name, child:GetFullName()))

        -- 1. Если это MeshPart
        if child:IsA("MeshPart") then
            foundMesh = true
            print("   -> Найден MeshPart!")
            print("      Старый MeshId:", child.MeshId)
            print("      Старая TextureID:", child.TextureID)

            local success, err = pcall(function()
                child.MeshId = skinData.MeshId
                child.TextureID = skinData.TextureId
            end)

            if success then
                print("   [✓] УСПЕШНО изменен MeshPart на:", skinData.Name)
            else
                print("   [X] ОШИБКА записи в MeshPart (возможно, заблокировано во время игры):", err)
            end

        -- 2. Если это SpecialMesh / DataModelMesh
        elseif child:IsA("SpecialMesh") or child:IsA("DataModelMesh") then
            foundMesh = true
            print("   -> Найден внутренний " .. child.ClassName .. "!")
            print("      Старый MeshId:", child.MeshId)
            print("      Старая TextureId:", child.TextureId)

            local success, err = pcall(function()
                child.MeshId = skinData.MeshId
                child.TextureId = skinData.TextureId
            end)

            if success then
                print("   [✓] УСПЕШНО изменен " .. child.ClassName .. " на:", skinData.Name)
            else
                print("   [X] ОШИБКА записи в " .. child.ClassName .. ":", err)
            end
        end
    end

    -- 3. Если мешей вообще не нашли, пробуем вставить в Handle
    if not foundMesh then
        print("[WARN] Внутри объекта не найдено ни одного меша! Ищем Handle...")
        local handle = toolObj:FindFirstChild("Handle") or toolObj:FindFirstChildWhichIsA("BasePart", true)
        
        if handle then
            print(" -> Handle найден (" .. handle.ClassName .. "), создаем новый SpecialMesh...")
            local newMesh = Instance.new("SpecialMesh")
            newMesh.Name = "ClientSkinMesh"
            newMesh.MeshId = skinData.MeshId
            newMesh.TextureId = skinData.TextureId
            newMesh.Parent = handle
            print("   [✓] УСПЕШНО создан и прикреплен новый SpecialMesh!")
        else
            print("   [X] КРИТИЧЕСКАЯ ОШИБКА: У объекта нет даже Handle/BasePart!")
        end
    end
end

-- Проверка привязки дисплея на теле
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

-- Сканирование персонажа и инвентаря
local function runFullScan()
    local char = LocalPlayer.Character
    if not char then 
        print("[WARN] Персонаж не найден в Workspace")
        return 
    end

    print("\n==========================================")
    print("=== ЗАПУСК СКАНИРОВАНИЯ (F9 LOGS) ===")
    print("==========================================")

    -- Сканируем Backpack и Character
    local containers = {
        ["Backpack"] = LocalPlayer:FindFirstChild("Backpack"),
        ["Character"] = char
    }

    for cName, container in pairs(containers) do
        if container then
            print("\n>>> Проверка контейнера:", cName)
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    local nameLower = item.Name:lower()
                    if nameLower:find("knife") or item:FindFirstChild("Knife") then
                        debugAndReplace(item, TARGET_SKINS.Knife, "Knife Tool")
                    elseif nameLower:find("gun") or item:FindFirstChild("Gun") then
                        debugAndReplace(item, TARGET_SKINS.Gun, "Gun Tool")
                    else
                        print(" -> Найден сторонний Tool (не нож и не пест):", item.Name)
                    end
                end
            end
        end
    end

    -- Сканируем WeaponDisplays на спине
    local weaponDisplaysFolder = Workspace:FindFirstChild("WeaponDisplays")
    if weaponDisplaysFolder then
        print("\n>>> Проверка папки Workspace.WeaponDisplays...")
        for _, display in ipairs(weaponDisplaysFolder:GetChildren()) do
            if isMyDisplay(display) then
                local nameLower = display.Name:lower()
                if nameLower:find("knife") then
                    debugAndReplace(display, TARGET_SKINS.Knife, "Knife Display")
                elseif nameLower:find("gun") then
                    debugAndReplace(display, TARGET_SKINS.Gun, "Gun Display")
                end
            end
        end
    else
        print("[INFO] Папка Workspace.WeaponDisplays отсутствует")
    end
end

-- Одноразовый запуск с полной детализацией
runFullScan()

-- Отслеживание экипировки (когда берешь нож в руки)
if LocalPlayer.Character then
    LocalPlayer.Character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.1)
            print("\n[EVENT] Предмет взят в руки:", child.Name)
            runFullScan()
        end
    end)
end
