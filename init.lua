-- asteroid 0.2.0 by paramat
-- For latest stable Minetest back to 0.4.7 stable
-- Depends default
-- Licenses: code WTFPL, textures CC BY SA

-- Variables

local ONGEN = true -- (true / false) Realm generation.
local PROG = true -- Print generation progress to terminal.

local YMIN = 13000 -- Approximate realm bottom.
local YMAX = 14000 -- Approximate realm top.
local XMIN = -16000 -- Approximate realm edges.
local XMAX = 16000
local ZMIN = -16000
local ZMAX = 16000

local ASCOTAV = 0.8 --  -- Asteroid / comet nucleus noise threshold average.
local ASCOTAMP = 0.1 --  -- Asteroid / comet nucleus noise threshold amplitude.
local PERS1AV = 0.5 --  -- Persistence1 average.
local PERS1AMP = 0.1 --  -- Persistence1 amplitude.

local SQUFAC = 2 --  -- Vertical squash factor.
local STOT = 0.05 --  -- Asteroid stone depth.
local ICET = 0.05 --  -- Comet ice depth.
local ATMODEP = 0.2 --  -- Comet atmosphere depth.

local FISTS = 0.01 -- 0.01 -- Fissure noise threshold at surface. Controls size of fissures and amount / size of fissure entrances at surface.
local FISEXP = 0.3 -- 0.3 -- Fissure expansion rate under surface.

local IROCHA = 5*5*5 --  -- .
local RARCHA = 11*11*11 --  -- .


-- 3D Perlin noise 1 for surfaces
local perl1 = {
	SEED1 = -92929422,
	OCTA1 = 6, --
	SCAL1 = 256, --
}

-- 3D Perlin noise 2 for varying persistence of noise1
local perl2 = {
	SEED2 = 595668,
	OCTA2 = 1, -- 
	PERS2 = 0.5, -- 
	SCAL2 = 1024, -- 
}

-- 3D Perlin noise 3 for fissures
local perl3 = {
	SEED3 = -188881,
	OCTA3 = 4, -- 
	PERS3 = 0.5, -- 
	SCAL3 = 64, -- 
}

-- 3D Perlin noise 4 for varying 'ascoth': size and proximity
local perl4 = {
	SEED4 = 1000760700090,
	OCTA4 = 1, -- 
	PERS4 = 0.5, -- 
	SCAL4 = 512, -- 
}

-- Stuff

asteroid = {}

-- Nodes of Yesod

