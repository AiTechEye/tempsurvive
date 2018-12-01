tempsurvive.new=function(player)
	local name=player:get_player_name()
	tempsurvive.player[name]={
		temp=0,
		warming=0,
		cooling=0,
		heat_resistance=40,
		coldness_resistance=-10,
		full_resistance=minetest.check_player_privs(name, {no_temperature=true}),
	}
end

minetest.register_on_joinplayer(function(player)
	tempsurvive.new(player)
	local name=player:get_player_name()
	if tempsurvive.player[name].full_resistance then return end
	tempsurvive.player[name].bar=player:hud_add(tempsurvive.bar)
	tempsurvive.player[name].screen=player:hud_add(tempsurvive.screen)
	player:get_inventory():set_size("clothes",9)
	minetest.after(0.1, function(player,name)
		tempsurvive.cloth_update(player)
	end,player,name)
end)

minetest.register_on_respawnplayer(function(player)
	local t=tempsurvive.player[player:get_player_name()]
	t.temp=0
	player:hud_change(t.bar, "text", tempsurvive.bar.text .."^[colorize:#00ff00cc")
	player:hud_change(t.bar, "number", t.temp)
	player:hud_change(t.screen, "text", tempsurvive.screen.text)
end)

minetest.register_on_leaveplayer(function(player)
	tempsurvive.player[player:get_player_name()]=nil
end)

minetest.register_privilege("no_temperature", {
	description = "Not affected by temperatures (relogin to take effect)",
	give_to_singleplayer= false,
})

tempsurvive.exposed=function(pos1,pos2,add)
	local d=vector.distance(pos1,pos2)
	if d<1 then
		return add
	end
	local v = {x = pos1.x - pos2.x, y = pos1.y - pos2.y-1, z = pos1.z - pos2.z}
	v.y=v.y-1
	local amount = (v.x ^ 2 + v.y ^ 2 + v.z ^ 2) ^ 0.5
	v.x = (v.x  / amount)*-1
	v.y = (v.y  / amount)*-1
	v.z = (v.z  / amount)*-1
	for i=1,d,1 do
		local node=minetest.registered_nodes[minetest.get_node({x=pos1.x+(v.x*i),y=pos1.y+(v.y*i),z=pos1.z+(v.z*i)}).name]
		if node and node.walkable then
			local c=minetest.get_node_group(node.name,"cracky")
			if add<0 then
				return 0
			elseif c>0 then
				c=c+1
			else
				c=2
			end
			add=add/c
		end
	end
	return add/d
end



tempsurvive.spread_temperature=function(target_pos,pos,add,rad)
	local td=vector.distance(target_pos,pos)
	if td<1 then
		return add
	end
	local jobs={pos}
	local checked={}
	while #jobs>0 and #jobs<1000 do
		for i,p in pairs(jobs) do
			for x=-1,1,1 do
			for y=-1,1,1 do
			for z=-1,1,1 do
				local np={x=p.x+x,y=p.y+y,z=p.z+z}
				local ta=minetest.pos_to_string(np)
				local d=vector.distance(pos,np)
				local nod=minetest.registered_nodes[minetest.get_node(np).name]
				if d<=rad and not checked[ta] and nod and not nod.walkable then
					if vector.distance(target_pos,np)<=1 then
						return add/td
					end
					checked[ta]=true
					table.insert(jobs,np)
				end
			end
			end
			end
			table.remove(jobs,i)
		end
	end
	return 0
end

tempsurvive.get_bio_temperature=function(pos)
	if pos.y<-50 then return 0 end
	local p={x=math.floor(pos.x),y=0,z=math.floor(pos.z)}
	local l=minetest.get_node_light(pos) or 0

	local temp=minetest.get_perlin(tempsurvive.perlin):get2d({x=p.x,y=p.z})-40

	if temp>0 then
		return temp+((l*0.025)*temp)
	else
		return temp,temp+(l*0.1)
	end
end

