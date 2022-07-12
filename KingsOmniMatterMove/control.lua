global.ore_to_move = {}
local OIL_MAX_PER_ROW = 20

function start_with(a,b)
	return string.sub(a,1,string.len(b)) == b
end
function end_with(a,b)
	return string.sub(a,string.len(a)-string.len(b)+1) == b
end

local round = function(nr)
	local dec = nr-math.floor(nr)
	if dec >= 0.5 then
		return math.floor(nr)+1
	else
		return math.floor(nr)
	end
end

function do_dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. do_dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local function get_coordinates(number, side_length)
	local x = number % side_length
	local y = math.floor(number / side_length)
	return {x,y}
end

--Oil fields have a fixed dimension of 0-57 (20 pumps) long and +6 for every X offset thereafter
-- (so 21 patches would result in one row of 20 spaced 3 apart, 0-57, and a second row with only one
-- patch at {6,0}; 22 would be the same, but row2 would have {6,0} and {6, 3}, etc.
local function get_oil_coordinates(number)
	--This layout allows for each pump to have its own compressor.
	local x_spacing = 6
	local y_spacing = 3
	local max_row_count = OIL_MAX_PER_ROW * y_spacing
	local col_offset = math.floor(number / OIL_MAX_PER_ROW) * x_spacing
	
	local x = col_offset
	local y = (number * y_spacing) % max_row_count
	
	--Offsets every other row so that the right and left pump outputs line up.
	if math.floor(number / OIL_MAX_PER_ROW) % 2 == 1 then
		y = y - 2
	end
	return {x,y}
end

--Mark field to move
script.on_event(defines.events.on_player_selected_area, function(event)
	if event.item == "ore-move-planner" then
		global.ore_to_move[event.player_index] = nil
		local player = game.players[event.player_index]
		local surface = player.surface
		local source_area = {
			{event.area.left_top.x,	event.area.left_top.y},
			{event.area.right_bottom.x,	event.area.right_bottom.y}}
		local source_entities = surface.find_entities_filtered{area = source_area, type = "resource"}
		local ent_name = nil
		if not global.ore_to_move[event.player_index] then
			global.ore_to_move[event.player_index] = {}
		end
		for _, ent in pairs(source_entities) do
			if ent.amount > 0 then
				if global.ore_to_move[event.player_index] and global.ore_to_move[event.player_index][ent.name] then
					table.insert(global.ore_to_move[event.player_index][ent.name]["entities"], ent)
					global.ore_to_move[event.player_index][ent.name]["ent_cnt"] = global.ore_to_move[event.player_index][ent.name]["ent_cnt"] + 1
					global.ore_to_move[event.player_index][ent.name]["dest_square_side"] = math.ceil(math.sqrt(global.ore_to_move[event.player_index][ent.name]["ent_cnt"]))
					--log("DEBUG existing: adding new ent " .. serpent.dump(ent, {compact = false, nocode = true, indent = "\t"}))
				else
					global.ore_to_move[event.player_index][ent.name] = { ["entities"] = {ent}, ["src_area"] = source_area, ["ent_cnt"] = 1, ["dest_square_side"] = math.ceil(math.sqrt(1)) }
					--log("DEBUG new: adding new ent " .. serpent.dump(ent, {compact = false, nocode = true, indent = "\t"}))
				end
			end
		end
		if next(global.ore_to_move[event.player_index]) == nil then
			global.ore_to_move[event.player_index]["chart_area"] = source_area
		end
	end
end)

--Move previously marked field to destination.
script.on_event(defines.events.on_player_alt_selected_area, function(event)
	if event.item == "ore-move-planner" and global.ore_to_move[event.player_index] ~= nil then
		local player = game.players[event.player_index]
		local surface = player.surface
		
		if global.ore_to_move[event.player_index]["chart_area"] then
			player.force.chart(player.surface, global.ore_to_move[event.player_index]["chart_area"])
			global.ore_to_move[event.player_index] = nil
			return
		end
		
		local starting_x_pad = 0
		local starting_y_pad = 0
		local FIELD_SPACING = 20 --how far apart should fields be from each other?
		for ent_name, ent_table in pairs(global.ore_to_move[event.player_index]) do
			--log("DEBUG: " .. ent_name .. " || " .. ent_table.ent_cnt)
			local source_area = ent_table.src_area
			local source_entities = ent_table.entities
		
			if ent_name == "crude-oil" then
				local num_patches = ent_table.ent_cnt
				local right_x = get_oil_coordinates(num_patches-1)[1]
				local top_y = get_oil_coordinates(OIL_MAX_PER_ROW)[2]
				local bottom_y = get_oil_coordinates(OIL_MAX_PER_ROW-1)[2]
				if num_patches < 20 then
					top_y = get_oil_coordinates(0)[2]
					bottom_y = get_oil_coordinates(num_patches-1)[2]
				end
				local dest_area = {
					{event.area.left_top.x + starting_x_pad,			event.area.left_top.y + starting_y_pad + top_y},
					{event.area.left_top.x + starting_x_pad + right_x,	event.area.left_top.y + starting_y_pad + bottom_y - 1}}
				-- log(string.format("Dest_box x1 %d y1 %d x2 %d y2 %d", dest_area[1][1], dest_area[1][2], dest_area[2][1], dest_area[2][2]))
				-- log(string.format("select_b x1 %d y1 %d x2 %d y2 %d", event.area.left_top.x, event.area.left_top.y, event.area.right_bottom.x, event.area.right_bottom.y))
				-- log(string.format("offsets  x1 %d y1 %d x2 %d y2 %d", 0, top_y, right_x, bottom_y))
				
				--Note: the areas defined are different shapes compared to non-ore.
				local blocker_tile = surface.find_tiles_filtered{area = dest_area, collision_mask = {"water-tile"}}
				local blocker_ent = surface.find_entities_filtered{area = dest_area, type= {"cliff","resource"}}
				
				if next(blocker_ent) or next(blocker_tile) then
					local ent = blocker_ent[next(blocker_ent)] or blocker_tile[next(blocker_tile)]
					game.print("[KingsOmnimatterMove]: "..ent.name.." is in the way.")
				else
					local ent_count = 0
					--If the surface has no blocking entities / tiles , continue
					for _, ent in pairs(source_entities) do
						local pos = get_oil_coordinates(ent_count)
						
						--Reminder, LUA arrays count from 1, because LUA is a retarded language.
						pos[1] = pos[1] + event.area.left_top.x + starting_x_pad
						--Extra y spacing ensures we have room for pipes.
						pos[2] = pos[2] + event.area.left_top.y + starting_y_pad
									
						if ent.amount > 0 then
							surface.create_entity({name = ent.name , position = pos, force = ent.force, amount = ent.amount})
							ent_count = ent_count + 1
						end
						--log("DEBUG: destroying_curde " .. serpent.dump(ent, {compact = false, nocode = true, indent = "\t"}))
						ent.destroy()
					end
					--Cause a chart to fire on the source_area and dest_area so the ore patch is visibly moved on the map.
					player.force.chart(player.surface, source_area)
					player.force.chart(player.surface, dest_area)
					global.ore_to_move[event.player_index][ent_name] = nil
				end
				
				--Now that we have used the pads, increment them to be to the right of this field, plus a spacer.
				starting_x_pad = starting_x_pad + right_x + FIELD_SPACING
				--we don't increment starting y pad, maybe one day.
				--starting_y_pad = starting_y_pad + bottom_y + 5
			else
				local dest_square_side = ent_table.dest_square_side
				local dest_area = {
					{event.area.left_top.x + starting_x_pad,						event.area.left_top.y + starting_y_pad},
					{event.area.left_top.x + dest_square_side + starting_x_pad - 1,	event.area.left_top.y + dest_square_side + starting_y_pad - 1}}

				--Algorithm side-effect: ore fields will be square. Side-effect acceptable.
				local blocker_tile = surface.find_tiles_filtered{area = dest_area, collision_mask = {"water-tile"}}
				local blocker_ent = surface.find_entities_filtered{area = dest_area, type= {"cliff","resource"}}
				
				if next(blocker_ent) or next(blocker_tile) then
					local ent = blocker_ent[next(blocker_ent)] or blocker_tile[next(blocker_tile)]
					game.print("[KingsOmnimatterMove]: "..ent.name.." is in the way.")
				else
					local ent_count = 0
					--If the surface has no blocking entities / tiles , continue
					for _, ent in pairs(source_entities) do
						local pos = get_coordinates(ent_count, dest_square_side)
						
						--Reminder, LUA arrays count from 1, because LUA is a retarded language.
						pos[1] = pos[1] + event.area.left_top.x + starting_x_pad
						--Extra y spacing ensures we have room for pipes.
						pos[2] = pos[2] + event.area.left_top.y + starting_y_pad
									
						if ent.amount > 0 then
							surface.create_entity({name = ent.name , position = pos, force = ent.force, amount = ent.amount})
							ent_count = ent_count + 1
						end
						--log("DEBUG: destroying " .. serpent.dump(ent, {compact = false, nocode = true, indent = "\t"}))
						ent.destroy()
					end
					--Cause a chart to fire on the source_area and dest_area so the ore patch is visibly moved on the map.
					player.force.chart(player.surface, source_area)
					player.force.chart(player.surface, dest_area)
					global.ore_to_move[event.player_index][ent_name] = nil
				end
				
				starting_x_pad = starting_x_pad + dest_square_side + FIELD_SPACING
			end
		end
		global.ore_to_move[event.player_index] = nil
	end
end)

-------------------------
---Planner spawn logic---
-------------------------

local function get_planner_status(player)
	return true
end

local function refresh_planner_status(force)
	for _, ply in pairs(game.players) do
		ply.set_shortcut_available("ore-move-planner-shortcut", get_planner_status(ply))
	end
end

local function spawn_planner(player_index)
	local player = game.players[player_index]
	local stack = player.cursor_stack
	--check if the cursor is valid and clear it before inserting (lets not void held items :) )
	if stack and stack.valid then
		player.clear_cursor()
		player.cursor_stack.set_stack({type="selection-tool",name = "ore-move-planner",count=1})
	end
