
/**
 *  A vending machine
 */
/obj/machinery/vending
	name = "Vendomat"
	desc = "A generic vending machine."
	icon = 'icons/obj/vending.dmi'
	icon_state = "generic"
	layer = 2.9
	anchored = 1
	density = 1

	var/icon_vend //Icon_state when vending
	var/icon_deny //Icon_state when denying access

	// Power
	use_power = 1
	idle_power_usage = 10
	var/vend_power_usage = 150 //actuators and stuff

	// Vending-related
	var/active = 1 //No sales pitches if off!
	var/vend_ready = 1 //Are we ready to vend?? Is it time??
	var/vend_delay = 10 //How long does it take to vend?
	var/categories = CAT_NORMAL // Bitmask of cats we're currently showing
	var/datum/stored_items/vending_products/currently_vending = null // What we're requesting payment for right now
	var/status_message = "" // Status screen messages like "insufficient funds", displayed in NanoUI
	var/status_error = 0 // Set to 1 if status_message is an error

	/*
		Variables used to initialize the product list
		These are used for initialization only, and so are optional if
		product_records is specified
	*/
	var/list/products	= list() // For each, use the following pattern:
	var/list/contraband	= list() // list(/type/path = amount,/type/path2 = amount2)
	var/list/premium 	= list() // No specified amount = only one in stock
	var/list/prices     = list() // Prices for each item, list(/type/path = price), items not in the list don't have a price.

	// List of vending_product items available.
	var/list/product_records = list()

	//Strings of small ad messages in the vending screen
	var/list/ads_list = list()
	// Stuff relating vocalizations
	var/list/slogan_list = list()
	var/shut_up = 1 //Stop spouting those godawful pitches!
	var/vend_reply //Thank you for shopping!
	var/last_reply = 0
	var/last_slogan = 0 //When did we last pitch?
	var/slogan_delay = 6000 //How long until we can pitch again?

	// Things that can go wrong
	emagged = 0 //Ignores if somebody doesn't have card access to that machine.
	var/seconds_electrified = 0 //Shock customers like an airlock.
	var/shoot_inventory = 0 //Fire items at customers! We're broken!

	var/scan_id = 1
	var/obj/item/weapon/coin/coin
	var/datum/wires/vending/wires = null

/obj/machinery/vending/New()
	..()
	wires = new(src)
	spawn(4)
		// So not all machines speak at the exact same time.
		// The first time this machine says something will be at slogantime + this random value,
		// so if slogantime is 10 minutes, it will say it at somewhere between 10 and 20 minutes after the machine is crated.
		src.last_slogan = world.time + rand(0, slogan_delay)

		src.build_inventory()
		power_change()

/**
 *  Build src.produdct_records from the products lists
 *
 *  src.products, src.contraband, src.premium, and src.prices allow specifying
 *  products that the vending machine is to carry without manually populating
 *  src.product_records.
 */
/obj/machinery/vending/proc/build_inventory()
	var/list/all_products = list(
		list(src.products, CAT_NORMAL),
		list(src.contraband, CAT_HIDDEN),
		list(src.premium, CAT_COIN))

	for(var/current_list in all_products)
		var/category = current_list[2]

		for(var/entry in current_list[1])
			var/datum/stored_items/vending_products/product = new/datum/stored_items/vending_products(src, entry)

			product.price = (entry in src.prices) ? src.prices[entry] : 0
			product.amount = (current_list[1][entry]) ? current_list[1][entry] : 1
			product.category = category

			src.product_records.Add(product)

/obj/machinery/vending/Destroy()
	qdel(wires)
	wires = null
	qdel(coin)
	coin = null
	for(var/datum/stored_items/vending_products/R in product_records)
		qdel(R)
	product_records = null
	return ..()

/obj/machinery/vending/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
			return
		if(2.0)
			if (prob(50))
				qdel(src)
				return
		if(3.0)
			if (prob(25))
				spawn(0)
					src.malfunction()
					return
				return
		else
	return

/obj/machinery/vending/blob_act()
	if (prob(50))
		spawn(0)
			src.malfunction()
			qdel(src)
		return

	return

/obj/machinery/vending/emag_act(var/remaining_charges, var/mob/user)
	if (!emagged)
		src.emagged = 1
		user << "You short out the product lock on \the [src]"
		return 1

/obj/machinery/vending/attackby(obj/item/weapon/W as obj, mob/user as mob)

	var/obj/item/weapon/card/id/I = W.GetID()

	if (currently_vending && vendor_account && !vendor_account.suspended)
		var/paid = 0
		var/handled = 0

		if (I) //for IDs and PDAs and wallets with IDs
			paid = pay_with_card(I,W)
			handled = 1
		else if (istype(W, /obj/item/weapon/spacecash/ewallet))
			var/obj/item/weapon/spacecash/ewallet/C = W
			paid = pay_with_ewallet(C)
			handled = 1
		else if (istype(W, /obj/item/weapon/spacecash/bundle))
			var/obj/item/weapon/spacecash/bundle/C = W
			paid = pay_with_cash(C)
			handled = 1

		if(paid)
			src.vend(currently_vending, usr)
			return
		else if(handled)
			SSnanoui.update_uis(src)
			return // don't smack that machine with your 2 thalers

	if (I || istype(W, /obj/item/weapon/spacecash))
		attack_hand(user)
		return
	else if(istype(W, /obj/item/weapon/screwdriver))
		src.panel_open = !src.panel_open
		user << "You [panel_open ? "open" : "close"] the maintenance panel."
		src.overlays.Cut()
		if(src.panel_open)
			src.overlays += image(src.icon, "[initial(icon_state)]-panel")

		SSnanoui.update_uis(src)  // Speaker switch is on the main UI, not wires UI
		return
	else if(istype(W, /obj/item/device/multitool)||istype(W, /obj/item/weapon/wirecutters))
		if(src.panel_open)
			attack_hand(user)
		return
	else if(istype(W, /obj/item/weapon/coin) && premium.len > 0)
		user.drop_from_inventory(W, src)
		coin = W
		categories |= CAT_COIN
		user << SPAN_NOTE("You insert \the [W] into \the [src].")
		SSnanoui.update_uis(src)
		return
	else if(istype(W, /obj/item/weapon/wrench))
		playsound(src.loc, 'sound/items/Ratchet.ogg', 100, 1)
		if(anchored)
			user.visible_message("[user] begins unsecuring \the [src] from the floor.", "You start unsecuring \the [src] from the floor.")
		else
			user.visible_message("[user] begins securing \the [src] to the floor.", "You start securing \the [src] to the floor.")

		if(do_after(user, 20, src))
			if(!src) return
			user << SPAN_NOTE("You [anchored? "un" : ""]secured \the [src]!")
			anchored = !anchored
		return

	else

		for(var/datum/stored_items/vending_products/R in product_records)
			if(istype(W, R.item_path))
				stock(W, R, user)
				return 1
		..()

