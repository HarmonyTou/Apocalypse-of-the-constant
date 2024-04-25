local RegisterInventoryItemAtlas = RegisterInventoryItemAtlas
local resolvefilepath = resolvefilepath

local function RegisterImageAtlas(atlas_path)
    local atlas = resolvefilepath(atlas_path)

    local file = io.open(atlas, "r")
    local data = file:read("*all")
    file:close()

    local str = string.gsub(data, "%s+", "")
    local _, _, elements = string.find(str, "<Elements>(.-)</Elements>")

    for s in string.gmatch(elements, "<Element(.-)/>") do
        local _, _, image = string.find(s, "name=\"(.-)\"")
        if image ~= nil then
            RegisterInventoryItemAtlas(atlas, image)
            RegisterInventoryItemAtlas(atlas, hash(image)) -- for client
        end
    end
end

return {
    RegisterImageAtlas = RegisterImageAtlas,
}