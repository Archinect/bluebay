////////////////////////////////
///// Construction datums //////
////////////////////////////////

/datum/construction/mecha/custom_action(step, atom/used_atom, mob/user)
	user.visible_message(
		"[user] has connected [used_atom] to [holder].",
		"You connect [used_atom] to [holder]"
	)
	holder.overlays += used_atom.icon_state+"+o"
	qdel(used_atom)
	return 1

/datum/construction/mecha/action(atom/used_atom,mob/user as mob)
	return check_all_steps(used_atom,user)


/datum/construction/reversible/mecha/custom_action(index, diff, atom/used_atom, mob/user)
	if(istype(used_atom, /obj/item/weapon/weldingtool))
		var/obj/item/weapon/weldingtool/W = used_atom
		if (W.remove_fuel(0, user))
			playsound(holder, 'sound/items/Welder2.ogg', 50, 1)
		else
			return 0
	else if(istype(used_atom, /obj/item/weapon/wrench))
		playsound(holder, 'sound/items/Ratchet.ogg', 50, 1)

	else if(istype(used_atom, /obj/item/weapon/screwdriver))
		playsound(holder, 'sound/items/Screwdriver.ogg', 50, 1)

	else if(istype(used_atom, /obj/item/weapon/wirecutters))
		playsound(holder, 'sound/items/Wirecutter.ogg', 50, 1)

	else if(istype(used_atom, /obj/item/stack/cable_coil))
		var/obj/item/stack/cable_coil/C = used_atom
		if(C.use(4))
			playsound(holder, 'sound/items/Deconstruct.ogg', 50, 1)
		else
			user << ("There's not enough cable to finish the task.")
			return 0
	else if(istype(used_atom, /obj/item/stack))
		if(ismaterial(used_atom))
			var/list/step = steps[index]
			var/obj/item/stack/material/M = used_atom
			if(M.get_material_name() != step["material"])
				return 0
		var/obj/item/stack/S = used_atom
		if(S.get_amount() < 5)
			user << ("There's not enough material in this stack.")
			return 0
		else
			S.use(5)
	else if(istype(used_atom, /obj/item/weapon/stock_parts))
		var/obj/item/weapon/stock_parts/S = used_atom
		var/list/step = steps[index]
		if(S.rating < step["rating"])
			return 0
		usr.drop_from_inventory(S, holder)

	return 1

/datum/construction/reversible/mecha/action(atom/used_atom,mob/user as mob)
	return check_step(used_atom,user)


/datum/construction/mecha/ripley_chassis
	steps = list(
		list("key"=/obj/item/mecha_parts/part/ripley/torso),//1
		list("key"=/obj/item/mecha_parts/part/ripley/left_arm),//2
		list("key"=/obj/item/mecha_parts/part/ripley/right_arm),//3
		list("key"=/obj/item/mecha_parts/part/ripley/left_leg),//4
		list("key"=/obj/item/mecha_parts/part/ripley/right_leg)//5
	)

	spawn_result()
		var/obj/item/mecha_parts/chassis/const_holder = holder
		const_holder.construct = new /datum/construction/reversible/mecha/ripley(const_holder)
		const_holder.icon = 'icons/mecha/mech_construction.dmi'
		const_holder.icon_state = "ripley0"
		const_holder.density = 1
		const_holder.overlays.len = 0
		spawn()
			qdel(src)
		return


/datum/construction/reversible/mecha/ripley
	result = /obj/mecha/working/ripley
	steps = list(
		//1
		list("key"=/obj/item/weapon/weldingtool,
			"backkey"=/obj/item/weapon/wrench,
			"desc"="External armor is wrenched."),
		//2
		list("key"=/obj/item/weapon/wrench,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="External armor is installed."),
		//3
		list("key"=/obj/item/stack/material,
			"backkey"=/obj/item/weapon/weldingtool,
			"desc"="Internal armor is welded.",
			"material" = MATERIAL_PLASTEEL),
		//4
		list("key"=/obj/item/weapon/weldingtool,
			"backkey"=/obj/item/weapon/wrench,
			"desc"="Internal armor is wrenched"),
		//5
		list("key"=/obj/item/weapon/wrench,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Internal armor is installed"),
		//6
		list("key"=/obj/item/stack/material,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Peripherals control module is secured",
			"material" = MATERIAL_STEEL),
		//7
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Peripherals control module is installed"),
		//8
		list("key"=/obj/item/weapon/circuitboard/mecha/ripley/peripherals,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Central control module is secured"),
		//9
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Central control module is installed"),
		//10
		list("key"=/obj/item/weapon/circuitboard/mecha/ripley/main,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The wiring is adjusted"),
		//11
		list("key"=/obj/item/weapon/wirecutters,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The wiring is added"),
		//12
		list("key"=/obj/item/stack/cable_coil,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The hydraulic systems are active."),
		//13
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/wrench,
			"desc"="The hydraulic systems are connected."),
		//14
		list("key"=/obj/item/weapon/wrench,
			"desc"="The hydraulic systems are disconnected.")
	)

	custom_action(index, diff, atom/used_atom, mob/user)
		if(!..())
			return 0

		//TODO: better messages.
		switch(index)
			if(14)
				user.visible_message(
					"[user] connects [holder] hydraulic systems",
					"You connect [holder] hydraulic systems."
				)
				holder.icon_state = "ripley1"
			if(13)
				if(diff==FORWARD)
					user.visible_message(
						"[user] activates [holder] hydraulic systems.",
						"You activate [holder] hydraulic systems."
					)
					holder.icon_state = "ripley2"
				else
					user.visible_message(
						"[user] disconnects [holder] hydraulic systems",
						"You disconnect [holder] hydraulic systems."
					)
					holder.icon_state = "ripley0"
			if(12)
				if(diff==FORWARD)
					user.visible_message(
						"[user] adds the wiring to [holder].",
						"You add the wiring to [holder]."
					)
					holder.icon_state = "ripley3"
				else
					user.visible_message(
						"[user] deactivates [holder] hydraulic systems.",
						"You deactivate [holder] hydraulic systems."
					)
					holder.icon_state = "ripley1"
			if(11)
				if(diff==FORWARD)
					user.visible_message(
						"[user] adjusts the wiring of [holder].",
						"You adjust the wiring of [holder]."
					)
					holder.icon_state = "ripley4"
				else
					user.visible_message(
						"[user] removes the wiring from [holder].",
						"You remove the wiring from [holder]."
					)
					new /obj/item/stack/cable_coil (get_turf(holder), 4)
					holder.icon_state = "ripley2"
			if(10)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs the central control module into [holder].",
						"You install the central computer mainboard into [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "ripley5"
				else
					user.visible_message(
						"[user] disconnects the wiring of [holder].",
						"You disconnect the wiring of [holder]."
					)
					holder.icon_state = "ripley3"
			if(9)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures the mainboard.",
						"You secure the mainboard."
					)
					holder.icon_state = "ripley6"
				else
					user.visible_message(
						"[user] removes the central control module from [holder].",
						"You remove the central computer mainboard from [holder]."
					)
					new /obj/item/weapon/circuitboard/mecha/ripley/main(get_turf(holder))
					holder.icon_state = "ripley4"
			if(8)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs the peripherals control module into [holder].",
						"You install the peripherals control module into [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "ripley7"
				else
					user.visible_message(
						"[user] unfastens the mainboard.",
						"You unfasten the mainboard."
					)
					holder.icon_state = "ripley5"
			if(7)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures the peripherals control module.",
						"You secure the peripherals control module."
					)
					holder.icon_state = "ripley8"
				else
					user.visible_message(
						"[user] removes the peripherals control module from [holder].",
						"You remove the peripherals control module from [holder]."
					)
					new /obj/item/weapon/circuitboard/mecha/ripley/peripherals(get_turf(holder))
					holder.icon_state = "ripley6"
			if(6)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs internal armor layer to [holder].",
						"You install internal armor layer to [holder]."
					)
					holder.icon_state = "ripley9"
				else
					user.visible_message(
						"[user] unfastens the peripherals control module.",
						"You unfasten the peripherals control module."
					)
					holder.icon_state = "ripley7"
			if(5)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures internal armor layer.",
						"You secure internal armor layer."
					)
					holder.icon_state = "ripley10"
				else
					user.visible_message(
						"[user] pries internal armor layer from [holder].",
						"You prie internal armor layer from [holder]."
					)
					new /obj/item/stack/material/steel (get_turf(holder), 5)
					holder.icon_state = "ripley8"
			if(4)
				if(diff==FORWARD)
					user.visible_message(
						"[user] welds internal armor layer to [holder].",
						"You weld the internal armor layer to [holder]."
					)
					holder.icon_state = "ripley11"
				else
					user.visible_message(
						"[user] unfastens the internal armor layer.",
						"You unfasten the internal armor layer."
					)
					holder.icon_state = "ripley9"
			if(3)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs external reinforced armor layer to [holder].",
						"You install external reinforced armor layer to [holder]."
					)
					holder.icon_state = "ripley12"
				else
					user.visible_message(
						"[user] cuts internal armor layer from [holder].",
						"You cut the internal armor layer from [holder]."
					)
					holder.icon_state = "ripley10"
			if(2)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures external armor layer.",
						"You secure external reinforced armor layer."
					)
					holder.icon_state = "ripley13"
				else
					user.visible_message(
						"[user] pries external armor layer from [holder].",
						"You prie external armor layer from [holder]."
					)
					new /obj/item/stack/material/plasteel (get_turf(holder), 5)
					holder.icon_state = "ripley11"
			if(1)
				if(diff==FORWARD)
					user.visible_message(
						"[user] welds external armor layer to [holder].",
						"You weld external armor layer to [holder]."
					)
				else
					user.visible_message(
						"[user] unfastens the external armor layer.",
						"You unfasten the external armor layer."
					)
					holder.icon_state = "ripley12"
		return 1