/**
 *  Receive payment with cashmoney.
 */
/obj/machinery/vending/proc/pay_with_cash(var/obj/item/weapon/spacecash/bundle/cashmoney)
	if(currently_vending.price > cashmoney.worth)
		// This is not a status display message, since it's something the character
		// themselves is meant to see BEFORE putting the money in
		usr << "\icon[cashmoney] <span class='warning'>That is not enough money.</span>"
		return 0

	visible_message("<span class='info'>\The [usr] inserts some cash into \the [src].</span>")
	cashmoney.worth -= currently_vending.price

	if(cashmoney.worth <= 0)
		usr.drop_from_inventory(cashmoney)
		qdel(cashmoney)
	else
		cashmoney.update_icon()

	// Vending machines have no idea who paid with cash
	credit_purchase("(cash)")
	return 1

/**
 * Scan a chargecard and deduct payment from it.
 *
 * Takes payment for whatever is the currently_vending item. Returns 1 if
 * successful, 0 if failed.
 */
/obj/machinery/vending/proc/pay_with_ewallet(var/obj/item/weapon/spacecash/ewallet/wallet)
	visible_message("<span class='info'>\The [usr] swipes \the [wallet] through \the [src].</span>")
	if(currently_vending.price > wallet.worth)
		src.status_message = "Insufficient funds on chargecard."
		src.status_error = 1
		return 0
	else
		wallet.worth -= currently_vending.price
		credit_purchase("[wallet.owner_name] (chargecard)")
		return 1

/**
 * Scan a card and attempt to transfer payment from associated account.
 *
 * Takes payment for whatever is the currently_vending item. Returns 1 if
 * successful, 0 if failed
 */
/obj/machinery/vending/proc/pay_with_card(var/obj/item/weapon/card/id/I, var/obj/item/ID_container)
	if(I==ID_container || ID_container == null)
		visible_message("<span class='info'>\The [usr] swipes \the [I] through \the [src].</span>")
	else
		visible_message("<span class='info'>\The [usr] swipes \the [ID_container] through \the [src].</span>")
	var/datum/money_account/customer_account = get_account(I.associated_account_number)
	if (!customer_account)
		src.status_message = "Error: Unable to access account. Please contact technical support if problem persists."
		src.status_error = 1
		return 0

	if(customer_account.suspended)
		src.status_message = "Unable to access account: account suspended."
		src.status_error = 1
		return 0

	// Have the customer punch in the PIN before checking if there's enough money. Prevents people from figuring out acct is
	// empty at high security levels
	if(customer_account.security_level != 0) //If card requires pin authentication (ie seclevel 1 or 2)
		var/attempt_pin = input("Enter pin code", "Vendor transaction") as num
		customer_account = attempt_account_access(I.associated_account_number, attempt_pin, 2)

		if(!customer_account)
			src.status_message = "Unable to access account: incorrect credentials."
			src.status_error = 1
			return 0

	if(currently_vending.price > customer_account.money)
		src.status_message = "Insufficient funds in account."
		src.status_error = 1
		return 0
	else
		// Okay to move the money at this point

		// debit money from the purchaser's account
		customer_account.money -= currently_vending.price

		// create entry in the purchaser's account log
		var/datum/transaction/T = new()
		T.target_name = "[vendor_account.owner_name] (via [src.name])"
		T.purpose = "Purchase of [currently_vending.item_name]"
		if(currently_vending.price > 0)
			T.amount = "([currently_vending.price])"
		else
			T.amount = "[currently_vending.price]"
		T.source_terminal = src.name
		T.date = current_date_string
		T.time = worldtime2text()
		customer_account.transaction_log.Add(T)

		// Give the vendor the money. We use the account owner name, which means
		// that purchases made with stolen/borrowed card will look like the card
		// owner made them
		credit_purchase(customer_account.owner_name)
		return 1

/**
 *  Add money for current purchase to the vendor account.
 *
 *  Called after the money has already been taken from the customer.
 */
/obj/machinery/vending/proc/credit_purchase(var/target as text)
	vendor_account.money += currently_vending.price

	var/datum/transaction/T = new()
	T.target_name = target
	T.purpose = "Purchase of [currently_vending.item_name]"
	T.amount = "[currently_vending.price]"
	T.source_terminal = src.name
	T.date = current_date_string
	T.time = worldtime2text()
	vendor_account.transaction_log.Add(T)

/obj/machinery/vending/attack_ai(mob/user as mob)
	return attack_hand(user)

/obj/machinery/vending/attack_hand(mob/user as mob)
	if(stat & (BROKEN|NOPOWER))
		return

	if(src.seconds_electrified != 0)
		if(src.shock(user, 100))
			return

	wires.Interact(user)
	ui_interact(user)

/**
 *  Display the NanoUI window for the vending machine.
 *
 *  See NanoUI documentation for details.
 */
/obj/machinery/vending/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	user.set_machine(src)

	var/list/data = list()
	if(currently_vending)
		data["mode"] = 1
		data["product"] = currently_vending.item_name
		data["price"] = currently_vending.price
		data["message_err"] = 0
		data["message"] = src.status_message
		data["message_err"] = src.status_error
	else
		data["mode"] = 0
		var/list/listed_products = list()

		for(var/key = 1 to src.product_records.len)
			var/datum/stored_items/vending_products/I = src.product_records[key]

			if(!(I.category & src.categories))
				continue

			listed_products.Add(list(list(
				"key" = key,
				"name" = I.item_name,
				"price" = I.price,
				"color" = I.display_color,
				"amount" = I.get_amount())))

		data["products"] = listed_products

	if(src.coin)
		data["coin"] = src.coin.name

	if(src.panel_open)
		data["panel"] = 1
		data["speaker"] = src.shut_up ? 0 : 1
	else
		data["panel"] = 0

	ui = SSnanoui.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "vending_machine.tmpl", src.name, 440, 600)
		ui.set_initial_data(data)
		ui.open()