tempsurvive.get_artificial_temperature=function(pos,temp)
	local a=minetest.find_nodes_in_area({x=pos.x-3, y=pos.y-3, z=pos.z-3}, {x=pos.x+3, y=pos.y+3, z=pos.z+3}, {"group:tempsurvive"})
	for i,no in pairs(a) do
		local name=minetest.get_node(no).name
		local add=0
		local rad=minetest.get_item_group(name,"tempsurvive_rad")
		if minetest.get_item_group(name,"tempsurvive_temp_by_meta")>0 then
			add=add+minetest.get_meta(no):get_int("temp")
		else
			add=minetest.get_item_group(name,"tempsurvive_add")
		end
		temp=temp+tempsurvive.spread_temperature(pos,no,add,rad)
	end
	return temp
end

minetest.register_globalstep(function(dtime)
	if tempsurvive.step_timer>tempsurvive.step_time then
		tempsurvive.step_timer=0
	else
		tempsurvive.step_timer=tempsurvive.step_timer+dtime
		return
	end
	for _,player in ipairs(minetest.get_connected_players()) do

		local ptemp=tempsurvive.player[player:get_player_name()]
		if ptemp and not ptemp.full_resistance then
			local pos=player:get_pos()
			local temp=tempsurvive.get_bio_temperature(pos)
			local itn=player:get_wielded_item():get_name()

			if tempsurvive.nodes[itn] then
				temp=temp+tempsurvive.nodes[itn].add*2
			end

			local cr=ptemp.coldness_resistance-ptemp.warming
			local hr=ptemp.heat_resistance+ptemp.cooling

			temp=tempsurvive.get_artificial_temperature(pos,temp)

			ptemp.temp=ptemp.temp-(math.floor(ptemp.temp-temp)*tempsurvive.speed)

			if ptemp.temp<cr then
				player:punch(player,1+math.floor((ptemp.temp-ptemp.coldness_resistance)*-0.1),{full_punch_interval=1,damage_groups={fleshy=1}})
			elseif ptemp.temp>hr then
				player:punch(player,1+math.floor((ptemp.temp-ptemp.heat_resistance)*0.5),{full_punch_interval=1,damage_groups={fleshy=1}})
			end

			local pt=math.floor(math.abs(ptemp.temp))

			if ptemp.temp<0 and pt<=cr*-1 then
				local t=math.floor(pt/math.abs(cr)*15)
				local ht=tempsurvive.n2dhex(math.ceil(t/2))
				player:hud_change(ptemp.bar, "text", tempsurvive.bar.text .."^[colorize:#00" .. tempsurvive.n2dhex(15-t) .. tempsurvive.n2dhex(t) .."cc")
				player:hud_change(ptemp.bar, "number", 20-math.floor(pt/math.abs(cr)*20))
				player:hud_change(ptemp.screen, "text", tempsurvive.screen.text .."^[colorize:#00" .. ht .. tempsurvive.n2dhex(t) ..  ht)
			elseif ptemp.temp>=0 and pt<=hr then
				local t=math.floor(pt/math.abs(hr)*15)
				local ht=tempsurvive.n2dhex(math.ceil(t/2))
				player:hud_change(ptemp.bar, "text", tempsurvive.bar.text .."^[colorize:#" .. tempsurvive.n2dhex(t) ..tempsurvive.n2dhex(15-t) .."00cc")
				player:hud_change(ptemp.bar, "number", 20+math.floor(pt/math.abs(hr)*20))
				player:hud_change(ptemp.screen, "text", tempsurvive.screen.text .."^[colorize:#" .. tempsurvive.n2dhex(t) .. ht .. "00" ..  ht)
			end
		end
	end
end)

tempsurvive.n2dhex=function(n)
	if n<0 then n=0 end
	local a={0,1,2,3,4,5,6,7,8,9,"a","b","c","d","e","f"}
	local a2=a[n+1] or "f"
	return a2 .. a2
end

minetest.register_on_player_receive_fields(function(player, form, p)
	if form=="tempsurvive.bag" and p.quit then
		local inv=player:get_inventory()
		local layers={}
		for i=1,9,1 do
			local name=inv:get_stack("clothes",i):get_name()
			local clothes=tempsurvive.clothes[name]
			if not clothes or layers[clothes.part .. " " .. clothes.layer] then
				if inv:room_for_item("main",name) then
					inv:add_item("main",inv:get_stack("clothes",i))
				else
					minetest.add_item(player:get_pos(), inv:get_stack("clothes",i))
				end
				inv:remove_item("clothes",inv:get_stack("clothes",i))
			else
				layers[clothes.part .. " " .. clothes.layer]=1
			end
		end
		tempsurvive.cloth_update(player)
	end
end)