/datum/construction/mecha/gygax_chassis
	steps = list(
		list("key"=/obj/item/mecha_parts/part/gygax/torso),//1
		list("key"=/obj/item/mecha_parts/part/gygax/left_arm),//2
		list("key"=/obj/item/mecha_parts/part/gygax/right_arm),//3
		list("key"=/obj/item/mecha_parts/part/gygax/left_leg),//4
		list("key"=/obj/item/mecha_parts/part/gygax/right_leg),//5
		list("key"=/obj/item/mecha_parts/part/gygax/head)
	)

	spawn_result()
		var/obj/item/mecha_parts/chassis/const_holder = holder
		const_holder.construct = new /datum/construction/reversible/mecha/gygax(const_holder)
		const_holder.icon = 'icons/mecha/mech_construction.dmi'
		const_holder.icon_state = "gygax0"
		const_holder.density = 1
		spawn()
			qdel(src)
		return


/datum/construction/reversible/mecha/gygax
	result = /obj/mecha/combat/gygax
	steps = list(
		//1
		list("key"=/obj/item/weapon/weldingtool,
			"backkey"=/obj/item/weapon/wrench,
			"desc"="External armor is wrenched."),
		//2
		list("key"=/obj/item/weapon/wrench,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="External armor is installed."),
		//3
		list("key"=/obj/item/mecha_parts/part/gygax/armour,
			"backkey"=/obj/item/weapon/weldingtool,
			"desc"="Internal armor is welded."),
		//4
		list("key"=/obj/item/weapon/weldingtool,
			"backkey"=/obj/item/weapon/wrench,
			"desc"="Internal armor is wrenched"),
		//5
		list("key"=/obj/item/weapon/wrench,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Internal armor is installed"),
		//6
		list("key"=/obj/item/stack/material,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Advanced capacitor is secured",
			"material" = MATERIAL_STEEL),
		//7
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Advanced capacitor is installed"),
		//8
		list("key"=/obj/item/weapon/stock_parts/capacitor,
			"rating" = 2,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Advanced scanner module is secured"),
		//9
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Advanced scanner module is installed"),
		//10
		list("key"=/obj/item/weapon/stock_parts/scanning_module,
			"rating" = 2,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Targeting module is secured"),
		//11
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Targeting module is installed"),
		//12
		list("key"=/obj/item/weapon/circuitboard/mecha/gygax/targeting,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Peripherals control module is secured"),
		//13
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Peripherals control module is installed"),
		//14
		list("key"=/obj/item/weapon/circuitboard/mecha/gygax/peripherals,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Central control module is secured"),
		//15
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Central control module is installed"),
		//16
		list("key"=/obj/item/weapon/circuitboard/mecha/gygax/main,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The wiring is adjusted"),
		//17
		list("key"=/obj/item/weapon/wirecutters,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The wiring is added"),
		//18
		list("key"=/obj/item/stack/cable_coil,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The hydraulic systems are active."),
		//19
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/wrench,
			"desc"="The hydraulic systems are connected."),
		//20
		list("key"=/obj/item/weapon/wrench,
			"desc"="The hydraulic systems are disconnected.")
		)

	custom_action(index, diff, atom/used_atom, mob/user)
		if(!..())
			return 0

		//TODO: better messages.
		switch(index)
			if(20)
				user.visible_message(
					"[user] connects [holder] hydraulic systems",
					"You connect [holder] hydraulic systems."
				)
				holder.icon_state = "gygax1"
			if(19)
				if(diff==FORWARD)
					user.visible_message(
						"[user] activates [holder] hydraulic systems.",
						"You activate [holder] hydraulic systems."
					)
					holder.icon_state = "gygax2"
				else
					user.visible_message(
						"[user] disconnects [holder] hydraulic systems",
						"You disconnect [holder] hydraulic systems."
					)
					holder.icon_state = "gygax0"
			if(18)
				if(diff==FORWARD)
					user.visible_message(
						"[user] adds the wiring to [holder].",
						"You add the wiring to [holder]."
					)
					holder.icon_state = "gygax3"
				else
					user.visible_message(
						"[user] deactivates [holder] hydraulic systems.",
						"You deactivate [holder] hydraulic systems."
					)
					holder.icon_state = "gygax1"
			if(17)
				if(diff==FORWARD)
					user.visible_message(
						"[user] adjusts the wiring of [holder].",
						"You adjust the wiring of [holder]."
					)
					holder.icon_state = "gygax4"
				else
					user.visible_message(
						"[user] removes the wiring from [holder].",
						"You remove the wiring from [holder]."
					)
					new /obj/item/stack/cable_coil (get_turf(holder), 4)
					holder.icon_state = "gygax2"
			if(16)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs the central control module into [holder].",
						"You install the central computer mainboard into [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "gygax5"
				else
					user.visible_message(
						"[user] disconnects the wiring of [holder].",
						"You disconnect the wiring of [holder]."
					)
					holder.icon_state = "gygax3"
			if(15)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures the mainboard.",
						"You secure the mainboard."
					)
					holder.icon_state = "gygax6"
				else
					user.visible_message(
						"[user] removes the central control module from [holder].",
						"You remove the central computer mainboard from [holder]."
					)
					new /obj/item/weapon/circuitboard/mecha/gygax/main(get_turf(holder))
					holder.icon_state = "gygax4"
			if(14)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs the peripherals control module into [holder].",
						"You install the peripherals control module into [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "gygax7"
				else
					user.visible_message(
						"[user] unfastens the mainboard.",
						"You unfasten the mainboard."
					)
					holder.icon_state = "gygax5"
			if(13)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures the peripherals control module.",
						"You secure the peripherals control module."
					)
					holder.icon_state = "gygax8"
				else
					user.visible_message(
						"[user] removes the peripherals control module from [holder].",
						"You remove the peripherals control module from [holder]."
					)
					new /obj/item/weapon/circuitboard/mecha/gygax/peripherals(get_turf(holder))
					holder.icon_state = "gygax6"
			if(12)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs the weapon control module into [holder].",
						"You install the weapon control module into [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "gygax9"
				else
					user.visible_message(
						"[user] unfastens the peripherals control module.",
						"You unfasten the peripherals control module."
					)
					holder.icon_state = "gygax7"
			if(11)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures the weapon control module.",
						"You secure the weapon control module."
					)
					holder.icon_state = "gygax10"
				else
					user.visible_message(
						"[user] removes the weapon control module from [holder].",
						"You remove the weapon control module from [holder]."
					)
					new /obj/item/weapon/circuitboard/mecha/gygax/targeting(get_turf(holder))
					holder.icon_state = "gygax8"
			if(10)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs [used_atom] to [holder].",
						"You install [used_atom] to [holder]."
					)
					holder.icon_state = "gygax11"
				else
					user.visible_message(
						"[user] unfastens the weapon control module.",
						"You unfasten the weapon control module."
					)
					holder.icon_state = "gygax9"
			if(9)
				if(diff==FORWARD)
					var/obj/item/weapon/stock_parts/scanning_module/S = locate() in holder
					if(!S)
						S = "advanced scanner module"
					user.visible_message(
						"[user] secures the [S].",
						"You secure the [S]."
					)
					holder.icon_state = "gygax12"
				else
					var/obj/item/weapon/stock_parts/scanning_module/S = locate() in holder
					if(S)
						S.forceMove(get_turf(holder))
					else
						S = "advanced scanner module"
					user.visible_message(
						"[user] removes the [S] from [holder].",
						"You remove the [S] from [holder]."
					)
					holder.icon_state = "gygax10"
			if(8)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs [used_atom] to [holder].",
						"You install [used_atom] to [holder]."
					)
					holder.icon_state = "gygax13"
				else
					var/obj/item/weapon/stock_parts/scanning_module/S = locate() in holder
					if(!S)
						S = "advanced scanner module"
					user.visible_message(
						"[user] unfastens the [S].",
						"You unfasten the [S]."
					)
					holder.icon_state = "gygax11"
			if(7)
				if(diff==FORWARD)
					var/obj/item/weapon/stock_parts/capacitor/C = locate() in holder
					if(!C)
						C = "advanced capacitor"
					user.visible_message(
						"[user] secures the [C].",
						"You secure the [C]."
					)
					holder.icon_state = "gygax14"
				else
					var/obj/item/weapon/stock_parts/capacitor/C = locate() in holder
					if(C)
						C.forceMove(get_turf(holder))
					else
						C = "advanced capacitor"
					user.visible_message(
						"[user] removes the [C] from [holder].",
						"You remove the [C] from [holder]."
					)
					holder.icon_state = "gygax12"
			if(6)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs internal armor layer to [holder].",
						"You install internal armor layer to [holder]."
					)
					holder.icon_state = "gygax15"
				else
					var/obj/item/weapon/stock_parts/capacitor/C = locate() in holder
					if(!C)
						C = "advanced capacitor"
					user.visible_message(
						"[user] unfastens the [C].",
						"You unfasten the [C]."
					)
					holder.icon_state = "gygax13"
			if(5)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures internal armor layer.",
						"You secure internal armor layer."
					)
					holder.icon_state = "gygax16"
				else
					user.visible_message(
						"[user] pries internal armor layer from [holder].",
						"You prie internal armor layer from [holder]."
					)
					new /obj/item/stack/material/steel (get_turf(holder), 5)
					holder.icon_state = "gygax14"
			if(4)
				if(diff==FORWARD)
					user.visible_message(
						"[user] welds internal armor layer to [holder].",
						"You weld the internal armor layer to [holder]."
					)
					holder.icon_state = "gygax17"
				else
					user.visible_message(
						"[user] unfastens the internal armor layer.",
						"You unfasten the internal armor layer."
					)
					holder.icon_state = "gygax15"
			if(3)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs Gygax Armour Plates to [holder].",
						"You install Gygax Armour Plates to [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "gygax18"
				else
					user.visible_message(
						"[user] cuts internal armor layer from [holder].",
						"You cut the internal armor layer from [holder]."
					)
					holder.icon_state = "gygax16"
			if(2)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures Gygax Armour Plates.",
						"You secure Gygax Armour Plates."
					)
					holder.icon_state = "gygax19"
				else
					user.visible_message(
						"[user] pries Gygax Armour Plates from [holder].",
						"You prie Gygax Armour Plates from [holder]."
					)
					new /obj/item/mecha_parts/part/gygax/armour(get_turf(holder))
					holder.icon_state = "gygax17"
			if(1)
				if(diff==FORWARD)
					user.visible_message(
						"[user] welds Gygax Armour Plates to [holder].",
						"You weld Gygax Armour Plates to [holder]."
					)
				else
					user.visible_message(
						"[user] unfastens Gygax Armour Plates.",
						"You unfasten Gygax Armour Plates."
					)
					holder.icon_state = "gygax18"
		return 1


