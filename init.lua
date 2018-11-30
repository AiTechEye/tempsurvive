tempsurvive={
	speed=0.01,
	step_timer=0,
	step_time=1,
	player={},
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
		offset={x=-244, y=-88}, --offset={x=-265, y=-88},
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
		["default:ice"]={add=-2,rad=3},
		["water"]={add=-10,rad=0},
		["torch"]={add=5,rad=5},
		["igniter"]={add=15,rad=5},
		["default:furnace_active"]={add=10,rad=10},
	}
}
dofile(minetest.get_modpath("tempsurvive") .. "/functions.lua")
dofile(minetest.get_modpath("tempsurvive") .. "/nodes_items.lua")