minetest.register_node("asteroid:stone", {
	description = "AST Stone",
	tiles = {"asteroid_stone.png"},
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("asteroid:ironore", {
	description = "AST Iron Ore",
	tiles = {"asteroid_stone.png^default_mineral_iron.png"},
	groups = {cracky=3},
	drop = "default:iron_lump",
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("asteroid:regolith", {
	description = "AST Regolith",
	tiles = {"asteroid_dust.png"},
	groups = {crumbly=3},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_gravel_footstep", gain=0.1},
	}),
})

minetest.register_node("asteroid:waterice", {
	description = "AST Water Ice",
	tiles = {"asteroid_waterice.png"},
	groups = {cracky=3,melts=1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("asteroid:atmos", {
	drawtype = "glasslike",
	tiles = {"asteroid_atmos.png"},
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	post_effect_color = {a=24, r=255, g=255, b=255},
	groups = {not_in_creative_inventory=1},
})

minetest.register_node("asteroid:snode", {
	description = "AST Snow Node",
	tiles = {"asteroid_snode.png"},
	groups = {crumbly=3,melts=2},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_gravel_footstep", gain=0.2},
	}),
})

minetest.register_node("asteroid:stonebrick", {
	description = "Asteroid Stone Brick",
	tiles = {"asteroid_stonebricktop.png", "asteroid_stonebrickbot.png", "asteroid_stonebrick.png"},
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("asteroid:stoneslab", {
	description = "Asteroid Stone Slab",
	tiles = {"asteroid_stonebricktop.png", "asteroid_stonebrickbot.png", "asteroid_stonebrick.png"},
	drawtype = "nodebox",
	paramtype = "light",
	sunlight_propagates = true,
	buildable_to = true,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0, 0.5}
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, 0, 0.5}
		},
	},
	groups = {cracky=3},
	sounds = default.node_sound_stone_defaults(),
})

-- Crafting

minetest.register_craft({
	output = "default:cobble",
	recipe = {
		{"asteroid:stone"},
	},
})

minetest.register_craft({
	output = "asteroid:stonebrick 4",
	recipe = {
		{"asteroid:stone", "asteroid:stone"},
		{"asteroid:stone", "asteroid:stone"},
	}
})

minetest.register_craft({
	output = "asteroid:stoneslab 4",
	recipe = {
		{"asteroid:stone", "asteroid:stone"},
	}
})

minetest.register_craft({
	output = "default:water_source",
	recipe = {
		{"asteroid:waterice"},
	},
})

minetest.register_craft({
	output = "default:water_source",
	recipe = {
		{"asteroid:snode"},
	},
})

-- On dignode. Atmosphere flows into a dug hole.

minetest.register_on_dignode(function(pos, oldnode, digger)
	local env = minetest.env
	local x = pos.x
	local y = pos.y
	local z = pos.z
	for i = -1,1 do
	for j = -1,1 do
	for k = -1,1 do
		if not (i == 0 and j == 0 and k == 0) then
			local nodename = env:get_node({x=x+i,y=y+j,z=z+k}).name
			if nodename == "asteroid:atmos" then	
				env:add_node({x=x,y=y,z=z},{name="asteroid:atmos"})
				print ("[moonrealm] Atmosphere flows into hole")
				return
			end
		end
	end
	end
	end
end)

-- On generated function

if ONGEN then
	minetest.register_on_generated(function(minp, maxp, seed)
		if minp.x < XMIN or maxp.x > XMAX
		or minp.y < YMIN or maxp.y > YMAX
		or minp.z < ZMIN or maxp.z > ZMAX then
			return
		end
		local x1 = maxp.x
		local y1 = maxp.y
		local z1 = maxp.z
		local x0 = minp.x
		local y0 = minp.y
		local z0 = minp.z
		local perlin2 = minetest.get_perlin(perl2.SEED2, perl2.OCTA2, perl2.PERS2, perl2.SCAL2)
		local perlin3 = minetest.get_perlin(perl3.SEED3, perl3.OCTA3, perl3.PERS3, perl3.SCAL3)
		local perlin4 = minetest.get_perlin(perl4.SEED4, perl4.OCTA4, perl4.PERS4, perl4.SCAL4)
		for x = x0, x1 do -- for each plane do
			if PROG then
				print ("[asteroid] "..x - x0.." ("..minp.x.." "..minp.y.." "..minp.z..")")
			end
			for z = z0, z1 do -- for each column do
				for y = y0, y1 do -- for each node do
					local noise2 = perlin2:get3d({x=x,y=y,z=z})
					local pers1 = PERS1AV + noise2 * PERS1AMP
					local perlin1 = minetest.get_perlin(perl1.SEED1, perl1.OCTA1, pers1, perl1.SCAL1)
					local noise1 = perlin1:get3d({x=x,y=y*SQUFAC,z=z})
					local noise1abs = math.abs(noise1) 
					local noise4 = perlin4:get3d({x=x,y=y,z=z})
					local ascot = ASCOTAV + noise4 * ASCOTAMP
					if noise1abs > ascot then -- if below surface then
						local comet = false
						if noise1 < 0 then comet = true end
						local noise3 = perlin3:get3d({x=x,y=y,z=z})
						local noise1dep = noise1abs - ascot -- noise1dep zero at surface
						if math.abs(noise3) > FISTS + noise1dep * FISEXP then -- if no cave then
							if noise1 > 0 then -- if asteroid then
								if noise1dep >= STOT then -- if stone then
									if math.random(IROCHA) == 2 then
										minetest.add_node({x=x,y=y,z=z},{name="asteroid:ironore"})
									elseif math.random(RARCHA) == 2 then
										minetest.add_node({x=x,y=y,z=z},{name="default:mese"})
									else
										minetest.add_node({x=x,y=y,z=z},{name="asteroid:stone"})
									end
								else -- dust
									minetest.add_node({x=x,y=y,z=z},{name="asteroid:regolith"})
								end
							else -- comet
								if noise1dep >= ICET then -- if ice then
									if math.random(RARCHA) == 2 then
										minetest.add_node({x=x,y=y,z=z},{name="default:mese"})
									else
										minetest.add_node({x=x,y=y,z=z},{name="asteroid:waterice"})
									end
								else -- snow node
									minetest.add_node({x=x,y=y,z=z},{name="asteroid:snode"})
								end
							end
						elseif comet then -- cave, if comet then add comet atmosphere
							minetest.add_node({x=x,y=y,z=z},{name="asteroid:atmos"})
						end
					elseif noise1 < -ascot + ATMODEP then -- if comet atmosphere
						minetest.add_node({x=x,y=y,z=z},{name="asteroid:atmos"})
					end
				end
			end
		end
	end)
end