/datum/construction/mecha/firefighter_chassis
	steps = list(
		list("key"=/obj/item/mecha_parts/part/ripley/torso),//1
		list("key"=/obj/item/mecha_parts/part/ripley/left_arm),//2
		list("key"=/obj/item/mecha_parts/part/ripley/right_arm),//3
		list("key"=/obj/item/mecha_parts/part/ripley/left_leg),//4
		list("key"=/obj/item/mecha_parts/part/ripley/right_leg),//5
		list("key"=/obj/item/clothing/suit/fire)//6
	)

	spawn_result()
		var/obj/item/mecha_parts/chassis/const_holder = holder
		const_holder.construct = new /datum/construction/reversible/mecha/firefighter(const_holder)
		const_holder.icon = 'icons/mecha/mech_construction.dmi'
		const_holder.icon_state = "fireripley0"
		const_holder.density = 1
		spawn()
			qdel(src)
		return


/datum/construction/reversible/mecha/firefighter
	result = /obj/mecha/working/ripley/firefighter
	steps = list(
		//1
		list("key"=/obj/item/weapon/weldingtool,
			"backkey"=/obj/item/weapon/wrench,
			"desc"="External armor is wrenched."),
		//2
		list("key"=/obj/item/weapon/wrench,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="External armor is installed."),
		//3
		list("key"=/obj/item/stack/material,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="External armor is being installed.",
			"material" = MATERIAL_PLASTEEL),
		//4
		list("key"=/obj/item/stack/material,
			"backkey"=/obj/item/weapon/weldingtool,
			"desc"="Internal armor is welded.",
			"material" = MATERIAL_PLASTEEL),
		//5
		list("key"=/obj/item/weapon/weldingtool,
			"backkey"=/obj/item/weapon/wrench,
			"desc"="Internal armor is wrenched"),
		//6
		list("key"=/obj/item/weapon/wrench,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Internal armor is installed"),
		//7
		list("key"=/obj/item/stack/material,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Peripherals control module is secured",
			"material" = MATERIAL_PLASTEEL),
		//8
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Peripherals control module is installed"),
		//9
		list("key"=/obj/item/weapon/circuitboard/mecha/ripley/peripherals,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Central control module is secured"),
		//10
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Central control module is installed"),
		//11
		list("key"=/obj/item/weapon/circuitboard/mecha/ripley/main,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The wiring is adjusted"),
		//12
		list("key"=/obj/item/weapon/wirecutters,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The wiring is added"),
		//13
		list("key"=/obj/item/stack/cable_coil,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The hydraulic systems are active."),
		//14
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/wrench,
			"desc"="The hydraulic systems are connected."),
		//15
		list("key"=/obj/item/weapon/wrench,
			"desc"="The hydraulic systems are disconnected.")
	)

	custom_action(index, diff, atom/used_atom, mob/user)
		if(!..())
			return 0

		//TODO: better messages.
		switch(index)
			if(15)
				user.visible_message(
					"[user] connects [holder] hydraulic systems",
					"You connect [holder] hydraulic systems."
				)
				holder.icon_state = "fireripley1"
			if(14)
				if(diff==FORWARD)
					user.visible_message(
						"[user] activates [holder] hydraulic systems.",
						"You activate [holder] hydraulic systems."
					)
					holder.icon_state = "fireripley2"
				else
					user.visible_message(
						"[user] disconnects [holder] hydraulic systems",
						"You disconnect [holder] hydraulic systems."
					)
					holder.icon_state = "fireripley0"
			if(13)
				if(diff==FORWARD)
					user.visible_message(
						"[user] adds the wiring to [holder].",
						"You add the wiring to [holder]."
					)
					holder.icon_state = "fireripley3"
				else
					user.visible_message(
						"[user] deactivates [holder] hydraulic systems.",
						"You deactivate [holder] hydraulic systems."
					)
					holder.icon_state = "fireripley1"
			if(12)
				if(diff==FORWARD)
					user.visible_message(
						"[user] adjusts the wiring of [holder].",
						"You adjust the wiring of [holder]."
					)
					holder.icon_state = "fireripley4"
				else
					user.visible_message(
						"[user] removes the wiring from [holder].",
						"You remove the wiring from [holder]."
					)
					new /obj/item/stack/cable_coil (get_turf(holder), 4)
					holder.icon_state = "fireripley2"
			if(11)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs the central control module into [holder].",
						"You install the central computer mainboard into [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "fireripley5"
				else
					user.visible_message(
						"[user] disconnects the wiring of [holder].",
						"You disconnect the wiring of [holder]."
					)
					holder.icon_state = "fireripley3"
			if(10)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures the mainboard.",
						"You secure the mainboard."
					)
					holder.icon_state = "fireripley6"
				else
					user.visible_message(
						"[user] removes the central control module from [holder].",
						"You remove the central computer mainboard from [holder]."
					)
					new /obj/item/weapon/circuitboard/mecha/ripley/main(get_turf(holder))
					holder.icon_state = "fireripley4"
			if(9)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs the peripherals control module into [holder].",
						"You install the peripherals control module into [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "fireripley7"
				else
					user.visible_message(
						"[user] unfastens the mainboard.",
						"You unfasten the mainboard."
					)
					holder.icon_state = "fireripley5"
			if(8)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures the peripherals control module.",
						"You secure the peripherals control module."
					)
					holder.icon_state = "fireripley8"
				else
					user.visible_message(
						"[user] removes the peripherals control module from [holder].",
						"You remove the peripherals control module from [holder]."
					)
					new /obj/item/weapon/circuitboard/mecha/ripley/peripherals(get_turf(holder))
					holder.icon_state = "fireripley6"
			if(7)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs internal armor layer to [holder].",
						"You install internal armor layer to [holder]."
					)
					holder.icon_state = "fireripley9"
				else
					user.visible_message(
						"[user] unfastens the peripherals control module.",
						"You unfasten the peripherals control module."
					)
					holder.icon_state = "fireripley7"

			if(6)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures internal armor layer.",
						"You secure internal armor layer."
					)
					holder.icon_state = "fireripley10"
				else
					user.visible_message(
						"[user] pries internal armor layer from [holder].",
						"You prie internal armor layer from [holder]."
					)
					new /obj/item/stack/material/plasteel (get_turf(holder), 5)
					holder.icon_state = "fireripley8"
			if(5)
				if(diff==FORWARD)
					user.visible_message(
						"[user] welds internal armor layer to [holder].",
						"You weld the internal armor layer to [holder]."
					)
					holder.icon_state = "fireripley11"
				else
					user.visible_message(
						"[user] unfastens the internal armor layer.",
						"You unfasten the internal armor layer."
					)
					holder.icon_state = "fireripley9"
			if(4)
				if(diff==FORWARD)
					user.visible_message(
						"[user] starts to install the external armor layer to [holder].",
						"You start to install the external armor layer to [holder]."
					)
					holder.icon_state = "fireripley12"
				else
					user.visible_message(
						"[user] cuts internal armor layer from [holder].",
						"You cut the internal armor layer from [holder]."
					)
					holder.icon_state = "fireripley10"
			if(3)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs external reinforced armor layer to [holder].",
						"You install external reinforced armor layer to [holder]."
					)
					holder.icon_state = "fireripley13"
				else
					user.visible_message(
						"[user] removes the external armor from [holder].",
						"You remove the external armor from [holder]."
					)
					new /obj/item/stack/material/plasteel (get_turf(holder), 5)
					holder.icon_state = "fireripley11"
			if(2)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures external armor layer.",
						"You secure external reinforced armor layer."
					)
					holder.icon_state = "fireripley14"
				else
					user.visible_message(
						"[user] pries external armor layer from [holder].",
						"You prie external armor layer from [holder]."
					)
					new /obj/item/stack/material/plasteel (get_turf(holder), 5)
					holder.icon_state = "fireripley12"
			if(1)
				if(diff==FORWARD)
					user.visible_message(
						"[user] welds external armor layer to [holder].",
						"You weld external armor layer to [holder]."
					)
				else
					user.visible_message(
						"[user] unfastens the external armor layer.",
						"You unfasten the external armor layer."
					)
					holder.icon_state = "fireripley13"
		return 1

