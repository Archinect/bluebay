/*
Destructive Analyzer

It is used to destroy hand-held objects and advance technological research. Controls are in the linked R&D console.

Note: Must be placed within 3 tiles of the R&D Console
*/

/obj/machinery/r_n_d/destructive_analyzer
	name = "destructive analyzer"
	icon_state = "d_analyzer"
	circuit = /obj/item/weapon/circuitboard/destructive_analyzer
	var/obj/item/weapon/loaded_item = null
	var/decon_mod = 1
	var/min_reliability = 90

	use_power = 1
	idle_power_usage = 30
	active_power_usage = 2500

/obj/machinery/r_n_d/destructive_analyzer/RefreshParts()
	var/T = 0
	for(var/obj/item/weapon/stock_parts/S in component_parts)
		T += S.rating
	decon_mod = T * 0.1
	min_reliability = 93 - T

/obj/machinery/r_n_d/destructive_analyzer/meteorhit()
	qdel(src)
	return

/obj/machinery/r_n_d/destructive_analyzer/update_icon()
	if(panel_open)
		icon_state = "d_analyzer_t"
	else if(loaded_item)
		icon_state = "d_analyzer_l"
	else
		icon_state = "d_analyzer"

/obj/machinery/r_n_d/destructive_analyzer/attackby(var/obj/item/O as obj, var/mob/user as mob)
	if(busy)
		user << SPAN_NOTE("\The [src] is busy right now.")
		return
	if(default_deconstruction_screwdriver(user, O))
		if(linked_console)
			linked_console.linked_destroy = null
			linked_console = null
		return
	if(default_deconstruction_crowbar(user, O))
		return
	if(default_part_replacement(user, O))
		return
	if(panel_open)
		user << SPAN_NOTE("You can't load \the [src] while it's opened.")
		return 1
	if(!linked_console)
		user << SPAN_NOTE("\The [src] must be linked to an R&D console first!")
		return
	if(istype(O, /obj/item) && !loaded_item)
		if(isrobot(user)) //Don't put your module items in there!
			return
		if(!O.origin_tech)
			user << SPAN_NOTE("This doesn't seem to have a tech origin!")
			return
		if(O.origin_tech.len == 0)
			user << SPAN_NOTE("You cannot deconstruct this item!")
			return
		if(O.reliability < min_reliability && O.crit_fail == 0)
			usr << "<span class='warning'>Item is neither reliable enough nor broken enough to learn from.</span>"
			return
		busy = 1
		loaded_item = O
		if(user.unEquip(O, src))
			user << SPAN_NOTE("You add \the [O] to \the [src]!")
			flick("d_analyzer_la", src)
			spawn(10)
				update_icon()
				busy = 0
			return 1
	return