/obj/machinery/vending/Topic(href, href_list)
	if(stat & (BROKEN|NOPOWER))
		return
	if(usr.stat || usr.restrained())
		return

	if(href_list["remove_coin"] && !issilicon(usr))
		if(!coin)
			usr << "There is no coin in this machine."
			return

		usr.put_in_hands(coin)
		usr << SPAN_NOTE("You remove the [coin] from the [src]")
		coin = null
		categories &= ~CAT_COIN

	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(src.loc, /turf))))
		if ((href_list["vend"]) && (src.vend_ready) && (!currently_vending))
			if((!allowed(usr)) && !emagged && scan_id)	//For SECURE VENDING MACHINES YEAH
				usr << "<span class='warning'>Access denied.</span>"	//Unless emagged of course
				flick(icon_deny,src)
				return

			var/key = text2num(href_list["vend"])
			var/datum/stored_items/vending_products/R = product_records[key]

			// This should not happen unless the request from NanoUI was bad
			if(!(R.category & src.categories))
				return

			if(R.price <= 0)
				src.vend(R, usr)
			else if(issilicon(usr)) //If the item is not free, provide feedback if a synth is trying to buy something.
				usr << "<span class='danger'>Artificial unit recognized.  Artificial units cannot complete this transaction.  Purchase canceled.</span>"
				return
			else
				src.currently_vending = R
				if(!vendor_account || vendor_account.suspended)
					src.status_message = "This machine is currently unable to process payments due to problems with the associated account."
					src.status_error = 1
				else
					src.status_message = "Please swipe a card or insert cash to pay for the item."
					src.status_error = 0

		else if (href_list["cancelpurchase"])
			src.currently_vending = null

		else if ((href_list["togglevoice"]) && (src.panel_open))
			src.shut_up = !src.shut_up

		src.add_fingerprint(usr)
		SSnanoui.update_uis(src)

/obj/machinery/vending/proc/vend(var/datum/stored_items/vending_products/R, mob/user)
	if((!allowed(usr)) && !emagged && scan_id)	//For SECURE VENDING MACHINES YEAH
		usr << "<span class='warning'>Access denied.</span>"	//Unless emagged of course
		flick(src.icon_deny,src)
		return
	src.vend_ready = 0 //One thing at a time!!
	src.status_message = "Vending..."
	src.status_error = 0
	SSnanoui.update_uis(src)

	if (R.category & CAT_COIN)
		if(!coin)
			user << SPAN_NOTE("You need to insert a coin to get this item.")
			return
		if(coin.string_attached)
			if(prob(50))
				user << SPAN_NOTE("You successfully pull the coin out before \the [src] could swallow it.")
			else
				user << SPAN_NOTE("You weren't able to pull the coin out fast enough, the machine ate it, string and all.")
				qdel(coin)
				coin = null
				categories &= ~CAT_COIN
		else
			qdel(coin)
			coin = null
			categories &= ~CAT_COIN

	if(((src.last_reply + (src.vend_delay + 200)) <= world.time) && src.vend_reply)
		spawn(0)
			src.speak(src.vend_reply)
			src.last_reply = world.time

	use_power(vend_power_usage)	//actuators and stuff
	if (src.icon_vend) //Show the vending animation if needed
		flick(src.icon_vend,src)
	spawn(src.vend_delay)
		R.get_product(get_turf(src))
		if(prob(1))
			sleep(3)
			if(R.get_product(get_turf(src)))
				src.visible_message(SPAN_NOTE("\The [src] clunks as it vends an additional item."))

		src.status_message = ""
		src.status_error = 0
		src.vend_ready = 1
		currently_vending = null
		SSnanoui.update_uis(src)

/**
 * Add item to the machine
 *
 * Checks if item is vendable in this machine should be performed before
 * calling. W is the item being inserted, R is the associated vending_product entry.
 */
/obj/machinery/vending/proc/stock(obj/item/weapon/W, var/datum/stored_items/vending_products/R, var/mob/user)
	if(!user.unEquip(W))
		return

	user << SPAN_NOTE("You stock \the [src] with \a [R.item_name]")
	R.add_product(W)

	SSnanoui.update_uis(src)

/obj/machinery/vending/process()
	if(stat & (BROKEN|NOPOWER))
		return

	if(!src.active)
		return

	if(src.seconds_electrified > 0)
		src.seconds_electrified--

	//Pitch to the people!  Really sell it!
	if(((src.last_slogan + src.slogan_delay) <= world.time) && (src.slogan_list.len > 0) && (!src.shut_up) && prob(5))
		var/slogan = pick(src.slogan_list)
		src.speak(slogan)
		src.last_slogan = world.time

	if(src.shoot_inventory && prob(2))
		src.throw_item()

	return

/obj/machinery/vending/proc/speak(var/message)
	if(stat & NOPOWER)
		return

	if (!message)
		return

	for(var/mob/O in hearers(src, null))
		O.show_message("<span class='game say'><span class='name'>\The [src]</span> beeps, \"[message]\"</span>",2)
	return

/obj/machinery/vending/update_icon()
	if(stat & BROKEN)
		icon_state = "[initial(icon_state)]-broken"
	else if( !(stat & NOPOWER) )
		icon_state = initial(icon_state)
	else
		spawn(rand(0, 15))
			src.icon_state = "[initial(icon_state)]-off"

//Oh no we're malfunctioning!  Dump out some product and break.
/obj/machinery/vending/proc/malfunction()
	for(var/datum/stored_items/vending_products/R in src.product_records)
		while(R.get_amount()>0)
			R.get_product(loc)
		break

	stat |= BROKEN
	src.icon_state = "[initial(icon_state)]-broken"
	return

//Somebody cut an important wire and now we're following a new definition of "pitch."
/obj/machinery/vending/proc/throw_item()
	var/obj/dispensed_item = null
	for(var/datum/stored_items/vending_products/R in src.product_records)
		dispensed_item = R.get_product(loc)
		if (dispensed_item)
			break

	if (!dispensed_item)
		return 0

	dispensed_item.forceMove(get_turf(src))
	visible_message("<span class='warning'>\The [src] shudders and \a [dispensed_item] falls out!</span>")
	return 1

/*
 * Vending machine types
 */

/*

/obj/machinery/vending/[vendors name here]   // --vending machine template   :)
	name = ""
	desc = ""
	icon = ''
	icon_state = ""
	vend_delay = 15
	products = list()
	contraband = list()
	premium = list()

*/