/datum/construction/mecha/durand_chassis
	steps = list(
		list("key"=/obj/item/mecha_parts/part/durand/torso),//1
		list("key"=/obj/item/mecha_parts/part/durand/left_arm),//2
		list("key"=/obj/item/mecha_parts/part/durand/right_arm),//3
		list("key"=/obj/item/mecha_parts/part/durand/left_leg),//4
		list("key"=/obj/item/mecha_parts/part/durand/right_leg),//5
		list("key"=/obj/item/mecha_parts/part/durand/head)
	)

	spawn_result()
		var/obj/item/mecha_parts/chassis/const_holder = holder
		const_holder.construct = new /datum/construction/reversible/mecha/durand(const_holder)
		const_holder.icon = 'icons/mecha/mech_construction.dmi'
		const_holder.icon_state = "durand0"
		const_holder.density = 1
		spawn()
			qdel(src)
		return

/datum/construction/reversible/mecha/durand
	result = /obj/mecha/combat/durand
	steps = list(
		//1
		list("key"=/obj/item/weapon/weldingtool,
			"backkey"=/obj/item/weapon/wrench,
			"desc"="External armor is wrenched."),
		//2
		list("key"=/obj/item/weapon/wrench,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="External armor is installed."),
		//3
		list("key"=/obj/item/mecha_parts/part/durand/armour,
			"backkey"=/obj/item/weapon/weldingtool,
			"desc"="Internal armor is welded."),
		//4
		list("key"=/obj/item/weapon/weldingtool,
			"backkey"=/obj/item/weapon/wrench,
			"desc"="Internal armor is wrenched"),
		//5
		list("key"=/obj/item/weapon/wrench,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Internal armor is installed"),
		//6
		list("key"=/obj/item/stack/material,
			 "backkey"=/obj/item/weapon/screwdriver,
			 "desc"="Advanced capacitor is secured",
			 "material" = MATERIAL_PLASTEEL),
		//7
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Advanced capacitor is installed"),
		//8
		list("key"=/obj/item/weapon/stock_parts/capacitor/adv,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Advanced scanner module is secured"),
		//9
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Advanced scanner module is installed"),
		//10
		list("key"=/obj/item/weapon/stock_parts/scanning_module/adv,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Targeting module is secured"),
		//11
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Targeting module is installed"),
		//12
		list("key"=/obj/item/weapon/circuitboard/mecha/durand/targeting,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Peripherals control module is secured"),
		//13
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Peripherals control module is installed"),
		//14
		list("key"=/obj/item/weapon/circuitboard/mecha/durand/peripherals,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Central control module is secured"),
		//15
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Central control module is installed"),
		//16
		list("key"=/obj/item/weapon/circuitboard/mecha/durand/main,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The wiring is adjusted"),
		//17
		list("key"=/obj/item/weapon/wirecutters,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The wiring is added"),
		//18
		list("key"=/obj/item/stack/cable_coil,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The hydraulic systems are active."),
		//19
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/wrench,
			"desc"="The hydraulic systems are connected."),
		//20
		list("key"=/obj/item/weapon/wrench,
			"desc"="The hydraulic systems are disconnected.")
		)


	custom_action(index, diff, atom/used_atom, mob/user)
		if(!..())
			return 0

		//TODO: better messages.
		switch(index)
			if(20)
				user.visible_message(
					"[user] connects [holder] hydraulic systems",
					"You connect [holder] hydraulic systems."
				)
				holder.icon_state = "durand1"
			if(19)
				if(diff==FORWARD)
					user.visible_message(
						"[user] activates [holder] hydraulic systems.",
						"You activate [holder] hydraulic systems."
					)
					holder.icon_state = "durand2"
				else
					user.visible_message(
						"[user] disconnects [holder] hydraulic systems",
						"You disconnect [holder] hydraulic systems."
					)
					holder.icon_state = "durand0"
			if(18)
				if(diff==FORWARD)
					user.visible_message(
						"[user] adds the wiring to [holder].",
						"You add the wiring to [holder]."
					)
					holder.icon_state = "durand3"
				else
					user.visible_message(
						"[user] deactivates [holder] hydraulic systems.",
						"You deactivate [holder] hydraulic systems."
					)
					holder.icon_state = "durand1"
			if(17)
				if(diff==FORWARD)
					user.visible_message(
						"[user] adjusts the wiring of [holder].",
						"You adjust the wiring of [holder]."
					)
					holder.icon_state = "durand4"
				else
					user.visible_message(
						"[user] removes the wiring from [holder].",
						"You remove the wiring from [holder]."
					)
					new /obj/item/stack/cable_coil (get_turf(holder), 4)
					holder.icon_state = "durand2"
			if(16)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs the central control module into [holder].",
						"You install the central computer mainboard into [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "durand5"
				else
					user.visible_message(
						"[user] disconnects the wiring of [holder].",
						"You disconnect the wiring of [holder]."
					)
					holder.icon_state = "durand3"
			if(15)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures the mainboard.",
						"You secure the mainboard."
					)
					holder.icon_state = "durand6"
				else
					user.visible_message(
						"[user] removes the central control module from [holder].",
						"You remove the central computer mainboard from [holder]."
					)
					new /obj/item/weapon/circuitboard/mecha/durand/main(get_turf(holder))
					holder.icon_state = "durand4"
			if(14)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs the peripherals control module into [holder].",
						"You install the peripherals control module into [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "durand7"
				else
					user.visible_message(
						"[user] unfastens the mainboard.",
						"You unfasten the mainboard."
					)
					holder.icon_state = "durand5"
			if(13)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures the peripherals control module.",
						"You secure the peripherals control module."
					)
					holder.icon_state = "durand8"
				else
					user.visible_message(
						"[user] removes the peripherals control module from [holder].",
						"You remove the peripherals control module from [holder]."
					)
					new /obj/item/weapon/circuitboard/mecha/durand/peripherals(get_turf(holder))
					holder.icon_state = "durand6"
			if(12)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs the weapon control module into [holder].",
						"You install the weapon control module into [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "durand9"
				else
					user.visible_message(
						"[user] unfastens the peripherals control module.",
						"You unfasten the peripherals control module."
					)
					holder.icon_state = "durand7"
			if(11)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures the weapon control module.",
						"You secure the weapon control module."
					)
					holder.icon_state = "durand10"
				else
					user.visible_message(
						"[user] removes the weapon control module from [holder].",
						"You remove the weapon control module from [holder]."
					)
					new /obj/item/weapon/circuitboard/mecha/durand/targeting(get_turf(holder))
					holder.icon_state = "durand8"
			if(10)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs [used_atom] to [holder].",
						"You install [used_atom] to [holder]."
					)
					holder.icon_state = "durand11"
				else
					user.visible_message(
						"[user] unfastens the weapon control module.",
						"You unfasten the weapon control module."
					)
					holder.icon_state = "durand9"
			if(9)
				if(diff==FORWARD)
					var/obj/item/weapon/stock_parts/scanning_module/S = locate() in holder
					if(!S)
						S = "advanced scanner module"
					user.visible_message(
						"[user] secures the [S].",
						"You secure the [S]."
					)
					holder.icon_state = "durand12"
				else
					var/obj/item/weapon/stock_parts/scanning_module/S = locate() in holder
					if(S)
						S.forceMove(get_turf(holder))
					else
						S = "advanced scanner module"
					user.visible_message(
						"[user] removes the [S] from [holder].",
						"You remove the [S] from [holder]."
					)
					holder.icon_state = "durand10"
			if(8)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs [used_atom] to [holder].",
						"You install [used_atom] to [holder]."
					)
					holder.icon_state = "durand13"
				else
					var/obj/item/weapon/stock_parts/scanning_module/S = locate() in holder
					if(!S)
						S = "advanced scanner module"
					user.visible_message(
						"[user] unfastens the [S].",
						"You unfasten the [S]."
					)
					holder.icon_state = "durand11"
			if(7)
				if(diff==FORWARD)
					var/obj/item/weapon/stock_parts/capacitor/C = locate() in holder
					if(!C)
						C = "advanced capacitor"
					user.visible_message(
						"[user] secures the [C].",
						"You secure the [C]."
					)
					holder.icon_state = "durand14"
				else
					var/obj/item/weapon/stock_parts/capacitor/C = locate() in holder
					if(C)
						C.forceMove(get_turf(holder))
					else
						C = "advanced capacitor"
					user.visible_message(
						"[user] removes the [C] from [holder].",
						"You remove the [C] from [holder]."
					)
					holder.icon_state = "durand12"
			if(6)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs internal armor layer to [holder].",
						"You install internal armor layer to [holder]."
					)
					holder.icon_state = "durand15"
				else
					var/obj/item/weapon/stock_parts/capacitor/C = locate() in holder
					if(!C)
						C = "advanced capacitor"
					user.visible_message(
						"[user] unfastens the [C].",
						"You unfasten the [C]."
					)
					holder.icon_state = "durand13"
			if(5)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures internal armor layer.",
						"You secure internal armor layer."
					)
					holder.icon_state = "durand16"
				else
					user.visible_message(
						"[user] pries internal armor layer from [holder].",
						"You prie internal armor layer from [holder]."
					)
					new /obj/item/stack/material/steel (get_turf(holder), 5)
					holder.icon_state = "durand14"
			if(4)
				if(diff==FORWARD)
					user.visible_message(
						"[user] welds internal armor layer to [holder].",
						"You weld the internal armor layer to [holder]."
					)
					holder.icon_state = "durand17"
				else
					user.visible_message(
						"[user] unfastens the internal armor layer.",
						"You unfasten the internal armor layer."
					)
					holder.icon_state = "durand15"
			if(3)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs Durand Armour Plates to [holder].",
						"You install Durand Armour Plates to [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "durand18"
				else
					user.visible_message(
						"[user] cuts internal armor layer from [holder].",
						"You cut the internal armor layer from [holder]."
					)
					holder.icon_state = "durand16"
			if(2)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures Durand Armour Plates.",
						"You secure Durand Armour Plates."
					)
					holder.icon_state = "durand19"
				else
					user.visible_message(
						"[user] pries Durand Armour Plates from [holder].",
						"You prie Durand Armour Plates from [holder]."
					)
					new /obj/item/mecha_parts/part/durand/armour(get_turf(holder))
					holder.icon_state = "durand17"
			if(1)
				if(diff==FORWARD)
					user.visible_message(
						"[user] welds Durand Armour Plates to [holder].",
						"You weld Durand Armour Plates to [holder]."
					)
				else
					user.visible_message(
						"[user] unfastens Durand Armour Plates.",
						"You unfasten Durand Armour Plates."
					)
					holder.icon_state = "durand18"
		return 1