end

--unlock ore-move planner after the tech is researtched
script.on_event(defines.events.on_research_finished, function(event)
	local research = event.research
	if research.name == "compression-mining" then
		refresh_planner_status()
	end
end)

--Refresh planner activation when a player is created (doesnt work for sp, thanks cutscene)
script.on_event(defines.events.on_player_created, function(event)
	refresh_planner_status()
end)

--Refresh planner activation when the cutscene is canceled
script.on_event(defines.events.on_cutscene_cancelled, function(event)
	refresh_planner_status()
end)

--Refresh planner activation when tech effects are reset
script.on_event(defines.events.on_technology_effects_reset, function(event)
	refresh_planner_status()
end)

--Refresh planner activation when omnidate is activated
script.on_event(defines.events.on_console_chat, function(event)
	if event.player_index and game.players[event.player_index] then
		if event.message=="omnidate" then
			refresh_planner_status()
		end
	end
end)

--Refresh planner activation when map config is changed (required to update after the setting is changed mid-save)
script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
	refresh_planner_status()
end)

--spawn ore-move planner when a player clicks the shortcut
script.on_event(defines.events.on_lua_shortcut, function(event)
	if event.prototype_name and event.prototype_name == "ore-move-planner-shortcut" then 
		spawn_planner(event.player_index)
	end
end)

--spawn ore-move planner when the hotkey is pressed
script.on_event("give-ore-move-planner", function(event)
	if get_planner_status(game.players[event.player_index]) == true then
		spawn_planner(event.player_index)
	end
end)