/obj/machinery/vending/boozeomat
	name = "Booze-O-Mat"
	desc = "A technological marvel, supposedly able to mix just the mixture you'd like to drink the moment you ask for one."
	icon_state = "boozeomat"
	icon_deny = "boozeomat-deny"
	products = list(
		/obj/item/weapon/reagent_containers/glass/drinks/drinkingglass = 30,
		/obj/item/weapon/reagent_containers/glass/drinks/bottle/whiskey = 5,
		/obj/item/weapon/reagent_containers/glass/drinks/bottle/vodka = 5,
		/obj/item/weapon/reagent_containers/glass/drinks/bottle/gin = 5,
		/obj/item/weapon/reagent_containers/glass/drinks/bottle/rum = 5,
		/obj/item/weapon/reagent_containers/glass/drinks/bottle/tequilla = 5,
		/obj/item/weapon/reagent_containers/glass/drinks/bottle/vermouth = 5,
		/obj/item/weapon/reagent_containers/glass/drinks/bottle/cognac = 5,
		/obj/item/weapon/reagent_containers/glass/drinks/bottle/kahlua = 5,
		/obj/item/weapon/reagent_containers/glass/drinks/bottle/wine = 5,
		/obj/item/weapon/reagent_containers/glass/drinks/bottle/small/beer = 6,
		/obj/item/weapon/reagent_containers/glass/drinks/bottle/small/ale = 6,
		/obj/item/weapon/reagent_containers/glass/drinks/orangejuice = 4,
		/obj/item/weapon/reagent_containers/glass/drinks/bottle/limejuice = 4,
		/obj/item/weapon/reagent_containers/glass/drinks/bottle/cream = 4,
		/obj/item/weapon/reagent_containers/glass/drinks/cans/cola = 8,
		/obj/item/weapon/reagent_containers/glass/drinks/cans/sodawater = 15,
		/obj/item/weapon/reagent_containers/glass/drinks/ice = 9,
		/obj/item/weapon/reagent_containers/glass/drinks/cans/tonic = 8,
		/obj/item/weapon/reagent_containers/glass/drinks/bottle/tomatojuice = 4,
		/obj/item/weapon/reagent_containers/glass/drinks/flask/barflask = 2,
		/obj/item/weapon/reagent_containers/glass/drinks/flask/vacuumflask = 2,
		/obj/item/weapon/reagent_containers/glass/drinks/bottle/absinthe = 2,
		/obj/item/weapon/reagent_containers/glass/drinks/bottle/bluecuracao = 2,
		/obj/item/weapon/reagent_containers/glass/drinks/bottle/grenadine = 5,
		/obj/item/weapon/reagent_containers/glass/drinks/bottle/melonliquor = 4,
	)
	contraband = list(
		/obj/item/weapon/reagent_containers/glass/drinks/tea = 10
	)
	vend_delay = 15
	idle_power_usage = 211 //refrigerator - believe it or not, this is actually the average power consumption of a refrigerated vending machine according to NRCan.
	slogan_list = list(
		"Alcohol is humanity's friend. Would you abandon a friend?",
		"I hope nobody asks me for a bloody cup o' tea...",
		"Is nobody thirsty on this station?",
		"Quite delighted to serve you!",
	)
	ads_list = list(
		"Drink up!", "Booze is good for you!",
		"Alcohol is humanity's best friend.",
		"Quite delighted to serve you!",
		"Care for a nice, cold beer?",
		"Nothing cures you like booze!",
		"Have a sip!", "Have a drink!", "Have a beer!",
		"Beer is good for you!",
		"Only the finest alcohol!",
		"Best quality booze since 2053!",
		"Award-winning wine!",
		"Maximum alcohol!",
		"Man loves beer.",
		"A toast for progress!"
	)
	req_access = list(access_bar)

/obj/machinery/vending/assist
	products = list(
		/obj/item/device/assembly/prox_sensor = 5,
		/obj/item/device/assembly/signaler = 4,
		/obj/item/device/assembly/igniter = 3,
		/obj/item/weapon/cartridge/signal = 4,
		/obj/item/weapon/wirecutters = 1,
	)
	contraband = list(/obj/item/device/flashlight = 5,/obj/item/device/assembly/timer = 2)
	ads_list = list(
		"Only the finest!",
		"Have some tools.",
		"The most robust equipment.",
		"The finest gear in space!"
	)

/obj/machinery/vending/assist/antag
	name = "SyndieVend"
	contraband = list()
	products = list(
		/obj/item/device/assembly/prox_sensor = 4,
		/obj/item/device/assembly/prox_sensor = 5,
		/obj/item/clothing/glasses/sunglasses = 4,
		/obj/item/device/assembly/signaler = 4,
		/obj/item/weapon/cartridge/signal = 4,
		/obj/item/device/assembly/infra = 4,
		/obj/item/weapon/handcuffs = 8,
		/obj/item/device/flash = 4,
	)

/obj/machinery/vending/coffee
	name = "Hot Drinks machine"
	desc = "A vending machine which dispenses hot drinks."
	ads_list = list(
		"Have a drink!",
		"Drink up!",
		"It's good for you!",
		"Would you like a hot joe?",
		"I'd kill for some coffee!",
		"The best beans in the galaxy.",
		"Only the finest brew for you.",
		"Mmmm. Nothing like a coffee.",
		"I like coffee, don't you?",
		"Coffee helps you work!",
		"Try some tea.",
		"We hope you like the best!",
		"Try our new chocolate!",
		"Admin conspiracies"
	)
	icon_state = "coffee"
	icon_vend = "coffee-vend"
	vend_delay = 34
	idle_power_usage = 211 //refrigerator - believe it or not, this is actually the average power consumption of a refrigerated vending machine according to NRCan.
	vend_power_usage = 85000 //85 kJ to heat a 250 mL cup of coffee
	products = list(
		/obj/item/weapon/reagent_containers/glass/drinks/h_chocolate = 25,
		/obj/item/weapon/reagent_containers/glass/drinks/coffee = 25,
		/obj/item/weapon/reagent_containers/glass/drinks/tea = 25
	)
	contraband = list(/obj/item/weapon/reagent_containers/glass/drinks/ice = 10)
	prices = list(
		/obj/item/weapon/reagent_containers/glass/drinks/h_chocolate = 75,
		/obj/item/weapon/reagent_containers/glass/drinks/coffee = 60,
		/obj/item/weapon/reagent_containers/glass/drinks/tea = 45
	)




/obj/machinery/vending/snack
	name = "Getmore Chocolate Corp"
	desc = "A snack machine courtesy of the Getmore Chocolate Corporation, based out of Mars."
	slogan_list = list(
		"Try our new nougat bar!",
		"Twice the calories for half the price!"
	)
	ads_list = list(
		"The healthiest!",
		"Award-winning chocolate bars!",
		"Mmm! So good!",
		"Oh my god it's so juicy!",
		"Have a snack.",
		"Snacks are good for you!",
		"Have some more Getmore!",
		"Best quality snacks straight from mars.",
		"We love chocolate!",
		"Try our new jerky!"
	)
	icon_state = "snack"
	products = list(
		/obj/item/weapon/reagent_containers/food/snacks/cheesiehonkers = 6,
		/obj/item/weapon/reagent_containers/food/snacks/spacetwinkie = 6,
		/obj/item/weapon/reagent_containers/food/snacks/tastybread = 6,
		/obj/item/weapon/reagent_containers/glass/drinks/dry_ramen = 6,
		/obj/item/weapon/reagent_containers/food/snacks/no_raisin = 6,
		/obj/item/weapon/reagent_containers/food/snacks/sosjerky = 6,
		/obj/item/weapon/reagent_containers/food/snacks/candy = 6,
		/obj/item/weapon/reagent_containers/food/snacks/chips =6,
	)
	contraband = list(
		/obj/item/weapon/reagent_containers/food/snacks/skrellsnacks = 3,
		/obj/item/weapon/reagent_containers/food/snacks/syndicake = 6,
	)
	prices = list(
		/obj/item/weapon/reagent_containers/food/snacks/cheesiehonkers = 60,
		/obj/item/weapon/reagent_containers/food/snacks/spacetwinkie = 40,
		/obj/item/weapon/reagent_containers/glass/drinks/dry_ramen = 110,
		/obj/item/weapon/reagent_containers/food/snacks/tastybread = 60,
		/obj/item/weapon/reagent_containers/food/snacks/no_raisin = 90,
		/obj/item/weapon/reagent_containers/food/snacks/sosjerky = 40,
		/obj/item/weapon/reagent_containers/food/snacks/chips = 75,
		/obj/item/weapon/reagent_containers/food/snacks/candy = 20,
	)

