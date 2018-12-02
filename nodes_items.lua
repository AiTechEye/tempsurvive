--[[
tempsurvive.register_clothe(name,{
	texture="",	-- required
	description="",	-- optional
	part="",		-- optional (arm/leg, chested/head, head, body)
	layer=1,		-- optional (texture layer)
	warming=1,	-- optional
	cooling=1,	-- optional
})


tempsurvive.register_cloth("name","hexcolor",craft-count-output,craft)


--]]

tempsurvive.register_cloth("white","ffffff",4,{{"wool:white"}})
tempsurvive.register_cloth("gray","777777",4,{{"wool:grey"}})
tempsurvive.register_cloth("darkgrey","333333",4,{{"wool:dark_grey"}})
tempsurvive.register_cloth("black","000000",4,{{"wool:black"}})
tempsurvive.register_cloth("lightgreen","00ff00",4,{{"wool:green"}})
tempsurvive.register_cloth("green","008800",4,{{"wool:dark_green"}})
tempsurvive.register_cloth("darkgreen","005500",8,{{"wool:dark_green","wool:black"}})
tempsurvive.register_cloth("yellow","ffff00",4,{{"wool:yellow"}})
tempsurvive.register_cloth("red","ff0000",4,{{"wool:red"}})
tempsurvive.register_cloth("darkred","770000",8,{{"wool:red","wool:black"}})
tempsurvive.register_cloth("brown","251700",4,{{"wool:brown"}})
tempsurvive.register_cloth("orange","ff4500",4,{{"wool:orange"}})
tempsurvive.register_cloth("pruple","9300ff",4,{{"wool:violet"}})
tempsurvive.register_cloth("pink","ff65b8",4,{{"wool:pink"}})
tempsurvive.register_cloth("cyan","00ffff",4,{{"wool:cyan"}})
tempsurvive.register_cloth("blue","0000ff",4,{{"wool:blue"}})
tempsurvive.register_cloth("lightblue","0081ff",8,{{"wool:blue","wool:white"}})
tempsurvive.register_cloth("darkblue","000044",4,{{"wool:blue","wool:black"}})

minetest.register_node("tempsurvive:fire", {
	tiles = {
		{
			name="fire_basic_flame_animated.png",
			animation={
				type="vertical_frames",
				aspect_w=16,
				aspect_h=16,
				length=1,
			}
		}
	},
	groups = {not_in_creative_inventory=1},
	drawtype="firelike",
	paramtype="light",
	light_source=13,
	sunlight_propagetes=true,
	drop="",
})

minetest.register_node("tempsurvive:cold_fire", {
	tiles = {
		{
			name="fire_basic_flame_animated.png^[colorize:#000055aa",
			animation={
				type="vertical_frames",
				aspect_w=16,
				aspect_h=16,
				length=1,
			}
		}
	},
	groups = {not_in_creative_inventory=1},
	drawtype="firelike",
	paramtype="light",
	light_source=13,
	sunlight_propagetes=true,
	drop="",
})

minetest.register_craft({
	output = "tempsurvive:stove",
	recipe = {
		{"default:stone_block","default:stone_block","default:stone_block"},
		{"","default:glass","default:stone_block"},
		{"default:stone_block","default:stone_block","default:stone_block"},
	}
})

