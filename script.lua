local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")

local LocalPlayer = Players.LocalPlayer

print("=== [MM2 SMART SKIN CHANGER] ===")

-- Настройки скинов
local SKINS = {
    Knife = {
        Name = "Icebreaker",
        MeshId = "rbxassetid://4738598711",
        TextureId = "rbxassetid://4738598920",
        Scale = Vector3.new(1, 1, 1)
    },
    Gun = {
        Name = "Harvester",
        MeshId = "rbxassetid://7800847534",
        TextureId = "rbxassetid://7800847683",
        Scale = Vector3.new(1, 1, 1)
    }
}

local function applySkinToTool(tool, skinData)
    if not tool or not tool:IsA("Tool") then return end
    
    local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart", true)
    if not handle then return end

    -- Меняем иконку в инвентаре
    if skinData.TextureId then
        tool.TextureId = skinData.TextureId
    end

    -- Ищем или создаем SpecialMesh
    local mesh = handle:FindFirstChildOfClass("SpecialMesh")
    if not mesh then
        mesh = Instance.new("SpecialMesh")
        mesh.Name = "SkinMesh"
        mesh.Parent = handle
    end

    -- Принудительно ставим MeshId и TextureId
    if mesh.MeshId ~= skinData.MeshId then
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = skinData.MeshId
        mesh.TextureId = skinData.TextureId or ""
        mesh.Scale = skinData.Scale
        print(string.format("[✓ SUCCESS] Скин %s успешно применен к %s!", skinData.Name, tool.Name))
    end
end

local function scanAndApply()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")

    local containers = {backpack, char}
    for _, container in ipairs(containers) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    local name = item.Name:lower()
                    if name:find("knife") or item:FindFirstChild("Knife") or name == "defaultknife" then
                        applySkinToTool(item, SKINS.Knife)
                    elseif name:find("gun") or item:FindFirstChild("Gun") or name == "defaultgun" then
                        applySkinToTool(item, SKINS.Gun)
                    end
                end
            end
        end
    end
end

-- Автоматическое отслеживание взятия в руки
if LocalPlayer.Character then
    LocalPlayer.Character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            task.wait(0.05)
            scanAndApply()
        end
    end)
end

-- Фоновый цикл проверки
task.spawn(function()
    while task.wait(0.3) do
        pcall(scanAndApply)
    end
end)