/obj/machinery/vending/snack/wallmounted
	icon_state = "snack_wall"


/obj/machinery/vending/cola
	name = "Robust Softdrinks"
	desc = "A softdrink vendor provided by Robust Industries, LLC."
	icon_state = "Cola_Machine"
	slogan_list = list(
		"Robust Softdrinks: More robust than a toolbox to the head!"
	)
	ads_list = list(
		"Refreshing!",
		"Hope you're thirsty!",
		"Over 1 million drinks sold!;Thirsty? Why not cola?",
		"Please, have a drink!",
		"Drink up!",
		"The best drinks in space."
	)
	products = list(
		/obj/item/weapon/reagent_containers/glass/drinks/cans/space_mountain_wind = 10,
		/obj/item/weapon/reagent_containers/glass/drinks/cans/waterbottle = 10,
		/obj/item/weapon/reagent_containers/glass/drinks/cans/grape_juice = 10,
		/obj/item/weapon/reagent_containers/glass/drinks/cans/iced_tea = 10,
		/obj/item/weapon/reagent_containers/glass/drinks/cans/space_up = 10,
		/obj/item/weapon/reagent_containers/glass/drinks/cans/starkist = 10,
		/obj/item/weapon/reagent_containers/glass/drinks/cans/dr_gibb = 10,
		/obj/item/weapon/reagent_containers/glass/drinks/cans/cola = 10,
	)
	contraband = list(
		/obj/item/weapon/reagent_containers/glass/drinks/cans/thirteenloko = 5,
		/obj/item/weapon/reagent_containers/food/snacks/liquidfood = 6
	)
	prices = list(
		/obj/item/weapon/reagent_containers/glass/drinks/cans/space_mountain_wind = 65,
		/obj/item/weapon/reagent_containers/glass/drinks/cans/grape_juice = 200,
		/obj/item/weapon/reagent_containers/glass/drinks/cans/waterbottle = 35,
		/obj/item/weapon/reagent_containers/glass/drinks/cans/dr_gibb = 120,
		/obj/item/weapon/reagent_containers/glass/drinks/cans/iced_tea = 65,
		/obj/item/weapon/reagent_containers/glass/drinks/cans/space_up = 70,
		/obj/item/weapon/reagent_containers/glass/drinks/cans/starkist = 70,
		/obj/item/weapon/reagent_containers/glass/drinks/cans/cola = 80,
	)
	idle_power_usage = 211 //refrigerator - believe it or not, this is actually the average power consumption of a refrigerated vending machine according to NRCan.

/obj/machinery/vending/cola/soda
	icon_state = "soda"

//This one's from bay12
/obj/machinery/vending/cart
	name = "PTech"
	desc = "Cartridges for PDAs."
	slogan_list = list("Carts to go!")
	icon_state = "cart"
	icon_deny = "cart-deny"
	products = list(
		/obj/item/weapon/cartridge/signal/science = 10,
		/obj/item/weapon/cartridge/quartermaster = 10,
		/obj/item/weapon/cartridge/engineering = 10,
		/obj/item/weapon/cartridge/security = 10,
		/obj/item/weapon/cartridge/janitor = 10,
		/obj/item/weapon/cartridge/medical = 10,
		/obj/item/weapon/cartridge/captain = 3,
		/obj/item/device/pda/heads = 10,
	)


/obj/machinery/vending/cigarette
	name = "Cigarette machine" //OCD had to be uppercase to look nice with the new formating
	desc = "A specialized vending machine designed to contribute to your slow and uncomfortable death."
	slogan_list = list(
		"Smoke now, and win the adoration of your peers.",
		"They beat cancer centuries ago, so smoke away.",
		"If you're not smoking, you must be joking.",
		"There's no better time to start smokin'.",
	)
	ads_list = list(
		"Probably not bad for you!",
		"Don't believe the scientists!",
		"It's good for you!",
		"Don't quit, buy more!",
		"Smoke!",
		"Nicotine heaven.",
		"Best cigarettes since 2150.",
		"Award-winning cigarettes, all the best brands.",
		"Feeling temperamental? Try a Temperamento!",
		"Carcinoma Angels - go fuck yerself!",
		"Don't be so hard on yourself, kid. Smoke a Lucky Star!",
		"We understand the depressed, alcoholic cowboy in you. That's why we also smoke Jericho.",
		"Professionals. Better cigarettes for better people. Yes, better people."
	)
	vend_delay = 34
	icon_state = "cigs"
	products = list(
		/obj/item/storage/fancy/cigarettes = 10,
		/obj/item/storage/box/matches = 10,
		/obj/item/weapon/flame/lighter/random = 4,
	)
	contraband = list(/obj/item/weapon/flame/lighter/zippo = 4)
	premium = list(/obj/item/storage/fancy/cigar = 5)
	prices = list(
		/obj/item/storage/fancy/cigarettes = 150,
		/obj/item/weapon/flame/lighter/random = 20,
		/obj/item/storage/box/matches = 10,
	)

/obj/machinery/vending/cigarette/wallmounted
	icon_state = "cigs_wall"