minetest.register_node("tempsurvive:stove", {
	description = "stove",
	groups = {cracky=3,tempsurvive_temp_by_meta=1,tempsurvive_rad=15,tempsurvive=1},
	tiles={"tempsurvive_stove.png"},
	drawtype="mesh",
	mesh="tempsurvive_stove.obj",
	paramtype="light",
	paramtype2="facedir",
	paramtype2="facedir",
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 1.5, 0.5},
		}
	},
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 1.5, 0.5},
		}
	},
	on_timer = function (pos, elapsed)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local slot=meta:get_int("slot")
		local stack=inv:get_stack("burning",slot)
		local ind=slot

		if inv:get_stack("burning",slot):get_name()=="" then
			local slots={1,2,3,4,5,6,7,8,9,1,2,3,4,5,6,7,8,9}
			for i=slot,slot+9 do
				ind=i
				slot=slots[i]
				stack=inv:get_stack("burning",slot)
				if stack:get_count()>0 then
					break
				end
			end
		end

		local time=minetest.get_craft_result({method="fuel", width=1, items={stack:get_name()}}).time
		if time==0 then time=minetest.get_item_group(stack:get_name(),"flammable") end
		if time==0 then time=minetest.get_item_group(stack:get_name(),"igniter") end
		if time==0 then time=minetest.get_item_group(stack:get_name(),"tempsurvive_add") end

		meta:set_int("power",meta:get_int("power")+time)
		stack:set_count(stack:get_count()-1)
		inv:set_stack("burning",slot,stack)

		if time==0 then
			minetest.remove_node({x=pos.x,y=pos.y+1,z=pos.z})
			meta:set_int("temp",0)
			meta:set_int("power",0)
			return
		elseif math.abs(meta:get_int("temp"))<math.abs(meta:get_int("power")) then
			meta:set_int("temp",meta:get_int("power"))
		end

		if meta:get_int("power")>0 then
			minetest.set_node({x=pos.x,y=pos.y+1,z=pos.z},{name="tempsurvive:fire"})
		else
			minetest.set_node({x=pos.x,y=pos.y+1,z=pos.z},{name="tempsurvive:cold_fire"})
		end

		slot=slot+1
		if slot>9 or ind>=9 then
			slot=1
			meta:set_int("temp",meta:get_int("power"))
			meta:set_int("power",0)
		end
		meta:set_int("slot",slot)
		minetest.get_node_timer(pos):start(math.abs(time))
	end,
	on_construct=function(pos)


		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		meta:set_int("power", 0)
		meta:set_int("temp", 0)
		meta:set_int("slot", 1)
		inv:set_size("burning", 9)
		meta:set_string("formspec",
		"size[8,8]"
		.."list[current_name;burning;2.5,0;3,3;]"
		.."list[current_player;main;0,4;8,32;]"
		.."listring[current_player;main]"
		.."listring[current_name;burning]"
		)
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		local item=stack:get_name()
		local time=minetest.get_craft_result({method="fuel", width=1, items={item}}).time + minetest.get_item_group(item,"flammable") + minetest.get_item_group(item,"igniter") + minetest.get_item_group(stack:get_name(),"tempsurvive_add")
		if time==0 then
			return 0
		end
		if not minetest.get_node_timer(pos):is_started() then
			minetest.get_node_timer(pos):start(0.2)
		end
		return stack:get_count()
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		return 0
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,
	on_destruct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		minetest.remove_node({x=pos.x,y=pos.y+1,z=pos.z})
		for i=1,9 do
			minetest.add_item(pos, inv:get_stack("burning",i))
		end
	end,
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type=="node" then
			local pos=pointed_thing.above
			pos={x=pos.x,y=pos.y+1,z=pos.z}
			local n=minetest.registered_nodes[minetest.get_node(pos).name]
			if minetest.is_protected(pos,placer:get_player_name())==false and n and n.buildable_to then
				minetest.set_node({x=pos.x,y=pos.y-1,z=pos.z},{name="tempsurvive:stove"})
				itemstack:take_item()
			end
		end
		return itemstack
	end,
})

minetest.register_craftitem("tempsurvive:plank_with_stick", {
	description = "Plank with stick",
	inventory_image = "tempsurvive_plank_with_stick.png",
	groups = {wood=1,flammable=4},
	on_place = function(itemstack, user, pointed_thing)
		if pointed_thing.type=="node" and not minetest.is_protected(pointed_thing.above,user:get_player_name()) then
			itemstack:take_item()
			minetest.set_node(pointed_thing.above,{name="tempsurvive:keepable_fire"})
		end
		return itemstack
	end
})

minetest.register_craft({
	output = "tempsurvive:plank_with_stick 2",
	recipe = {
		{"group:wood","",""},
		{"","",""},
		{"","","group:stick"},
	}
})

