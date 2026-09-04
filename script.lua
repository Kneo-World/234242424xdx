local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

print("==================================================")
print("=== [DEEP STORAGE SCANNER & REAL MESH FINDER] ===")
print("==================================================")

-- 1. СКАНИРУЕМ ВСЕ МОДЕЛИ И МЕШИ В REPLICATEDSTORAGE
print("\n>>> [1] Сканирование ReplicatedStorage на наличие оружия...")
local foundModels = {}

for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
    local nameLower = obj.Name:lower()
    if nameLower:find("icebreaker") or nameLower:find("harvester") or nameLower:find("knife") or nameLower:find("gun") then
        if obj:IsA("Model") or obj:IsA("MeshPart") or obj:IsA("Tool") then
            table.insert(foundModels, {
                Name = obj.Name,
                Class = obj.ClassName,
                Path = obj:GetFullName()
            })
        end
    end
end

if #foundModels > 0 then
    print(string.format("Найдено совпадений: %d", #foundModels))
    for i, item in ipairs(foundModels) do
        print(string.format(" [%d] %-20s | Class: %-10s | Path: %s", i, item.Name, item.Class, item.Path))
    end
else
    print("[WARN] В ReplicatedStorage не найдено ни одной модели по ключевым словам!")
end

-- 2. ПРОВЕРЯЕМ ТЕКУЩИЙ MESH В РУКАХ И ЕГО СВОЙСТВА
local function inspectCurrentWeapon()
    print("\n>>> [2] Проверка оружия в Backpack и Character...")
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")

    local containers = {["Backpack"] = backpack, ["Character"] = char}

    for cName, container in pairs(containers) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    print(string.format("\n[TOOL FOUND] Контейнер: %s | Имя: %s", cName, tool.Name))
                    
                    for _, desc in ipairs(tool:GetDescendants()) do
                        if desc:IsA("SpecialMesh") or desc:IsA("DataModelMesh") then
                            print("   └─ SpecialMesh:")
                            print("      ├─ MeshId:", desc.MeshId)
                            print("      ├─ TextureId:", desc.TextureId)
                            print("      └─ Scale:", tostring(desc.Scale))
                        elseif desc:IsA("MeshPart") then
                            print("   └─ MeshPart:")
                            print("      ├─ MeshId:", desc.MeshId)
                            print("      └─ TextureID:", desc.TextureID)
                        end
                    end
                end
            end
        end
    end
end

inspectCurrentWeapon()

-- 3. ПОПЫТКА БЕЗОПАСНОЙ ПОДМЕНЫ С ЛОГИРОВАНИЕМ
print("\n>>> [3] Проверка заблокированных ID...")
local testMesh = Instance.new("SpecialMesh")
testMesh.MeshId = "rbxassetid://4738598711"

print("Тестовый MeshId установлен:", testMesh.MeshId)
if testMesh.MeshId == "" then
    print("[X] ОШИБКА: Roblox заблокировал этот MeshId (пустая строка)!")
else
    print("[✓] MeshId принят движком, но если модели нет — ID не является raw-мешем.")
end
