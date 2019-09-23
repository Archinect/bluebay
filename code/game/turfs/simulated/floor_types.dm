/turf/simulated/floor/airless
	icon_state = "floor"
	name = "airless floor"
	oxygen = 0
	nitrogen = 0
	temperature = TCMB

	New()
		..()
		name = "floor"

/turf/simulated/floor/airless/ceiling
	icon_state = "rockvault"

/turf/simulated/floor/light
	name = "Light floor"
	light_range = 5
	icon_state = "light_on"
	floor_type = /obj/item/stack/tile/light

	New()
		var/n = name //just in case commands rename it in the ..() call
		..()
		spawn(4)
			if(src)
				update_icon()
				name = n

/turf/simulated/floor/wood
	name = "floor"
	icon_state = "wood"
	floor_type = /obj/item/stack/tile/wood

/turf/simulated/floor/vault
	icon_state = "rockvault"

	New(location,type)
		..()
		icon_state = "[type]vault"

/turf/simulated/wall/vault
	icon_state = "rockvault"

	New(location,type)
		..()
		icon_state = "[type]vault"

/turf/simulated/floor/engine
	name = "reinforced floor"
	icon_state = "engine"
	thermal_conductivity = 0.025
	heat_capacity = 325000
	intact = 0

/turf/simulated/floor/engine/nitrogen
	oxygen = 0

/turf/simulated/floor/engine/attackby(obj/item/weapon/C as obj, mob/user as mob)
	if(!C)
		return
	if(!user)
		return
	if(istype(C, /obj/item/weapon/wrench))
		user << SPAN_NOTE("Removing rods...")
		playsound(src, 'sound/items/Ratchet.ogg', 80, 1)
		if(do_after(user, 30))
			PoolOrNew(/obj/item/stack/rods, list(loc, 2))
			ChangeTurf(/turf/simulated/floor)
			var/turf/simulated/floor/F = src
			F.make_plating()
			return

/turf/simulated/floor/engine/cult
	name = "engraved floor"
	icon_state = "cult"

/turf/simulated/floor/engine/cult/cultify()
	return

/turf/simulated/floor/engine/n20
	New()
		. = ..()
		assume_gas("sleeping_agent", 2000)

/turf/simulated/floor/engine/vacuum
	name = "vacuum floor"
	icon_state = "engine"
	oxygen = 0
	nitrogen = 0
	temperature = TCMB

/turf/simulated/floor/plating
	name = "plating"
	icon_state = "plating"
	floor_type = null
	intact = 0

/turf/simulated/floor/plating/with_grille
	blocks_air = 1
	icon_state = "with_grille"
	var/strict_typecheck = 1
	var/tmp/border_type = /obj/structure/window
	var/id = null //for tint

	New()
		var/tint = border_type == /obj/structure/window/reinforced/polarized
		icon_state = "plating"
		..()
		var/type = /turf/simulated/floor/plating
		if(strict_typecheck)
			type = src.type
		new /obj/structure/grille(src)
		var/obj/structure/window/reinforced/W = null
		for(var/dir in cardinal)
			if(!istype(get_step(src,dir), type))
				W = new border_type(src)
				W.dir = dir
				if(src.id && tint)
					W:id = src.id
		blocks_air = 0

/turf/simulated/floor/plating/with_grille/reinforced
	border_type = /obj/structure/window/reinforced

/turf/simulated/floor/plating/with_grille/tinted
	border_type = /obj/structure/window/reinforced/polarized


/turf/simulated/floor/plating/airless
	icon_state = "plating"
	name = "airless plating"
	oxygen = 0
	nitrogen = 0
	temperature = TCMB

	New()
		..()
		name = "plating"

/turf/simulated/floor/bluegrid
	icon = 'icons/turf/floors.dmi'
	icon_state = "bcircuit"

/turf/simulated/floor/greengrid
	icon = 'icons/turf/floors.dmi'
	icon_state = "gcircuit"


/turf/simulated/shuttle
	name = "shuttle"
	icon = 'icons/turf/shuttle.dmi'
	thermal_conductivity = 0.05
	heat_capacity = 0
	layer = 2

/turf/simulated/shuttle/edge
	density = 1
	blocks_air = 1

