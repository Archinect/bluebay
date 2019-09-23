/obj/item/weapon/material/star
	name = "shuriken"
	desc = "A sharp, perfectly weighted piece of metal."
	icon_state = "star"
	force_divisor = 0.1 // 6 with hardness 60 (steel)
	thrown_force_divisor = 0.75 // 15 with weight 20 (steel)
	throw_speed = 10
	throw_range = 15
	sharp = 1
	edge =  1
	randpixel = 12

/obj/item/weapon/material/star/throw_impact(atom/hit_atom)
	..()
	if(material.radioactivity>0 && isliving(hit_atom))
		var/mob/living/M = hit_atom
		M.adjustToxLoss(rand(20,40))

/obj/item/weapon/material/star/ninja
	default_material = MATERIAL_URANIUM