/obj/machinery/vending/medical
	name = "NanoMed Plus"
	desc = "Medical drug dispenser."
	icon_state = "med"
	icon_deny = "med-deny"
	ads_list = list(
		"Go save some lives!",
		"The best stuff for your medbay.",
		"Only the finest tools.",
		"Natural chemicals!",
		"This stuff saves lives.",
		"Don't you want some?",
		"Ping!"
	)
	req_access = list(access_medical_equip)
	products = list(
		/obj/item/weapon/reagent_containers/glass/beaker/bottle/inaprovaline = 4,
		/obj/item/weapon/reagent_containers/glass/beaker/bottle/antitoxin = 4,
		/obj/item/weapon/reagent_containers/glass/beaker/bottle/stoxin = 4,
		/obj/item/weapon/reagent_containers/glass/beaker/bottle/toxin = 4,
		/obj/item/weapon/reagent_containers/syringe/antiviral = 4,
		/obj/item/weapon/reagent_containers/glass/beaker = 4,
		/obj/item/stack/medical/bruise_pack/advanced = 3,
		/obj/item/weapon/reagent_containers/syringe = 12,
		/obj/item/weapon/reagent_containers/dropper = 2,
		/obj/item/stack/medical/ointment/advanced = 3,
		/obj/item/device/healthanalyzer = 5,
		/obj/item/stack/medical/splint = 2,
	)
	contraband = list(
		/obj/item/weapon/reagent_containers/pill/antitox = 6,
		/obj/item/weapon/reagent_containers/pill/stox = 4,
		/obj/item/weapon/reagent_containers/pill/tox = 3,
	)
	idle_power_usage = 211 //refrigerator - believe it or not, this is actually the average power consumption of a refrigerated vending machine according to NRCan.


//This one's from bay12
/obj/machinery/vending/phoronresearch
	name = "Toximate 3000"
	desc = "All the fine parts you need in one vending machine!"
	products = list(
		/obj/item/clothing/under/rank/scientist = 6,
		/obj/item/device/assembly/prox_sensor = 6,
		/obj/item/device/assembly/signaler = 6,
		/obj/item/device/assembly/igniter = 6,
		/obj/item/clothing/head/bio_hood = 6,
		/obj/item/clothing/suit/bio_suit = 6,
		/obj/item/device/assembly/timer = 6,
		/obj/item/device/transfer_valve = 6,
	)

/obj/machinery/vending/wallmed1
	name = "NanoMed"
	desc = "Wall-mounted Medical Equipment dispenser."
	ads_list = list(
		"Go save some lives!",
		"The best stuff for your medbay.",
		"Only the finest tools.",
		"Natural chemicals!",
		"This stuff saves lives.",
		"Don't you want some?"
	)
	icon_state = "wallmed"
	icon_deny = "wallmed-deny"
	req_access = list(access_medical)
	density = 0 //It is wall-mounted, and thus, not dense. --Superxpdude
	products = list(
		/obj/item/weapon/reagent_containers/hypospray/autoinjector = 4,
		/obj/item/stack/medical/bruise_pack = 2,
		/obj/item/stack/medical/ointment = 2,
		/obj/item/device/healthanalyzer = 1
	)
	contraband = list(
		/obj/item/weapon/reagent_containers/syringe/antitoxin = 4,
		/obj/item/weapon/reagent_containers/syringe/antiviral = 4,
		/obj/item/weapon/reagent_containers/pill/tox = 1
	)

/obj/machinery/vending/wallmed2
	name = "NanoMed"
	desc = "Wall-mounted Medical Equipment dispenser."
	icon_state = "wallmed"
	icon_deny = "wallmed-deny"
	req_access = list(access_medical)
	density = 0 //It is wall-mounted, and thus, not dense. --Superxpdude
	products = list(
		/obj/item/weapon/reagent_containers/hypospray/autoinjector = 5,
		/obj/item/weapon/reagent_containers/syringe/antitoxin = 3,
		/obj/item/stack/medical/bruise_pack = 3,
		/obj/item/stack/medical/ointment =3,
		/obj/item/device/healthanalyzer = 3
	)
	contraband = list(/obj/item/weapon/reagent_containers/pill/tox = 3)

/obj/machinery/vending/security
	name = "SecTech"
	desc = "A security equipment vendor."
	ads_list = list(
		"Crack capitalist skulls!",
		"Beat some heads in!",
		"Don't forget - harm is good!",
		"Your weapons are right here.",
		"Handcuffs!",
		"Freeze, scumbag!",
		"Don't tase me bro!",
		"Tase them, bro.",
		"Why not have a donut?"
	)
	icon_state = "sec"
	icon_deny = "sec-deny"
	req_access = list(access_security)
	products = list(
		/obj/item/weapon/reagent_containers/food/snacks/donut/normal = 12,
		/obj/item/storage/box/evidence = 6,
		/obj/item/weapon/grenade/flashbang = 4,
		/obj/item/device/flashlight/seclite=7,
		/obj/item/weapon/handcuffs = 8,
		/obj/item/device/flash = 5,
	)
	contraband = list(
		/obj/item/clothing/glasses/sunglasses = 2,
		/obj/item/storage/box/donut = 2
	)

/obj/machinery/vending/hydronutrients
	name = "NutriMax"
	desc = "A plant nutrients vendor."
	slogan_list = list(
		"Aren't you glad you don't have to fertilize the natural way?",
		"Now with 50% less stink!",
		"Plants are people too!"
	)
	ads_list = list(
		"We like plants!",
		"Don't you want some?",
		"The greenest thumbs ever.",
		"We like big plants.",
		"Soft soil..."
	)
	icon_state = "nutri"
	icon_deny = "nutri-deny"
	products = list(
		/obj/item/weapon/reagent_containers/glass/fertilizer/l4z = 25,
		/obj/item/weapon/reagent_containers/glass/fertilizer/ez = 35,
		/obj/item/weapon/reagent_containers/glass/fertilizer/rh = 15,
		/obj/item/weapon/reagent_containers/syringe = 5,
		/obj/item/storage/bag/plants = 5,
		/obj/item/weapon/plantspray/pests = 20,
	)
	premium = list(
		/obj/item/weapon/reagent_containers/glass/beaker/bottle/ammonia = 10,
		/obj/item/weapon/reagent_containers/glass/beaker/bottle/diethylamine = 5
	)
	idle_power_usage = 211 //refrigerator - believe it or not, this is actually the average power consumption of a refrigerated vending machine according to NRCan.