/turf/simulated/shuttle/wall
	name = "wall"
	icon_state = "wall"
	opacity = 1
	density = 1
	blocks_air = 1

/turf/simulated/shuttle/wall/New()
	..()
	update_icon()

/turf/simulated/shuttle/wall/orange
	color = "#FF6633"

/turf/simulated/shuttle/wall/proc/update_icon()
	var/neighbors = 0
	for(var/dir in cardinal)
		var/turf/T = get_step(src, dir)
		if(istype(T, /turf/simulated/shuttle/wall))
			neighbors |= dir

	//No neighbors
	if(!neighbors)
		icon_state = initial(icon_state)
	//Neighbors allside
	else if(neighbors == (NORTH|SOUTH|EAST|WEST))
		icon_state = "[initial(icon_state)]_full"
	//One or two adjacent neighbors
	else if(neighbors in alldirs)
		icon_state = "[initial(icon_state)]_edge"
		dir = neighbors
	//Two opposite neighbors
	else if(neighbors in list(NORTH|SOUTH, EAST|WEST))
		dir = neighbors & (NORTH|EAST)
		icon_state = "[initial(icon_state)]_line"
	//Three neighbors
	else
		icon_state = "[initial(icon_state)]_trine"
		dir = (NORTH|SOUTH|EAST|WEST) - neighbors

/turf/simulated/shuttle/wall/gray
	icon_state = "wall_gray"

/turf/simulated/shuttle/wall/gray/update_icon()
	return

/turf/simulated/shuttle/floor
	name = "floor"
	icon_state = "floor"

/turf/simulated/shuttle/plating
	name = "plating"
	icon = 'icons/turf/floors.dmi'
	icon_state = "plating"

/turf/simulated/shuttle/plating/vox	//Skipjack plating
	oxygen = 0
	nitrogen = MOLES_N2STANDARD + MOLES_O2STANDARD

/turf/simulated/shuttle/floor4 // Added this floor tile so that I have a seperate turf to check in the shuttle -- Polymorph
	name = "Brig floor"        // Also added it into the 2x3 brig area of the shuttle.
	icon_state = "floor4"

/turf/simulated/shuttle/floor4/vox	//skipjack floors
	name = "skipjack floor"
	oxygen = 0
	nitrogen = MOLES_N2STANDARD + MOLES_O2STANDARD

/turf/simulated/floor/beach
	name = "Beach"
	icon = 'icons/misc/beach.dmi'

/turf/simulated/floor/beach/sand
	name = "Sand"
	icon_state = "sand"

/turf/simulated/floor/beach/coastline
	name = "Coastline"
	icon = 'icons/misc/beach2.dmi'
	icon_state = "sandwater"

/turf/simulated/floor/beach/water
	name = "Water"
	icon_state = "water"

/turf/simulated/floor/beach/water/New()
	..()
	overlays += image("icon"='icons/misc/beach.dmi',"icon_state"="water5","layer"=MOB_LAYER+0.1)

/turf/simulated/floor/grass
	name = "Grass patch"
	icon_state = "grass1"
	floor_type = /obj/item/stack/tile/grass

	New()
		icon_state = "grass[pick("1","2","3","4")]"
		..()
		spawn(4)
			if(src)
				update_icon()
				for(var/direction in cardinal)
					if(istype(get_step(src,direction),/turf/simulated/floor))
						var/turf/simulated/floor/FF = get_step(src,direction)
						FF.update_icon() //so siding get updated properly

/turf/simulated/floor/carpet
	name = "Carpet"
	icon_state = "carpet"
	floor_type = /obj/item/stack/tile/carpet

	New()
		if(!icon_state)
			icon_state = "carpet"
		..()
		spawn(4)
			if(src)
				update_icon()
				for(var/direction in list(1,2,4,8,5,6,9,10))
					if(istype(get_step(src,direction),/turf/simulated/floor))
						var/turf/simulated/floor/FF = get_step(src,direction)
						FF.update_icon() //so siding get updated properly



/turf/simulated/floor/plating/ironsand/New()
	..()
	name = "Iron Sand"
	icon_state = "ironsand[rand(1,15)]"

/turf/simulated/floor/plating/snow
	name = "snow"
	icon = 'icons/turf/snow.dmi'
	icon_state = "snow"

/turf/simulated/floor/plating/snow/ex_act(severity)
	return