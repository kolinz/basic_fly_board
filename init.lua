local modpath = minetest.get_modpath("basic_fly_board")
local conf = dofile(modpath .. "/mod.lua")  -- mod.lua にエンティティ定義あり

for name, relpath in pairs(conf.entities or {}) do
    local fullpath = modpath .. "/" .. relpath
    local ok, err = pcall(dofile, fullpath)
    if not ok then
        minetest.log("error", "[basic_fly_board] Failed to load " .. relpath .. ": " .. err)
    end
end

minetest.register_craftitem("basic_fly_board:board_spawner", {
    description = "Board Spawner",
    inventory_image = "board_spawner.png",
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then return itemstack end  -- 修正ポイント

        local pos = pointed_thing.above
        local obj = minetest.add_entity(pos, "basic_fly_board:board")
        if obj and placer then
            obj:set_yaw(placer:get_look_horizontal())
        end

        if not minetest.settings:get_bool("creative_mode") then
            itemstack:take_item()
        end
        return itemstack
    end,
})