tempsurvive.cloth_update=function(player)
	local p=tempsurvive.player[player:get_player_name()]
	local inv=player:get_inventory()
	local layer={}
	local layern={}
	local skin=player:get_properties().textures[1]

	if not p.skin or (p.skin~=skin and not string.find(skin,"%^")) then
		p.skin=skin
	end
	local textures=p.skin

	p.warming=0
	p.cooling=0
	for i=1,9,1 do
		local clothe=tempsurvive.clothes[inv:get_stack("clothes",i):get_name()]
		if clothe then
			p.warming=p.warming+clothe.warming
			p.cooling=p.cooling+clothe.cooling
			if not layer[clothe.layer .. ""] then
				layer[clothe.layer .. ""]={}
				table.insert(layern,clothe.layer)
			end
			table.insert(layer[clothe.layer .. ""],clothe.texture)
			
		end
	end
	table.sort(layern)
	for i,n in ipairs(layern) do
		for ii,t in pairs(layer[n .. ""]) do
			textures=textures .. "^" .. t 
		end
	end

	if tempsurvive.armor then
		player:set_properties({
			mesh="3d_armor_character.b3d",
			textures={
				textures,
				player:get_properties().textures[3],
				"3d_armor_trans.png"
			}
		})
		armor:set_player_armor(player)
		armor:update_inventory(player)
	else
		player:set_properties({textures={textures}})
	end
end

tempsurvive.register_clothe=function(name,def)
	def.description=def.description or name
	local part
	local mn=minetest.get_current_modname()

	if def.part=="arm" or def.part=="leg" then
		part="tempsurvive_arm-leg.obj"
	elseif def.part=="chested" then
		part="tempsurvive_chested-head.obj"
	elseif def.part=="head" then
		part="tempsurvive_head.obj"
	else
		part="tempsurvive_body.obj"
		def.part="all"
	end

	if not (def.warming or def.cooling) then
		def.warming=2
	end

	if def.warming and not def.cooling then
		def.cooling=def.warming*-1
	elseif def.cooling and not def.warming then
		def.warming=def.cooling*-1
	end

	tempsurvive.clothes[mn .. ":cloth_" .. name]={
		warming=def.warming,
		cooling=def.cooling,
		part=def.part,
		layer=def.layer or 2,
		texture=def.texture
	}

	minetest.register_node(mn .. ":cloth_" .. name, {
		description = def.description .. " Warming: " .. def.warming ..", Cooling: " .. def.cooling,
		stack_max=1,
		drop="",
		tiles={def.texture},
		groups={dig_immediate=3,tempsurvive_cloths=1,cloth=1},
		drawtype="mesh",
		mesh=part,
		paramtype="light",
		on_use=function(itemstack, user, pointed_thing)
			minetest.registered_nodes["tempsurvive:clothes_bag"].on_use(1,user)
		end,
		on_place = function(itemstack, placer, pointed_thing)
			return
		end,
		on_construct = function(pos)
			minetest.after(0.01, function(pos)
				minetest.remove_node(pos)
			end,pos)
		end,
	})

	if def.craft then
		minetest.register_craft({
			output = mn .. ":cloth_" .. name,
			recipe = def.craft
		})
		minetest.register_craft({
			type = "fuel",
			recipe = mn .. ":cloth_" .. name,
			burntime = 2,
		})
	end
end

tempsurvive.register_cloth=function(name,hex,amount,craft)
	local itnam=minetest.get_current_modname() ..":cloth_" .. name
	minetest.register_craftitem(itnam, {
		description = string.upper(string.sub(name,1,1)) .. string.sub(name,2,string.len(name)) .." Cloth",
		inventory_image = "tempsurvive_bag.png^[colorize:#" .. hex .."^tempsurvive_cloth.png",
		groups = {cloth=1}
	})
	if craft then
	minetest.register_craft({
		type = "fuel",
		recipe = itnam,
		burntime = 2
	})
	minetest.register_craft({
		output = itnam .." " .. amount,
		recipe = craft
	})
	end
end