/obj/machinery/vending/hydroseeds
	name = "MegaSeed Servitor"
	desc = "When you need seeds fast!"
	slogan_list = list(
		"Also certain mushroom varieties available, more for experts! Get certified today!",
		"Hands down the best seed selection on the station!",
		"THIS'S WHERE TH' SEEDS LIVE! GIT YOU SOME!",
	)
	ads_list = list(
		"We like plants!",
		"Grow some crops!",
		"Grow, baby, growww!",
		"Aw h'yeah son!"
	)
	icon_state = "seeds"

	products = list(
		/obj/item/seeds/ambrosiavulgarisseed = 3,
		/obj/item/seeds/chantermycelium = 3,
		/obj/item/seeds/watermelonseed = 3,
		/obj/item/seeds/sunflowerseed = 3,
		/obj/item/seeds/towermycelium = 3,
		/obj/item/seeds/sugarcaneseed = 3,
		/obj/item/seeds/whitebeetseed = 3,
		/obj/item/seeds/plumpmycelium = 2,
		/obj/item/seeds/eggplantseed = 3,
		/obj/item/seeds/cocoapodseed = 3,
		/obj/item/seeds/cabbageseed = 3,
		/obj/item/seeds/pumpkinseed = 3,
		/obj/item/seeds/bananaseed = 3,
		/obj/item/seeds/carrotseed = 3,
		/obj/item/seeds/potatoseed = 3,
		/obj/item/seeds/replicapod = 3,
		/obj/item/seeds/tomatoseed = 3,
		/obj/item/seeds/peanutseed = 3,
		/obj/item/seeds/orangeseed = 3,
		/obj/item/seeds/cherryseed = 3,
		/obj/item/seeds/plastiseed = 3,
		/obj/item/seeds/berryseed = 3,
		/obj/item/seeds/chiliseed = 3,
		/obj/item/seeds/wheatseed = 3,
		/obj/item/seeds/appleseed = 3,
		/obj/item/seeds/poppyseed = 3,
		/obj/item/seeds/lemonseed = 3,
		/obj/item/seeds/grassseed = 3,
		/obj/item/seeds/grapeseed = 3,
		/obj/item/seeds/cornseed = 3,
		/obj/item/seeds/soyaseed = 3,
		/obj/item/seeds/limeseed = 3,
		/obj/item/seeds/riceseed = 3
	)
	contraband = list(
		/obj/item/seeds/amanitamycelium = 2,
		/obj/item/seeds/libertymycelium = 2,
		/obj/item/seeds/reishimycelium = 2,
		/obj/item/seeds/reishimycelium = 2,
		/obj/item/seeds/glowshroom = 2,
		/obj/item/seeds/nettleseed = 2,
		/obj/item/seeds/mtearseed = 2,
		/obj/item/seeds/shandseed = 2,

	)
	premium = list(/obj/item/toy/waterflower = 1)

/**
 *  Populate hydroseeds product_records
 *
 *  This needs to be customized to fetch the actual names of the seeds, otherwise
 *  the machine would simply list "packet of seeds" times 20
 */
/obj/machinery/vending/hydroseeds/build_inventory()
	var/list/all_products = list(
		list(src.products, CAT_NORMAL),
		list(src.contraband, CAT_HIDDEN),
		list(src.premium, CAT_COIN))

	for(var/current_list in all_products)
		var/category = current_list[2]

		for(var/entry in current_list[1])
			var/obj/item/seeds/S = new entry(src)
			var/name = S.name
			var/datum/stored_items/vending_products/product = new/datum/stored_items/vending_products(src, entry, name)

			product.price = (entry in src.prices) ? src.prices[entry] : 0
			product.amount = (current_list[1][entry]) ? current_list[1][entry] : 1
			product.category = category

			src.product_records.Add(product)

/obj/machinery/vending/magivend
	name = "MagiVend"
	desc = "A magic vending machine."
	icon_state = "MagiVend"
	slogan_list = list(
		"Sling spells the proper way with MagiVend!",
		"Be your own Houdini! Use MagiVend!"
	)
	vend_delay = 15
	vend_reply = "Have an enchanted evening!"
	ads_list = list(
		"FJKLFJSD",
		"AJKFLBJAKL",
		"1234 LOONIES LOL!",
		">MFW",
		"Kill them fuckers!",
		"GET DAT FUKKEN DISK",
		"HONK!",
		"EI NATH",
		"Destroy the station!",
		"Admin conspiracies since forever!",
		"Space-time bending hardware!"
	)
	products = list(
		/obj/item/clothing/suit/wizrobe/red = 1,
		/obj/item/clothing/head/wizard/red = 1,
		/obj/item/clothing/shoes/sandal = 1,
		/obj/item/clothing/suit/wizrobe = 1,
		/obj/item/clothing/head/wizard = 1,
		/obj/item/weapon/staff = 2,
	)

obj/machinery/vending/clothesvend
	name = "Clothing vendomat"
	desc = "Dress up!"
	ads_list = list(
		"Clother for all of your needs!",
		"90% discount! Only today!",
		"BuyALot!"
	)
	icon_state = "clothesvend"
	products = list(
		/obj/item/clothing/head/greenbandana = 2,
		/obj/item/clothing/head/orangebandana = 2,
		/obj/item/clothing/head/bandana = 2,
		/obj/item/clothing/head/cowboy_hat = 2,
		/obj/item/clothing/head/tajaran/scarf = 2,
		/obj/item/clothing/head/hairflower = 2,
		/obj/item/clothing/head/whiteribbon = 2,
		/obj/item/clothing/head/sombrero = 2,
		/obj/item/clothing/head/ushanka = 2,
		/obj/item/clothing/shoes/sandal = 2,
		/obj/item/clothing/shoes/sandal/brown = 2,
		/obj/item/clothing/shoes/sandal/pink = 2,
		/obj/item/clothing/under/pants/blackjeans = 2,
		/obj/item/clothing/under/pants/classicjeans = 2,
		/obj/item/clothing/under/pants/white = 2,
		/obj/item/clothing/under/pants/red = 2,
		/obj/item/clothing/under/pants/black = 2,
		/obj/item/clothing/under/pants/track = 2,
		/obj/item/clothing/under/pants/tan = 2,
		/obj/item/clothing/under/pants/jeans = 2,
		/obj/item/clothing/under/pants/camo = 2,
		/obj/item/clothing/under/pants/khaki = 2,
		/obj/item/clothing/under/blackskirt = 2,
		/obj/item/clothing/under/dress/plaid_blue = 2,
	)
	contraband = list(
		/obj/item/clothing/suit/witchrobe = 2,
		/obj/item/clothing/head/witchhat = 2,
		/obj/item/clothing/shoes/witchshoes = 2,
	)

/obj/machinery/vending/dinnerware
	name = "Dinnerware"
	desc = "A kitchen and restaurant equipment vendor."
	ads_list = list(
		"Mm, food stuffs!",
		"Food and food accessories.",
		"Get your plates!",
		"You like forks?",
		"I like forks.",
		"Woo, utensils.",
		"You don't really need these..."
	)
	icon_state = "dinnerware"
	products = list(
		/obj/item/weapon/reagent_containers/glass/drinks/drinkingglass = 8,
		/obj/item/weapon/material/kitchen/utensil/fork = 6,
		/obj/item/clothing/suit/chef/classic = 2,
		/obj/item/weapon/material/knife = 3,
		/obj/item/weapon/tray = 8,
	)
	contraband = list(
		/obj/item/weapon/material/kitchen/utensil/spoon = 2,
		/obj/item/weapon/material/kitchen/utensil/knife = 2,
		/obj/item/weapon/material/kitchen/rollingpin = 2,
		/obj/item/weapon/material/knife/butch = 2
	)

