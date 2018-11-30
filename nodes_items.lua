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
		local a=minetest.find_nodes_in_area({x=pos.x-3, y=pos.y-3, z=pos.z-3}, {x=pos.x+3, y=pos.y+3, z=pos.z+3}, {"group:tempsurvive"})
		for i,no in pairs(a) do
			local name=minetest.get_node(no).name
			temp=temp+tempsurvive.spread_temperature(
				pos,
				no,
				minetest.get_item_group(name,"tempsurvive_add"),
				minetest.get_item_group(name,"tempsurvive_rad")
			)
		end
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
		local a=minetest.find_nodes_in_area({x=pos.x-3, y=pos.y-3, z=pos.z-3}, {x=pos.x+3, y=pos.y+3, z=pos.z+3}, {"group:tempsurvive"})

		for i,no in pairs(a) do
			local name=minetest.get_node(no).name
			temp=temp+tempsurvive.spread_temperature(
				pos,
				no,
				minetest.get_item_group(name,"tempsurvive_add"),
				minetest.get_item_group(name,"tempsurvive_rad")
			)
		end
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