minetest.register_node("tempsurvive:keepable_fire", {
	description = "Keepable fire",
	tiles = {
		{
			name="fire_basic_flame_animated.png",
			animation={
				type="vertical_frames",
				aspect_w=16,
				aspect_h=16,
				length=1,
			}
		}
	},
	groups = {dig_immediate=3,igniter=2,not_in_creative_inventory=1,tempsurvive_temp_by_meta=1,tempsurvive_rad=15,tempsurvive=1},
	drawtype="firelike",
	paramtype="light",
	light_source=12,
	walkable=false,
	sunlight_propagetes=true,
	damage_per_secound=5,
	drop="",
	on_timer = function (pos, elapsed)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		local slot=meta:get_int("slot")
		local stack=inv:get_stack("burning",slot)
		local ind=slot

		if inv:get_stack("burning",slot):get_name()=="" then
			local slots={1,2,3,4,5,6,7,8,9,1,2,3,4,5,6,7,8,9}
			for i=slot,slot+9 do
				ind=i
				slot=slots[i]
				stack=inv:get_stack("burning",slot)
				if stack:get_count()>0 then
					break
				end
			end
		end

		local time=minetest.get_craft_result({method="fuel", width=1, items={stack:get_name()}}).time
		if time==0 then time=minetest.get_item_group(stack:get_name(),"flammable") end
		if time==0 then time=minetest.get_item_group(stack:get_name(),"igniter") end
		if time==0 and stack:get_count()>0 and meta:get_int("slot")~=slot and meta:get_int("power")>0 then
			time=1
		end


		meta:set_int("power",meta:get_int("power")+time)
		stack:set_count(stack:get_count()-1)
		inv:set_stack("burning",slot,stack)

		if time==0 then
			minetest.remove_node(pos)
			return
		elseif meta:get_int("temp")<meta:get_int("power") then
			meta:set_int("temp",meta:get_int("power"))
		end
		slot=slot+1
		if slot>9 or ind>=9 then
			slot=1
			meta:set_int("temp",meta:get_int("power"))
			meta:set_int("power",0)
		end
		meta:set_int("slot",slot)
		minetest.get_node_timer(pos):start(time)
	end,

	on_construct=function(pos)
		minetest.get_node_timer(pos):start(math.random(5,10))
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		meta:set_int("power", 0)
		meta:set_int("temp", 0)
		meta:set_int("slot", 1)
		inv:set_size("burning", 9)
		meta:set_string("formspec",
		"size[8,8]"
		.."list[current_name;burning;2.5,0;3,3;]"
		.."list[current_player;main;0,4;8,32;]"
		.."listring[current_player;main]"
		.."listring[current_name;burning]"
		)
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		return stack:get_count()
	end,
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		return 0
	end,
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,
	on_destruct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		for i=1,9 do
			minetest.add_item(pos, inv:get_stack("burning",i))
		end
	end,
})

minetest.register_node("tempsurvive:clothes_bag", {
	description = "Clothes bag",
	tiles = {"tempsurvive_bag.png"},
	groups = {dig_immediate=3},
	drawtype="nodebox",
	paramtype="light",
	paramtype2="facedir",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.3125, 0.5, 0.0625, 0.375},
			{-0.5, 0.0625, -0.25, 0.5, 0.125, 0.3125}
		}
	},
	on_use=function(itemstack, user, pointed_thing)
		local w,c=0,0
		local inv=user:get_inventory()
		for i=1,9,1 do
			local name=inv:get_stack("clothes",i):get_name()
			local a=tempsurvive.clothes[name]
			if a then
				c=c+a.cooling
				w=w+a.warming
			end
		end

		local gui="size[8,8]"
		.."list[current_player;clothes;2.5,0;3,3;]"
		.."list[current_player;main;0,4;8,32;]"
		.."listring[current_player;main]"
		.."listring[current_player;clothes]"
		.."label[0,0;Warming: " .. w .."\nCooling: " .. c .."]"
		minetest.after(0.1, function(gui)
			return minetest.show_formspec(user:get_player_name(), "tempsurvive.bag",gui)
		end, gui)
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		minetest.registered_nodes["tempsurvive:clothes_bag"].on_use(1,player)
	end,
})

minetest.register_craft({
	output = "tempsurvive:clothes_bag",
	recipe = {
		{"group:wool","group:tempsurvive_cloths","group:wool"},
	}
})
minetest.register_craft({
	type = "fuel",
	recipe = "tempsurvive:clothes_bag",
	burntime = 4
})