/obj/machinery/vending/sovietsoda
	name = "BODA"
	desc = "An old sweet water vending machine,how did this end up here?"
	icon_state = "sovietsoda"
	ads_list = list(
		"For Tsar and Country.",
		"Have you fulfilled your nutrition quota today?",
		"Very nice!",
		"We are simple people, for this is all we eat.",
		"If there is a person, there is a problem. If there is no person, then there is no problem."
	)
	products = list(
		/obj/item/weapon/reagent_containers/glass/drinks/drinkingglass/soda = 30
	)
	contraband = list(/obj/item/weapon/reagent_containers/glass/drinks/drinkingglass/cola = 20)
	idle_power_usage = 211 //refrigerator - believe it or not, this is actually the average power consumption of a refrigerated vending machine according to NRCan.

/obj/machinery/vending/tool
	name = "YouTool"
	desc = "Tools for tools."
	icon_state = "tool"
	icon_deny = "tool-deny"
	//req_access = list(access_maint_tunnels) //Maintenance access
	products = list(
		/obj/item/stack/cable_coil/random = 10,
		/obj/item/weapon/weldingtool = 3,
		/obj/item/weapon/screwdriver = 5,
		/obj/item/weapon/wirecutters = 5,
		/obj/item/device/t_scanner = 5,
		/obj/item/device/analyzer = 5,
		/obj/item/weapon/crowbar = 5,
		/obj/item/weapon/wrench = 5,
	)
	contraband = list(/obj/item/weapon/weldingtool/hugetank = 2,/obj/item/clothing/gloves/fyellow = 2)
	premium = list(/obj/item/clothing/gloves/yellow = 1)

/obj/machinery/vending/engivend
	name = "Engi-Vend"
	desc = "Spare tool vending. What? Did you expect some witty description?"
	icon_state = "engivend"
	icon_deny = "engivend-deny"
	req_one_access = list(access_atmospherics,access_engine_equip)
	products = list(
		/obj/item/weapon/airalarm_electronics = 10,
		/obj/item/weapon/power_control = 10,
		/obj/item/weapon/airlock_electronics = 10,
		/obj/item/device/flashlight/heavy = 6,
		/obj/item/clothing/glasses/meson = 2,
		/obj/item/weapon/cell/high = 10,
		/obj/item/device/multitool = 4,
	)
	contraband = list(/obj/item/weapon/cell/potato = 3)
	premium = list(/obj/item/storage/belt/utility = 3)

//This one's from bay12
/obj/machinery/vending/engineering
	name = "Robco Tool Maker"
	desc = "Everything you need for do-it-yourself station repair."
	icon_state = "engi"
	icon_deny = "engi-deny"
	req_one_access = list(access_atmospherics,access_engine_equip)
	products = list(
		/obj/item/clothing/under/rank/chief_engineer = 4,
		/obj/item/weapon/stock_parts/scanning_module = 5,
		/obj/item/weapon/stock_parts/console_screen = 5,
		/obj/item/weapon/stock_parts/micro_laser = 5,
		/obj/item/weapon/stock_parts/manipulator = 5,
		/obj/item/weapon/stock_parts/matter_bin = 5,
		/obj/item/clothing/under/rank/engineer = 4,
		/obj/item/storage/belt/utility = 4,
		/obj/item/stack/cable_coil/heavyduty = 8,
		/obj/item/device/flashlight/heavy = 5,
		/obj/item/clothing/glasses/meson = 4,
		/obj/item/clothing/gloves/yellow = 4,
		/obj/item/clothing/shoes/orange = 4,
		/obj/item/clothing/head/hardhat = 4,
		/obj/item/clothing/head/welding = 8,
		/obj/item/weapon/screwdriver = 12,
		/obj/item/weapon/wirecutters = 12,
		/obj/item/weapon/weldingtool = 8,
		/obj/item/weapon/light/tube = 10,
		/obj/item/clothing/suit/fire = 4,
		/obj/item/device/multitool = 12,
		/obj/item/device/t_scanner = 12,
		/obj/item/weapon/crowbar = 12,
		/obj/item/weapon/wrench = 12,
		/obj/item/weapon/cell = 8,
	)
	// There was an incorrect entry (cablecoil/power).  I improvised to cablecoil/heavyduty.
	// Another invalid entry, /obj/item/weapon/circuitry.  I don't even know what that would translate to, removed it.
	// The original products list wasn't finished.  The ones without given quantities became quantity 5.  -Sayu

//This one's from bay12
/obj/machinery/vending/robotics
	name = "Robotech Deluxe"
	desc = "All the tools you need to create your own robot army."
	icon_state = "robotics"
	icon_deny = "robotics-deny"
	req_access = list(access_robotics)
	products = list(
		/obj/item/clothing/suit/storage/toggle/labcoat = 4,
		/obj/item/clothing/under/rank/roboticist = 4,
		/obj/item/clothing/mask/breath/medical = 5,
		/obj/item/device/assembly/prox_sensor = 3,
		/obj/item/device/assembly/signaler = 3,
		/obj/item/weapon/tank/anesthetic = 2,
		/obj/item/device/healthanalyzer = 3,
		/obj/item/weapon/surgical/circular_saw = 2,
		/obj/item/weapon/screwdriver = 5,
		/obj/item/weapon/cell/high = 12,
		/obj/item/stack/cable_coil = 4,
		/obj/item/weapon/surgical/scalpel = 2,
		/obj/item/weapon/crowbar = 5,
		/obj/item/device/flash = 4,
	)
	//everything after the power cell had no amounts, I improvised.  -Sayu

/obj/machinery/vending/thundervend
	name = "Violence-o-Mate"
	desc = "That's a guns and ammo vendor."
	ads_list = list(
		"ULTRAVIOLENCE!",
		"Do you like to hurt other people, mate?",
		"You're not a nice person!",
		"Get a goddamn gun and take them out!",
		"Why did you come back here?"
	)
	icon_state = "thundervendor"
	products = list(
		/obj/item/weapon/reagent_containers/hypospray/autoinjector/combat=60,
		/obj/item/weapon/material/hatchet/tacknife/thunder = 30,
		/obj/item/weapon/gun/projectile/automatic/hornet = 10,
		/obj/item/weapon/grenade/chem_grenade/metalfoam=20,
		/obj/item/weapon/grenade/chem_grenade/cleaner=30,
		/obj/item/weapon/gun/energy/wasp = 10,
		/obj/item/weapon/grenade/flashbang=20,
		/obj/item/ammo_magazine/hornet = 30,
		/obj/item/ammo_magazine/legalist=20,
	)
	vend_delay = 10
	density = 1

