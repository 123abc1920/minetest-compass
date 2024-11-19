local store = minetest.get_mod_storage()
points = minetest.deserialize(store:get_string("compasses")) or {}

local save = function()
    store:set_string("compasses", minetest.serialize(points))
end

minetest.register_on_shutdown(save)
minetest.register_on_leaveplayer(save)

minetest.register_node("compass:home_block", {
    description = "Home Point",
    tiles = { "home_block_side.png", "home_block_side.png",
        "home_block_side_first.png", "home_block_side_first.png",
        "home_block_side_first.png", "home_block_side_first.png" },
    walkable = true,
    waving = 1,
    groups = { snappy = 3, flammable = 2, cracky = 3 },
    drop = "compass:home_block",

    on_construct = function(pos)
        table.insert(points, { name = "", pos = { pos.x, pos.y, pos.z } })
        local meta = minetest.get_meta(pos)
        meta:set_string("formspec", "field[text;;${text}]")
    end,
    on_receive_fields = function(pos, formname, fields, sender)
        local player_name = sender:get_player_name()
        if minetest.is_protected(pos, player_name) then
            minetest.record_protection_violation(pos, player_name)
            return
        end
        local text = fields.text
        if not text then
            return
        end
        if string.len(text) > 512 then
            minetest.chat_send_player(player_name, S("Text too long"))
            return
        end
        default.log_player_action(sender, "wrote \"" .. text ..
            "\" to the sign at", pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("text", text)

        -- set name of point
        for _, v in ipairs(points) do
            if pos.x == v.pos[1] then
                if pos.y == v.pos[2] then
                    if pos.z == v.pos[3] then
                        v.name = text
                    end
                end
            end
        end
        -- end of set

        if #text > 0 then
            meta:set_string("infotext", S('"@1"', text))
        else
            meta:set_string("infotext", '')
        end
    end,
    on_destruct = function(pos)
        local a
        for i, v in ipairs(points) do
            if pos.x == v.pos[1] then
                if pos.y == v.pos[2] then
                    if pos.z == v.pos[3] then
                        a = i
                        break
                    end
                end
            end
        end
        table.remove(points, a)
    end
})

minetest.register_craft({
    type = "shaped",
    output = "compass:home_block",
    recipe = { { "default:dirt", "default:dirt", "default:dirt" },
        { "default:dirt", "",             "default:dirt" },
        { "default:dirt", "default:dirt", "default:dirt" } }
})

--compasses

local findAbs       = function(p)
    return math.sqrt(p[1] * p[1] + p[2] * p[2])
end

local findAB        = function(a, b)
    return a[1] * b[1] + a[2] * b[2]
end

local leftRight     = function(a, m, b)
    local x = { b[1] - m[1], b[2] - m[2] }
    if a[1] * x[2] - a[2] * x[1] > 0 then
        return true
    else
        return false
    end
end

local compassImg    = function(user, tool)
    local p = user:get_pos()
    local name = tool:get_meta():get_string("the_node")
    for _, v in ipairs(points) do
        if v.name == name then
            local x = v.pos[1]
            local y = v.pos[3]
            local a = p.x
            local b = p.z

            local vec1 = { user:get_look_dir().x, user:get_look_dir().z }
            local vec2 = { x - a, y - b }
            local alpha = math.acos(findAB(vec1, vec2) / (findAbs(vec1) * findAbs(vec2)))
            alpha = (alpha * 180) / math.pi

            local bool = leftRight({ user:get_look_dir().x, user:get_look_dir().z }, { a, b }, { x, y })
            if alpha >= 0 and alpha < 22.5 then
                user:set_wielded_item("compass:compass_item_1")
            end
            if alpha >= 22.5 and alpha < 67.5 then
                if bool then
                    user:set_wielded_item("compass:compass_item_8")
                else
                    user:set_wielded_item("compass:compass_item_2")
                end
            end
            if alpha >= 67.5 and alpha < 112.5 then
                if bool then
                    user:set_wielded_item("compass:compass_item_7")
                else
                    user:set_wielded_item("compass:compass_item_3")
                end
            end
            if alpha >= 112.5 and alpha < 157.5 then
                if bool then
                    user:set_wielded_item("compass:compass_item_6")
                else
                    user:set_wielded_item("compass:compass_item_4")
                end
            end
            if alpha >= 157.5 and alpha <= 180 then
                user:set_wielded_item("compass:compass_item_5")
            end

            local next_tool = user:get_wielded_item()
            local next_tool_meta = next_tool:get_meta()
            next_tool_meta:set_string("description", "Compass to " .. name)
            next_tool_meta:set_string("the_node", name)
            user:set_wielded_item(next_tool)

            break
        end
    end
end

local changeCompass = function(stack, user, point)
    local tool = user:get_wielded_item()
    local meta = tool:get_meta()

    if point.above == nil then
        compassImg(user, tool)
        return
    end
    local node = minetest.find_node_near(point.above, 2, { "compass:home_block" })
    if node then
        for _, v in ipairs(points) do
            if v.pos[1] == node.x then
                if v.pos[2] == node.y then
                    if v.pos[3] == node.z then
                        meta:set_string("description", "Compass to " .. v.name)
                        meta:set_string("the_node", v.name)
                        break
                    end
                end
            end
        end
        user:set_wielded_item(tool)
    else
        compassImg(user, tool)
    end
end

for i = 1, 8 do
    minetest.register_tool("compass:compass_item_" .. i, {
        description = "Compass",
        inventory_image = "compass_item_" .. i .. ".png",
        on_use = function(stack, user, point)
            changeCompass(stack, user, point)
        end
    })
end

minetest.register_craft({
    type = "shaped",
    output = "compass:compass_item_1",
    recipe = { { "",  "default:dirt", "" },
        { "default:dirt", "",             "default:dirt" },
        { "",             "default:dirt", "" } }
})