//PHAZON

/datum/construction/mecha/phazon_chassis
	steps = list(
		list("key"=/obj/item/mecha_parts/part/phazon/torso),//1
		list("key"=/obj/item/mecha_parts/part/phazon/left_arm),//2
		list("key"=/obj/item/mecha_parts/part/phazon/right_arm),//3
		list("key"=/obj/item/mecha_parts/part/phazon/left_leg),//4
		list("key"=/obj/item/mecha_parts/part/phazon/right_leg),//5
		list("key"=/obj/item/mecha_parts/part/phazon/head)
	)

	spawn_result()
		var/obj/item/mecha_parts/chassis/const_holder = holder
		const_holder.construct = new /datum/construction/reversible/mecha/phazon(const_holder)
		const_holder.icon = 'icons/mecha/mech_construction.dmi'
		const_holder.icon_state = "phazon0"
		const_holder.density = 1
		spawn()
			qdel(src)
		return


/datum/construction/reversible/mecha/phazon
	result = /obj/mecha/combat/phazon
	steps = list(
		//1
		list("key"=/obj/item/weapon/hand_tele,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="The hand tele is installed."),
		//2
		list("key"=/obj/item/weapon/weldingtool,
			"backkey"=/obj/item/weapon/wrench,
			"desc"="External armor is wrenched."),
		//3
		list("key"=/obj/item/weapon/wrench,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="External armor is installed."),
		//4
		list("key"=/obj/item/mecha_parts/part/phazon/armor,
			"backkey"=/obj/item/weapon/weldingtool,
			"desc"="Phase armor is welded."),
		//5
		list("key"=/obj/item/weapon/weldingtool,
			"backkey"=/obj/item/weapon/wrench,
			"desc"="Phase armor is wrenched."),
		//6
		list("key"=/obj/item/weapon/wrench,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Phase armor is installed."),
		//7
		list("key"=/obj/item/stack/material,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The bluespace crystal is engaged.",
			"material" = MATERIAL_PLASTEEL),
		//8
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/wirecutters,
			"desc"="The bluespace crystal is connected."),
		//9
		list("key"=/obj/item/stack/cable_coil,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="The bluespace crystal is installed."),
		//10
		list("key"=/obj/item/weapon/stock_parts/subspace/crystal,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Super capacitor is secured."),
		//12
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Super capacitor is installed."),
		//12
		list("key"=/obj/item/weapon/stock_parts/capacitor,
			"rating" = 3,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Phasic scanner module is secured."),
		//13
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Phasic scanner module is installed."),
		//14
		list("key"=/obj/item/weapon/stock_parts/scanning_module,
			"rating" = 3,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Weapon control module is secured."),
		//15
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Weapon control is installed."),
		//16
		list("key"=/obj/item/weapon/circuitboard/mecha/phazon/targeting,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Peripherals control module is secured."),
		//17
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Peripherals control module is installed"),
		//18
		list("key"=/obj/item/weapon/circuitboard/mecha/phazon/peripherals,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Central control module is secured."),
		//19
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Central control module is installed."),
		//20
		list("key"=/obj/item/weapon/circuitboard/mecha/phazon/main,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The wiring is adjusted."),
		//21
		list("key"=/obj/item/weapon/wirecutters,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The wiring is added."),
		//22
		list("key"=/obj/item/stack/cable_coil,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The hydraulic systems are active."),
		//23
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/wrench,
			"desc"="The hydraulic systems are connected."),
		//24
		list("key"=/obj/item/weapon/wrench,
			"desc"="The hydraulic systems are disconnected.")
		)


	custom_action(index, diff, atom/used_atom, mob/user)
		if(!..())
			return 0

		//TODO: better messages.
		switch(index)
			if(24)
				user.visible_message(
					"[user] connects the [holder] hydraulic systems",
					"You connect [holder] hydraulic systems."
				)
				holder.icon_state = "phazon1"
			if(23)
				if(diff==FORWARD)
					user.visible_message(
						"[user] activates the [holder] hydraulic systems.",
						"You activate [holder] hydraulic systems."
					)
					holder.icon_state = "phazon2"
				else
					user.visible_message(
						"[user] disconnects the [holder] hydraulic systems",
						"You disconnect [holder] hydraulic systems."
					)
					holder.icon_state = "phazon0"
			if(22)
				if(diff==FORWARD)
					user.visible_message(
						"[user] adds the wiring to the [holder].",
						"You add the wiring to [holder]."
					)
					holder.icon_state = "phazon3"
				else
					user.visible_message(
						"[user] deactivates the [holder] hydraulic systems.",
						"You deactivate [holder] hydraulic systems."
					)
					holder.icon_state = "phazon1"
			if(21)
				if(diff==FORWARD)
					user.visible_message(
						"[user] adjusts the wiring of the [holder].",
						"You adjust the wiring of [holder]."
					)
					holder.icon_state = "phazon4"
				else
					user.visible_message(
						"[user] removes the wiring from the [holder].",
						"You remove the wiring from [holder]."
					)
					new /obj/item/stack/cable_coil (get_turf(holder), 4)
					holder.icon_state = "phazon2"
			if(20)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs the central control module into the [holder].",
						"You install the central computer mainboard into [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "phazon5"
				else
					user.visible_message(
						"[user] disconnects the wiring of the [holder].",
						"You disconnect the wiring of [holder]."
					)
					holder.icon_state = "phazon3"
			if(19)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures the mainboard.",
						"You secure the mainboard."
					)
					holder.icon_state = "phazon6"
				else
					user.visible_message(
						"[user] removes the central control module from the [holder].",
						"You remove the central computer mainboard from [holder]."
					)
					new /obj/item/weapon/circuitboard/mecha/phazon/main(get_turf(holder))
					holder.icon_state = "phazon4"
			if(18)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs the peripherals control module into the [holder].",
						"You install the peripherals control module into [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "phazon7"
				else
					user.visible_message(
						"[user] unfastens the mainboard.",
						"You unfasten the mainboard."
					)
					holder.icon_state = "phazon5"
			if(17)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures the peripherals control module.",
						"You secure the peripherals control module."
					)
					holder.icon_state = "phazon8"
				else
					user.visible_message(
						"[user] removes the peripherals control module from the [holder].",
						"You remove the peripherals control module from [holder]."
					)
					new /obj/item/weapon/circuitboard/mecha/phazon/peripherals(get_turf(holder))
					holder.icon_state = "phazon6"
			if(16)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs the weapon control module into the [holder].",
						"You install the weapon control module into [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "phazon9"
				else
					user.visible_message(
						"[user] unfastens the peripherals control module.",
						"You unfasten the peripherals control module."
					)
					holder.icon_state = "phazon7"
			if(15)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures the weapon control module.",
						"You secure the weapon control module."
					)
					holder.icon_state = "phazon10"
				else
					user.visible_message(
						"[user] removes the weapon control module from the [holder].",
						"You remove the weapon control module from [holder]."
					)
					new /obj/item/weapon/circuitboard/mecha/phazon/targeting(get_turf(holder))
					holder.icon_state = "phazon8"
			if(14)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs [used_atom] to the [holder].",
						"You install [used_atom] to [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "phazon11"
				else
					user.visible_message(
						"[user] unfastens the weapon control module.",
						"You unfasten the weapon control module."
					)
					holder.icon_state = "phazon9"
			if(13)
				if(diff==FORWARD)
					var/obj/item/weapon/stock_parts/scanning_module/S = locate() in holder
					if(!S)
						S = "phasic scanner module"
					user.visible_message(
						"[user] secures the [S].",
						"You secure the [S]."
					)
					holder.icon_state = "phazon12"
				else
					var/obj/item/weapon/stock_parts/scanning_module/S = locate() in holder
					if(S)
						S.forceMove(get_turf(holder))
					else
						S = "phasic scanner module"
					user.visible_message(
						"[user] removes the [S] from [holder].",
						"You remove the [S] from [holder]."
					)
					holder.icon_state = "phazon10"
			if(12)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs [used_atom] to the [holder].",
						"You install [used_atom] to [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "phazon13"
				else
					var/obj/item/weapon/stock_parts/scanning_module/S = locate() in holder
					if(!S)
						S = "phasic scanner module"
					user.visible_message(
						"[user] unfastens the [S].",
						"You unfasten the [S]."
					)
					holder.icon_state = "phazon11"
			if(11)
				if(diff==FORWARD)
					var/obj/item/weapon/stock_parts/capacitor/C = locate() in holder
					if(!C)
						C = "super capacitor"
					user.visible_message(
						"[user] secures the [C].",
						"You secure the [C]."
					)
					holder.icon_state = "phazon14"
				else
					var/obj/item/weapon/stock_parts/capacitor/C = locate() in holder
					if(C)
						C.forceMove(get_turf(holder))
					else
						C = "super capacitor"
					user.visible_message(
						"[user] removes the [C] from [holder].",
						"You remove the [C] from [holder]."
					)
					holder.icon_state = "phazon12"
			if(10)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs the bluespace crystal.",
						"You install the bluespace crystal"
					)
					qdel(used_atom)
					holder.icon_state = "phazon15"
				else
					var/obj/item/weapon/stock_parts/capacitor/C = locate() in holder
					if(!C)
						C = "super capacitor"
					user.visible_message(
						"[user] unfastens the [C].",
						"You unfasten the [C]."
					)
					holder.icon_state = "phazon13"
			if(9)
				if(diff==FORWARD)
					user.visible_message(
						"[user] connects the bluespace crystal.",
						"You connect the bluespace crystal."
					)
					holder.icon_state = "phazon16"
				else
					user.visible_message(
						"[user] removes the bluespace crystal from the [holder].",
						"You remove the bluespace crystal from the [holder]."
					)
					new /obj/item/weapon/stock_parts/subspace/crystal(get_turf(holder))
					holder.icon_state = "phazon14"
			if(8)
				if(diff==FORWARD)
					user.visible_message(
						"[user] engages the bluespace crystal.",
						"You engage the bluespace crystal."
					)
					holder.icon_state = "phazon17"
				else
					user.visible_message(
						"[user] disconnects the bluespace crystal from the [holder].",
						"You disconnect the bluespace crystal from the [holder]."
					)
					holder.icon_state = "phazon15"
			if(7)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs the phase armor layer to the [holder].",
						"You install the phase armor layer to the [holder]."
					)
					holder.icon_state = "phazon18"
				else
					user.visible_message(
						"[user] disengages the bluespace crystal.",
						"You disengage the bluespace crystal."
					)
					holder.icon_state = "phazon16"
			if(6)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures the phase armor layer.",
						"You secure the phase armor layer."
					)
					holder.icon_state = "phazon19"
				else
					user.visible_message(
						"[user] pries the phase armor layer from the [holder].",
						"You pry the phase armor layer from the [holder]."
					)
					new /obj/item/stack/material/plasteel (get_turf(holder), 5)
					holder.icon_state = "phazon17"
			if(5)
				if(diff==FORWARD)
					user.visible_message(
						"[user] welds the phase armor layer to the [holder].",
						"You weld the phase armor layer to the [holder]."
					)
					holder.icon_state = "phazon20"
				else
					user.visible_message(
						"[user] unfastens the phase armor layer.",
						"You unfasten the phase armor layer."
					)
					holder.icon_state = "phazon18"
			if(4)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs Phazon Armor Plates to the [holder].",
						"You install Phazon Armor Plates to the [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "phazon21"
				else
					user.visible_message(
						"[user] cuts phase armor layer from the [holder].",
						"You cut phase armor layer from the [holder]."
					)
					holder.icon_state = "phazon19"
			if(3)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures Phazon Armor Plates.",
						"You secure Phazon Armor Plates."
					)
					holder.icon_state = "phazon22"
				else
					user.visible_message(
						"[user] pries Phazon Armor Plates from the [holder].",
						"You pry Phazon Armor Plates from the [holder]."
					)
					new /obj/item/mecha_parts/part/phazon/armor(get_turf(holder))
					holder.icon_state = "phazon20"
			if(2)
				if(diff==FORWARD)
					user.visible_message(
						"[user] welds Phazon Armor Plates to the [holder].",
						"You weld Phazon Armor Plates to the [holder]."
					)
				else
					user.visible_message(
						"[user] unfastens Phazon Armor Plates.",
						"You unfasten Phazon Armor Plates."
					)
					holder.icon_state = "phazon21"
			if(1)
				if(diff==FORWARD)
					user.visible_message(
						"[user] carefully inserts the hand tele into \the [holder] and secures it.",
						"You carefully insert the hand tele into \the [holder] and secures it."//anomaly core
					)
					qdel(used_atom)
		return 1


