local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

print("=== [SKIN CHANGER] Глубокое сканирование и подмена ===")

-- База данных скинов (MeshId и TextureId)
local WeaponDatabase = {
    ["Icebreaker"] = {MeshId = "rbxassetid://6022874136", TextureId = "rbxassetid://6022874251"},
    ["Harvester"] = {MeshId = "rbxassetid://7800847534", TextureId = "rbxassetid://7800847683"},
    ["Icepiercer"] = {MeshId = "rbxassetid://11834434264", TextureId = "rbxassetid://11834434400"},
    ["Bat"] = {MeshId = "rbxassetid://11229779932", TextureId = "rbxassetid://11229780100"},
    ["Corrupt"] = {MeshId = "rbxassetid://197879343", TextureId = "rbxassetid://197879357"},
    ["Nikilis"] = {MeshId = "rbxassetid://3184125538", TextureId = "rbxassetid://3184125700"},
    ["Lugercane"] = {MeshId = "rbxassetid://4488391411", TextureId = "rbxassetid://4488391550"},
    ["ChromaLuger"] = {MeshId = "rbxassetid://332044679", TextureId = "rbxassetid://332044810"},
    ["Pixel"] = {MeshId = "rbxassetid://235381341", TextureId = "rbxassetid://235381480"},
    ["Slasher"] = {MeshId = "rbxassetid://3187392501", TextureId = "rbxassetid://3187392650"},
    ["Bioblade"] = {MeshId = "rbxassetid://4659627458", TextureId = "rbxassetid://4659627600"},
    ["Prismatic"] = {MeshId = "rbxassetid://5360359935", TextureId = "rbxassetid://5360360080"},
    ["Db"] = {MeshId = "rbxassetid://4749071819", TextureId = "rbxassetid://4749071980"}
}

-- 1. Попытка взлома ProfileData через require
local ProfileDataModule = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ProfileData")
local RawProfile = require(ProfileDataModule)

local TargetData = nil
if type(RawProfile) == "table" then
    TargetData = RawProfile
elseif type(RawProfile) == "function" then
    pcall(function() TargetData = RawProfile(LocalPlayer) end)
end

-- Поиск нужной вложенной таблицы инвентаря
local function findWeaponsTable(tbl)
    if type(tbl) ~= "table" then return nil end
    if tbl.Owned and type(tbl.Owned) == "table" then return tbl.Owned end
    if tbl.Weapons and type(tbl.Weapons) == "table" then return findWeaponsTable(tbl.Weapons) end
    for _, v in pairs(tbl) do
        if type(v) == "table" and v.Owned then
            return v.Owned
        end
    end
    return nil
end

local ownedTable = findWeaponsTable(TargetData)

if ownedTable then
    print("[SUCCESS] Инвентарь найден в ProfileData! Наполняем...")
    for skinID in pairs(WeaponDatabase) do
        ownedTable[skinID] = (ownedTable[skinID] or 0) + 1
    end
    
    -- Перерисуем GUI MM2
    local successInv, InvModule = pcall(function() 
        return require(ReplicatedStorage.Modules.InventoryModule) 
    end)
    if successInv and InvModule and InvModule.MyInventory then
        pcall(function()
            InvModule.MyInventory = InvModule.GenerateInventory(InvModule.GUI.MyInventory, TargetData, "Main")
            InvModule.SortInventory(InvModule.MyInventory)
            InvModule.ConnectEquipButtons()
            print("[OK] GUI инвентаря перезагружен!")
        end)
    end
else
    print("[WARN] Не удалось внедрить скины в ProfileData. Включаем прямой визуальный режим!")
end

-- 2. Функция подмены 3D-меша
local function applyMeshToPart(part, data)
    if not part or not data then return end

    if part:IsA("MeshPart") then
        part.MeshId = data.MeshId
        if data.TextureId then part.TextureID = data.TextureId end
        return
    end

    local innerMesh = part:FindFirstChild("Mesh") 
        or part:FindFirstChildOfClass("SpecialMesh") 
        or part:FindFirstChildWhichIsA("DataModelMesh")

    if innerMesh then
        innerMesh.MeshId = data.MeshId
        if data.TextureId then innerMesh.TextureId = data.TextureId end
    else
        local newMesh = Instance.new("SpecialMesh")
        newMesh.Name = "Mesh"
        newMesh.MeshId = data.MeshId
        if data.TextureId then newMesh.TextureId = data.TextureId end
        newMesh.Parent = part
    end
end

-- Проверка привязки дисплея на теле к твоему игроку
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

-- Выбери скины по умолчанию для ножа и песта (если инвентарь игры их не сменил)
local SELECTED_KNIFE = "Icebreaker"
local SELECTED_GUN = "Harvester"

local function refreshVisuals()
    local char = LocalPlayer.Character
    if not char then return end

    local knifeData = WeaponDatabase[SELECTED_KNIFE]
    local gunData = WeaponDatabase[SELECTED_GUN]

    -- Обновляем предметы в Backpack и руках
    local containers = {LocalPlayer:FindFirstChild("Backpack"), char}
    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    local isKnife = item.Name:find("Knife") or item:FindFirstChild("Knife")
                    local isGun = item.Name:find("Gun") or item:FindFirstChild("Gun")
                    local data = isKnife and knifeData or (isGun and gunData or nil)

                    if data then
                        item.TextureId = data.TextureId or data.MeshId
                        
                        local handle = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
                        if handle then
                            applyMeshToPart(handle, data)
                        end
                    end
                end
            end
        end
    end

    -- Обновляем предметы на теле
    local weaponDisplaysFolder = Workspace:FindFirstChild("WeaponDisplays")
    if weaponDisplaysFolder then
        for _, display in ipairs(weaponDisplaysFolder:GetChildren()) do
            if isMyDisplay(display) then
                if display.Name:find("Knife") and knifeData then
                    applyMeshToPart(display, knifeData)
                elseif display.Name:find("Gun") and gunData then
                    applyMeshToPart(display, gunData)
                end
            end
        end
    end
end

-- Постоянный цикл визуальной подмены
task.spawn(function()
    while task.wait(0.3) do
        refreshVisuals()
    end
end)
