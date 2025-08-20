minetest.register_entity("basic_fly_board:board", {
    initial_properties = {
        physical = true,
        collide_with_objects = true,
        collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
        visual = "cube",
        textures = {
            "default_wood.png", "default_wood.png", "default_wood.png",
            "default_wood.png", "default_wood.png", "default_wood.png"
        },
    },

    driver = nil,
    speed = 0,
    max_speed = 2.0,
    accel = 0.1,
    float_height = 1.5,

    on_activate = function(self, staticdata, dtime_s)
        self.object:set_velocity({x=0, y=0, z=0})
    end,

    on_rightclick = function(self, clicker)
        if not self.driver then
            self.driver = clicker
            clicker:set_attach(self.object, "", {x=0, y=5, z=0}, {x=0, y=0, z=0})
        else
            self.driver:set_detach()
            self.driver = nil
        end
    end,

    on_step = function(self, dtime)
        if not self.driver then return end

        local look_yaw = self.driver:get_look_horizontal()
        self.object:set_yaw(look_yaw)

        local forward = {x = -math.sin(look_yaw), z = math.cos(look_yaw)}
        local right   = {x = math.cos(look_yaw), z = math.sin(look_yaw)}

        local ctrl = self.driver:get_player_control()
        local dir = {x = 0, z = 0}
        if ctrl.up then
            dir.x = dir.x + forward.x
            dir.z = dir.z + forward.z
        end
        if ctrl.down then
            dir.x = dir.x - forward.x
            dir.z = dir.z - forward.z
        end
        if ctrl.right then
            dir.x = dir.x + right.x
            dir.z = dir.z + right.z
        end
        if ctrl.left then
            dir.x = dir.x - right.x
            dir.z = dir.z - right.z
        end

        local len = math.sqrt(dir.x^2 + dir.z^2)
        if len > 0 then
            dir.x = dir.x / len
            dir.z = dir.z / len
            self.speed = math.min(self.speed + self.accel, self.max_speed)
        else
            self.speed = self.speed * 0.95
        end

        local vel_x = dir.x * self.speed
        local vel_z = dir.z * self.speed

        local pos = self.object:get_pos()
        local ground_y = pos.y
        for y = pos.y, pos.y - 5, -0.1 do
            local node = minetest.get_node({x=pos.x, y=y, z=pos.z})
            if node.name ~= "air" then
                ground_y = y
                break
            end
        end
        local target_y = ground_y + self.float_height
        local dy = (target_y - pos.y) * 0.2

        self.object:set_velocity({x = vel_x, y = dy, z = vel_z})
    end
})

-- 高度調整GUIコマンド
minetest.register_chatcommand("flyboard_gui", {
    description = "高度調整GUIを開く",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return end

        local formspec = "formspec_version[4]" ..
                         "size[6,3]" ..
                         "label[0.5,0.5;高度調整]" ..
                         "button[1,1;2,1;up;↑ 上昇]" ..
                         "button[3,1;2,1;down;↓ 下降]"

        minetest.show_formspec(name, "basic_fly_board:altitude_gui", formspec)
    end
})

-- GUI入力処理
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "basic_fly_board:altitude_gui" then return end
    local name = player:get_player_name()

    for _, obj in pairs(minetest.get_objects_inside_radius(player:get_pos(), 5)) do
        local ent = obj:get_luaentity()
        if ent and ent.name == "basic_fly_board:board" and ent.driver == player then
            local pos = ent.object:get_pos()
            if fields.up then
                ent.object:set_pos({x = pos.x, y = pos.y + 1, z = pos.z})
            elseif fields.down then
                ent.object:set_pos({x = pos.x, y = pos.y - 1, z = pos.z})
            end
            return
        end
    end
end)