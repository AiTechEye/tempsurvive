tempsurvive={
	speed=0.01,
	step_timer=0,
	step_time=1,
	player={},
	armor=minetest.get_modpath("3d_armor"),
	perlin={
		offset=50,
		scale=50,
		spread={x=1000,y=1000,z=1000},
		seed=5349,
		octaves=3,
		persist=0.5,
		lacunarity=2,
		flags="default"
	},
	bar={
		hud_elem_type="statbar",
		position={x=0.5,y=1.025},
		text="tempsurvive_bar.png",
		number=40,
		size={x=24,y=4},
		direction=0,
		offset={x=-244, y=-88},
	},
	clothes={},
	screen={
		hud_elem_type = "image",
		text ="tempsurvive_screen.png",
		scale = {x=-100, y=-100},
		alignment = {x=1, y=1},
	},
	nodes={
		["snowy"]={add=-1,rad=2},
		["puts_out_fire"]={add=-2,rad=3},
		["water"]={add=-10,rad=0},
		["torch"]={add=5,rad=5},
		["igniter"]={add=15,rad=5},
		["default:furnace_active"]={add=10,rad=10},
	}
}

dofile(minetest.get_modpath("tempsurvive") .. "/functions.lua")
dofile(minetest.get_modpath("tempsurvive") .. "/nodes_items.lua")

minetest.register_on_mods_loaded(function()
	local groups_to_change={}
	for i,v in pairs(tempsurvive.nodes) do
		if string.find(i,":")==nil then
			groups_to_change[i]=v
		elseif minetest.registered_nodes[i] then
			local group=table.copy(minetest.registered_nodes[i].groups or {})
			group.tempsurvive=1
			group.tempsurvive_add=v.add
			group.tempsurvive_rad=v.rad
			minetest.override_item(i, {groups=group})
		end
	end
	for i,v in pairs(minetest.registered_nodes) do
		for ii,vv in pairs(groups_to_change) do
			if v.groups[ii] then
				local group=table.copy(v.groups or {})
				group.tempsurvive=1
				group.tempsurvive_add=vv.add
				group.tempsurvive_rad=vv.rad
				minetest.override_item(i, {groups=group})
				tempsurvive.nodes[i]={add=vv.add,rad=vv.rad}
			end
		end
	end
	for ii,vv in pairs(groups_to_change) do
		tempsurvive.nodes[ii]=nil
	end
end)