minetest.register_node("tempsurvive:thermometer", {
	description = "Thermometer",
	tiles = {"tempsurvive_thermometer.png"},
	inventory_image="tempsurvive_thermometer_item.png",
	wield_image="tempsurvive_thermometer_item.png",
	liquids_pointable=true,
	groups = {dig_immediate=3},
	drawtype="nodebox",
	paramtype="light",
	paramtype2="facedir",
	walkable=false,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.1, -0.25, 0.43, 0.1, 0.25, 0.5}
		}
	},
	on_use=function(itemstack, user, pointed_thing)
		local pos=pointed_thing.above or user:get_pos()
		local temp=tempsurvive.get_bio_temperature(pos)
		temp=tempsurvive.get_artificial_temperature(pos,temp)
		minetest.chat_send_player(user:get_player_name(), math.floor(temp*10)*0.1)
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("infotext", math.floor(tempsurvive.get_bio_temperature(pos)*10)*0.1)
		minetest.get_node_timer(pos):start(2)
	end,
	on_timer = function (pos, elapsed)
		local meta=minetest.get_meta(pos)
		local temp=tempsurvive.get_bio_temperature(pos)
		temp=tempsurvive.get_artificial_temperature(pos,temp)
		meta:set_string("infotext", math.floor(temp*10)*0.1)
		return true
	end,
})

minetest.register_craft({
	output = "tempsurvive:thermometer",
	recipe = {
		{"","default:bronze_ingot",""},
		{"","default:wood",""},
		{"","default:glass",""},
	}
})

tempsurvive.register_clothe("leather_gloves",{
	description="Leather Gloves",
	texture="tempsurvive_gloves.png",
	part="arm",
	layer=9,
	craft={
		{"tempsurvive:cloth_brown","","tempsurvive:cloth_brown"},
		{"tempsurvive:cloth_brown","","tempsurvive:cloth_brown"},
		{"","",""},
	},
})
tempsurvive.register_clothe("leather_shoes",{
	description="Leather Shoes",
	texture="tempsurvive_shoes.png",
	part="leg",
	layer=9,
	craft={
		{"","",""},
		{"tempsurvive:cloth_brown","","tempsurvive:cloth_brown"},
		{"tempsurvive:cloth_brown","","tempsurvive:cloth_brown"},
	},
})
tempsurvive.register_clothe("shirt",{
	description="Red Shirt",
	texture="tempsurvive_shirt.png",
	part="chested",
	layer=1,
	warming=1,
	craft={
		{"tempsurvive:cloth_red","tempsurvive:cloth_red","tempsurvive:cloth_red"},
		{"","",""},
		{"","",""},
	},
})
tempsurvive.register_clothe("sweatshirt",{
	description="Orange Sweatshirt",
	texture="tempsurvive_sweatshirt.png",
	part="chested",
	layer=2,
	craft={
		{"tempsurvive:cloth_orange","tempsurvive:cloth_orange","tempsurvive:cloth_orange"},
		{"","tempsurvive:cloth_orange",""},
		{"","tempsurvive:cloth_orange",""},
	}
})

tempsurvive.register_clothe("brown_woolhat",{
	description="Brown Woolhat",
	texture="tempsurvive_brownwollhat.png",
	part="head",
	layer=2,
	craft={
		{"tempsurvive:cloth_brown","tempsurvive:cloth_brown","tempsurvive:cloth_brown"},
		{"tempsurvive:cloth_brown","","tempsurvive:cloth_brown"},
	}
})

tempsurvive.register_clothe("lightblue_overall",{
	description="Lightblue Overall",
	texture="tempsurvive_lightblueoverall.png",
	part="body",
	warming=10,
	layer=8,
	craft={
		{"tempsurvive:cloth_lightblue","tempsurvive:cloth_lightblue","tempsurvive:cloth_lightblue"},
		{"tempsurvive:cloth_lightblue","tempsurvive:cloth_darkblue","tempsurvive:cloth_lightblue"},
		{"tempsurvive:cloth_lightblue","wool:blue","tempsurvive:cloth_lightblue"},
	}
})