//ODYSSEUS

/datum/construction/mecha/odysseus_chassis
	steps = list(
		list("key"=/obj/item/mecha_parts/part/odysseus/torso),//1
		list("key"=/obj/item/mecha_parts/part/odysseus/head),//2
		list("key"=/obj/item/mecha_parts/part/odysseus/left_arm),//3
		list("key"=/obj/item/mecha_parts/part/odysseus/right_arm),//4
		list("key"=/obj/item/mecha_parts/part/odysseus/left_leg),//5
		list("key"=/obj/item/mecha_parts/part/odysseus/right_leg)//6
	)

	spawn_result()
		var/obj/item/mecha_parts/chassis/const_holder = holder
		const_holder.construct = new /datum/construction/reversible/mecha/odysseus(const_holder)
		const_holder.icon = 'icons/mecha/mech_construction.dmi'
		const_holder.icon_state = "odysseus0"
		const_holder.density = 1
		spawn()
			qdel(src)
		return


/datum/construction/reversible/mecha/odysseus
	result = /obj/mecha/medical/odysseus
	steps = list(
		//1
		list("key"=/obj/item/weapon/weldingtool,
			"backkey"=/obj/item/weapon/wrench,
			"desc"="External armor is wrenched."),
		//2
		list("key"=/obj/item/weapon/wrench,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="External armor is installed."),
		//3
		list("key"=/obj/item/stack/material,
			"backkey"=/obj/item/weapon/weldingtool,
			"desc"="Internal armor is welded.",
			"material" = MATERIAL_PLASTEEL),
		//4
		list("key"=/obj/item/weapon/weldingtool,
			"backkey"=/obj/item/weapon/wrench,
			"desc"="Internal armor is wrenched"),
		//5
		list("key"=/obj/item/weapon/wrench,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Internal armor is installed"),
		//6
		list("key"=/obj/item/stack/material,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Peripherals control module is secured",
			"material" = MATERIAL_STEEL),
		//7
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Peripherals control module is installed"),
		//8
		list("key"=/obj/item/weapon/circuitboard/mecha/odysseus/peripherals,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="Central control module is secured"),
		//9
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/crowbar,
			"desc"="Central control module is installed"),
		//10
		list("key"=/obj/item/weapon/circuitboard/mecha/odysseus/main,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The wiring is adjusted"),
		//11
		list("key"=/obj/item/weapon/wirecutters,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The wiring is added"),
		//12
		list("key"=/obj/item/stack/cable_coil,
			"backkey"=/obj/item/weapon/screwdriver,
			"desc"="The hydraulic systems are active."),
		//13
		list("key"=/obj/item/weapon/screwdriver,
			"backkey"=/obj/item/weapon/wrench,
			"desc"="The hydraulic systems are connected."),
		//14
		list("key"=/obj/item/weapon/wrench,
			"desc"="The hydraulic systems are disconnected.")
	)

	custom_action(index, diff, atom/used_atom, mob/user)
		if(!..())
			return 0

		//TODO: better messages.
		switch(index)
			if(14)
				user.visible_message(
					"[user] connects [holder] hydraulic systems",
					"You connect [holder] hydraulic systems."
				)
				holder.icon_state = "odysseus1"
			if(13)
				if(diff==FORWARD)
					user.visible_message(
						"[user] activates [holder] hydraulic systems.",
						"You activate [holder] hydraulic systems."
					)
					holder.icon_state = "odysseus2"
				else
					user.visible_message(
						"[user] disconnects [holder] hydraulic systems",
						"You disconnect [holder] hydraulic systems."
					)
					holder.icon_state = "odysseus0"
			if(12)
				if(diff==FORWARD)
					user.visible_message(
						"[user] adds the wiring to [holder].",
						"You add the wiring to [holder]."
					)
					holder.icon_state = "odysseus3"
				else
					user.visible_message(
						"[user] deactivates [holder] hydraulic systems.",
						"You deactivate [holder] hydraulic systems."
					)
					holder.icon_state = "odysseus1"
			if(11)
				if(diff==FORWARD)
					user.visible_message(
						"[user] adjusts the wiring of [holder].",
						"You adjust the wiring of [holder]."
					)
					holder.icon_state = "odysseus4"
				else
					user.visible_message(
						"[user] removes the wiring from [holder].",
						"You remove the wiring from [holder]."
					)
					new /obj/item/stack/cable_coil (get_turf(holder), 4)
					holder.icon_state = "odysseus2"
			if(10)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs the central control module into [holder].",
						"You install the central computer mainboard into [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "odysseus5"
				else
					user.visible_message(
						"[user] disconnects the wiring of [holder].",
						"You disconnect the wiring of [holder]."
					)
					holder.icon_state = "odysseus3"
			if(9)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures the mainboard.",
						"You secure the mainboard."
					)
					holder.icon_state = "odysseus6"
				else
					user.visible_message(
						"[user] removes the central control module from [holder].",
						"You remove the central computer mainboard from [holder]."
					)
					new /obj/item/weapon/circuitboard/mecha/odysseus/main(get_turf(holder))
					holder.icon_state = "odysseus4"
			if(8)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs the peripherals control module into [holder].",
						"You install the peripherals control module into [holder]."
					)
					qdel(used_atom)
					holder.icon_state = "odysseus7"
				else
					user.visible_message(
						"[user] unfastens the mainboard.",
						"You unfasten the mainboard."
					)
					holder.icon_state = "odysseus5"
			if(7)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures the peripherals control module.",
						"You secure the peripherals control module."
					)
					holder.icon_state = "odysseus8"
				else
					user.visible_message(
						"[user] removes the peripherals control module from [holder].",
						"You remove the peripherals control module from [holder]."
					)
					new /obj/item/weapon/circuitboard/mecha/odysseus/peripherals(get_turf(holder))
					holder.icon_state = "odysseus6"
			if(6)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs internal armor layer to [holder].",
						"You install internal armor layer to [holder]."
					)
					holder.icon_state = "odysseus9"
				else
					user.visible_message(
						"[user] unfastens the peripherals control module.",
						"You unfasten the peripherals control module."
					)
					holder.icon_state = "odysseus7"
			if(5)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures internal armor layer.",
						"You secure internal armor layer."
					)
					holder.icon_state = "odysseus10"
				else
					user.visible_message(
						"[user] pries internal armor layer from [holder].",
						"You prie internal armor layer from [holder]."
					)
					new /obj/item/stack/material/steel (get_turf(holder), 5)
					holder.icon_state = "odysseus8"
			if(4)
				if(diff==FORWARD)
					user.visible_message(
						"[user] welds internal armor layer to [holder].",
						"You weld the internal armor layer to [holder]."
					)
					holder.icon_state = "odysseus11"
				else
					user.visible_message(
						"[user] unfastens the internal armor layer.",
						"You unfasten the internal armor layer."
					)
					holder.icon_state = "odysseus9"
			if(3)
				if(diff==FORWARD)
					user.visible_message(
						"[user] installs [used_atom] layer to [holder].",
						"You install external reinforced armor layer to [holder]."
					)
					holder.icon_state = "odysseus12"
				else
					user.visible_message(
						"[user] cuts internal armor layer from [holder].",
						"You cut the internal armor layer from [holder]."
					)
					holder.icon_state = "odysseus10"
			if(2)
				if(diff==FORWARD)
					user.visible_message(
						"[user] secures external armor layer.",
						"You secure external reinforced armor layer."
					)
					holder.icon_state = "odysseus13"
				else
					var/obj/item/stack/material/plasteel/MS = new (get_turf(holder), 5)
					user.visible_message(
						"[user] pries [MS] from [holder].",
						"You prie [MS] from [holder]."
					)
					holder.icon_state = "odysseus11"
			if(1)
				if(diff==FORWARD)
					user.visible_message(
						"[user] welds external armor layer to [holder].",
						"You weld external armor layer to [holder]."
					)
					holder.icon_state = "odysseus14"
				else
					user.visible_message(
						"[user] unfastens the external armor layer.",
						"You unfasten the external armor layer."
					)
					holder.icon_state = "odysseus12"
		return 1