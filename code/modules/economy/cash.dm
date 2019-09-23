/obj/item/weapon/spacecash
	name = "0 Thaler"
	desc = "It's worth 0 Thalers."
	gender = PLURAL
	icon = 'icons/obj/items.dmi'
	icon_state = "spacecash1"
	opacity = 0
	density = 0
	anchored = 0.0
	force = 1.0
	throwforce = 1.0
	throw_speed = 1
	throw_range = 2
	w_class = ITEM_SIZE_TINY
	var/access = list()
	access = access_crate_cash
	var/worth = 0

/obj/item/weapon/spacecash/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W, /obj/item/weapon/spacecash))
		if(istype(W, /obj/item/weapon/spacecash/ewallet)) return 0

		var/obj/item/weapon/spacecash/bundle/bundle
		if(!istype(W, /obj/item/weapon/spacecash/bundle))
			var/obj/item/weapon/spacecash/cash = W
			user.drop_from_inventory(cash)
			bundle = new (src.loc)
			bundle.worth += cash.worth
			qdel(cash)
		else //is bundle
			bundle = W
		bundle.worth += src.worth
		bundle.update_icon()
		user.drop_from_inventory(src)
		user.drop_from_inventory(bundle)
		user.put_in_hands(bundle)
		user << SPAN_NOTE("You add [src.worth] Thalers worth of money to the bundles.<br>It holds [bundle.worth] Thalers now.")
		qdel(src)

/obj/item/weapon/spacecash/bundle
	name = "pile of thalers"
	icon_state = ""
	desc = "They are worth 0 Thalers."
	worth = 0

/obj/item/weapon/spacecash/bundle/update_icon()
	overlays.Cut()
	var/sum = src.worth
	var/num = 0
	for(var/i in list(1000,500,200,100,50,20,10,1))
		while(sum >= i && num < 50)
			sum -= i
			num++
			var/image/banknote = image('icons/obj/items.dmi', "spacecash[i]")
			var/matrix/M = matrix()
			M.Translate(rand(-6, 6), rand(-4, 8))
			M.Turn(pick(-45, -27.5, 0, 0, 0, 0, 0, 0, 0, 27.5, 45))
			banknote.transform = M
			src.overlays += banknote
	if(num == 0) // Less than one thaler, let's just make it look like 1 for ease
		var/image/banknote = image('icons/obj/items.dmi', "spacecash1")
		var/matrix/M = matrix()
		M.Translate(rand(-6, 6), rand(-4, 8))
		M.Turn(pick(-45, -27.5, 0, 0, 0, 0, 0, 0, 0, 27.5, 45))
		banknote.transform = M
		src.overlays += banknote

	src.desc = "They are worth [worth] Thalers."
	if(overlays.len <= 2)
		w_class = ITEM_SIZE_TINY
	else
		w_class = ITEM_SIZE_SMALL

/obj/item/weapon/spacecash/bundle/attack_self()
	var/amount = input(usr, "How many Thalers do you want to take? (0 to [src.worth])", "Take Money", 20) as num
	amount = round(Clamp(amount, 0, src.worth))
	if(amount==0) return 0

	src.worth -= amount
	src.update_icon()
	if(!worth)
		usr.drop_from_inventory(src)
	if(amount in list(1000,500,200,100,50,20,1))
		var/cashtype = text2path("/obj/item/weapon/spacecash/c[amount]")
		var/obj/cash = new cashtype (usr.loc)
		usr.put_in_hands(cash)
	else
		var/obj/item/weapon/spacecash/bundle/bundle = new (usr.loc)
		bundle.worth = amount
		bundle.update_icon()
		usr.put_in_hands(bundle)
	if(!worth)
		qdel(src)

/obj/item/weapon/spacecash/c1
	name = "1 Thaler"
	icon_state = "spacecash1"
	desc = "It's worth 1 credit."
	worth = 1

/obj/item/weapon/spacecash/c10
	name = "10 Thaler"
	icon_state = "spacecash10"
	desc = "It's worth 10 Thalers."
	worth = 10

/obj/item/weapon/spacecash/c20
	name = "20 Thaler"
	icon_state = "spacecash20"
	desc = "It's worth 20 Thalers."
	worth = 20

/obj/item/weapon/spacecash/c50
	name = "50 Thaler"
	icon_state = "spacecash50"
	desc = "It's worth 50 Thalers."
	worth = 50

/obj/item/weapon/spacecash/c100
	name = "100 Thaler"
	icon_state = "spacecash100"
	desc = "It's worth 100 Thalers."
	worth = 100

/obj/item/weapon/spacecash/c200
	name = "200 Thaler"
	icon_state = "spacecash200"
	desc = "It's worth 200 Thalers."
	worth = 200

/obj/item/weapon/spacecash/c500
	name = "500 Thaler"
	icon_state = "spacecash500"
	desc = "It's worth 500 Thalers."
	worth = 500

/obj/item/weapon/spacecash/c1000
	name = "1000 Thaler"
	icon_state = "spacecash1000"
	desc = "It's worth 1000 Thalers."
	worth = 1000

proc/spawn_money(var/sum, spawnloc, mob/living/carbon/human/human_user as mob)
	if(sum in list(1000,500,200,100,50,20,10,1))
		var/cash_type = text2path("/obj/item/weapon/spacecash/c[sum]")
		var/obj/cash = new cash_type (usr.loc)
		human_user.put_in_hands(cash)
	else
		var/obj/item/weapon/spacecash/bundle/bundle = new (spawnloc)
		bundle.worth = sum
		bundle.update_icon()
		if(human_user)
			human_user.put_in_hands(bundle)
	return

/obj/item/weapon/spacecash/ewallet
	name = "Charge card"
	icon_state = "efundcard"
	desc = "A card that holds an amount of money."
	var/owner_name = "" //So the ATM can set it so the EFTPOS can put a valid name on transactions.

/obj/item/weapon/spacecash/ewallet/examine(mob/user, return_dist=1)
	. = ..()
	if (.<=2)
		user << SPAN_NOTE("Charge card's owner: [src.owner_name]. Thalers remaining: [src.worth].")

/obj/item/weapon/spacecash/ewallet/lotto
	name = "lottery card"
	desc = "A scratch-action charge card that contains a variable amount of money."
	worth = 0
	var/scratched = 0

/obj/item/weapon/spacecash/ewallet/lotto/attack_self(mob/user)
	if(!scratched)
		user << "<span class='notice'>You initiate the simulated scratch action process on the charge card. . .</span>"
		if(do_after(user,5))
			switch(rand(1,100))
				if(1 to 46)
					worth = rand(0,200)
					user << "<span class='notice'>The card reads [worth]. Not your lucky day!</span>"
				if(47 to 68)
					worth = 200
					user << "<span class='notice'>The card reads [worth]. At least you broke even.</span>"
				if(69 to 84)
					worth = pick(200,300,400,500)
					user << "<span class='notice'>The card reads [worth]. That's a pretty penny!</span>"
				if(85 to 94)
					worth = pick(500,600,700,800,900,1000)
					user << "<span class='notice'>The card reads [worth]. Your luck is running high!</span>"
				if(95 to 99)
					worth = pick(1000,2000,3000,4000,5000,6000,7000,8000,9000)
					user << "<span class='notice'>The card reads [worth]. You're rich!</span>"
				if(100)
					worth = pick(10000,20000,30000,40000,50000)
					user << "<span class='notice'>The card reads [worth]. You're blessed!</span>"
				else
					worth = 0
					user << "<span class='notice'>The card reads [worth]. Not your lucky day!</span>"
			scratched = 1
			owner_name = user.name