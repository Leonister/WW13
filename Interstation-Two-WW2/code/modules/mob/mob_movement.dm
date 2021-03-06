/mob/var/velocity = 0
/mob/var/velocity_lastdir = -1 // turning makes you lose 1 or 2 velocity
/mob/var/run_delay_maximum = 2.2 / 1.25

/mob/proc/get_run_delay()
	switch (velocity)
		if (0 to 3)
			return run_delay_maximum
		if (4 to 7)
			return run_delay_maximum/1.08
		if (8 to 11)
			return run_delay_maximum/1.16
		if (12 to INFINITY)
			return run_delay_maximum/1.24

// walking
/mob/var/walk_delay = 3.3 / 1.25

/mob/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)

	if(air_group || (height==0)) return 1

	if(ismob(mover))
		var/mob/moving_mob = mover
		if ((other_mobs && moving_mob.other_mobs))
			return 1
		return (!mover.density || !density || lying)
	else
		return (!mover.density || !density || lying)
	return

/mob/proc/setMoveCooldown(var/timeout)
	if(client)
		client.move_delay = max(world.time + timeout, client.move_delay)

/client/North()
	..()


/client/South()
	..()


/client/West()
	..()


/client/East()
	..()


/client/proc/client_dir(input, direction=-1)
	return turn(input, direction*dir2angle(dir))

/client/Northeast()
	diagonal_action(NORTHEAST)
/client/Northwest()
	diagonal_action(NORTHWEST)
/client/Southeast()
	diagonal_action(SOUTHEAST)
/client/Southwest()
	diagonal_action(SOUTHWEST)

/client/proc/diagonal_action(direction)
	switch(client_dir(direction, 1))
		if(NORTHEAST)
			swap_hand()
			return
		if(SOUTHEAST)
			attack_self()
			return
		if(SOUTHWEST)
			if(iscarbon(usr))
				var/mob/living/carbon/C = usr
				C.toggle_throw_mode()
			else
				usr << "\red This mob type cannot throw items."
			return
		if(NORTHWEST)
			if(iscarbon(usr))
				var/mob/living/carbon/C = usr
				if(!C.get_active_hand())
					usr << "\red You have nothing to drop in your hand."
					return
				drop_item()
			else
				usr << "\red This mob type cannot drop items."
			return

//This gets called when you press the delete button.
/client/verb/delete_key_pressed()
	set hidden = 1

	if(!usr.pulling)
		usr << "\blue You are not pulling anything."
		return
	usr.stop_pulling()

/client/verb/swap_hand()
	set hidden = 1
	if(istype(mob, /mob/living/carbon))
		mob:swap_hand()
	return



/client/verb/attack_self()
	set hidden = 1
	if(mob && isliving(mob))
		var/mob/living/L = mob
		L.mode()
	return


/client/verb/toggle_throw_mode()
	set hidden = 1
	if(!istype(mob, /mob/living/carbon))
		return
	if (!mob.stat && isturf(mob.loc) && !mob.restrained())
		mob:toggle_throw_mode()
	else
		return


/client/verb/drop_item()
	set hidden = 1
	if(!isrobot(mob) && mob.stat == CONSCIOUS && isturf(mob.loc))
		return mob.drop_item()
	return


/client/Center()
	/* No 3D movement in 2D spessman game. dir 16 is Z Up
	if (isobj(mob.loc))
		var/obj/O = mob.loc
		if (mob.canmove)
			return O.relaymove(mob, 16)
	*/
	return

//This proc should never be overridden elsewhere at /atom/movable to keep directions sane.
/atom/movable/Move(newloc, direct)
	if (direct & (direct - 1))
		if (direct & 1)
			if (direct & 4)
				if (step(src, NORTH))
					step(src, EAST)
				else
					if (step(src, EAST))
						step(src, NORTH)
			else
				if (direct & 8)
					if (step(src, NORTH))
						step(src, WEST)
					else
						if (step(src, WEST))
							step(src, NORTH)
		else
			if (direct & 2)
				if (direct & 4)
					if (step(src, SOUTH))
						step(src, EAST)
					else
						if (step(src, EAST))
							step(src, SOUTH)
				else
					if (direct & 8)
						if (step(src, SOUTH))
							step(src, WEST)
						else
							if (step(src, WEST))
								step(src, SOUTH)
	else
		var/atom/A = src.loc

		var/olddir = dir //we can't override this without sacrificing the rest of movable/New()
		. = ..()
		if(direct != olddir)
			dir = olddir
			set_dir(direct)

		src.move_speed = world.time - src.l_move_time
		src.l_move_time = world.time
		src.m_flag = 1
		if ((A != src.loc && A && A.z == src.z))
			src.last_move = get_dir(A, src.loc)
	return

/client/proc/Move_object(direct)
	if(mob && mob.control_object)
		if(mob.control_object.density)
			step(mob.control_object,direct)
			if(!mob.control_object)	return
			mob.control_object.dir = direct
		else
			mob.control_object.forceMove(get_step(mob.control_object,direct))
	return


/mob/living/carbon/human/var/next_stamina_message = -1
/mob/var/next_snow_message = -1
/client/Move(n, direct)
	if(!canmove)
		return

	if(!mob)
		return // Moved here to avoid nullrefs below

	var/mob_is_observer = istype(mob, /mob/observer)
	var/mob_is_living = istype(mob, /mob/living)
	var/mob_is_human = istype(mob, /mob/living/carbon/human)

	if (mob_is_living && istype(mob.loc, /obj/tank))
		var/obj/tank/tank = mob.loc
		tank.receive_command_from(mob, direct)
		return 1

	var/turf/t1 = n

	if (t1 && map.check_prishtina_block(mob, t1))
		mob.dir = direct
		mob << "<span class = 'warning'>You cannot pass the invisible wall until the Grace Period has ended.</span>"
		return 0

	if (mob_is_observer && t1 && locate(/obj/noghost) in t1)
		if (!mob.client.holder || !check_rights(R_MOD, user = mob))
			mob.dir = direct
			return

	if (mob_is_human)
		var/mob/living/carbon/human/H = mob
		if (H.crouching)
			return

	if(mob_is_observer)
		var/turf/t = get_step(mob, direct)
		if (!t)
			return

	else if (mob.is_on_train() && !mob.buckled)
		var/datum/train_controller/tc = mob.get_train()
		if (tc && tc.moving)
			if (mob.train_move_check(get_step(mob, direct)) && !mob.lying && mob.stat != UNCONSCIOUS && mob.stat != DEAD)
				mob.next_train_movement = direct
				mob.train_gib_immunity = 1
				mob.last_train_movement = world.time // last successful move
			mob.last_train_movement_attempt = world.time // last move attempt
			return // prevent normal movement if we're on a train

	if(mob.control_object)	Move_object(direct)

	if(mob.incorporeal_move && mob_is_observer)
		Process_Incorpmove(direct)
		return

	if(moving)	return 0

	if(world.time < move_delay)	return

	if(locate(/obj/effect/stop/, mob.loc))
		for(var/obj/effect/stop/S in mob.loc)
			if(S.victim == mob)
				return

	if(mob.stat==DEAD && mob_is_living)
		mob.ghostize()
		return

	// handle possible Eye movement
	if(mob.eyeobj)
		return mob.EyeMove(n,direct)

	if(mob.transforming)	return//This is sota the goto stop mobs from moving var

	if(mob_is_living)
		var/mob/living/L = mob
		if(L.incorporeal_move)//Move though walls
			Process_Incorpmove(direct)
			return

	if(Process_Grab())	return

	if(!mob.canmove)
		return

	if (mob_is_living)
		if (locate(/obj/structure/classic_window_frame) in mob.loc)
			mob.visible_message("<span class = 'warning'>[mob] starts climbing through the window frame.</span>")
			mob.canmove = 0
			var/oloc = mob.loc
			sleep(rand(25,35))
			mob.canmove = 1
			if (mob.lying || mob.stat == DEAD || mob.stat == UNCONSCIOUS || mob.loc != oloc)
				return
			mob.visible_message("<span class = 'warning'>[mob] climbs through the window frame.</span>")

	// we can probably move now, so update our eye for ladders
	if (mob_is_human)
		var/mob/living/carbon/human/H = mob
		H.update_laddervision(null)

	if(!mob.lastarea)
		mob.lastarea = get_area(mob.loc)

	if(isobj(mob.loc) || ismob(mob.loc))//Inside an object, tell it we moved
		var/atom/O = mob.loc
		if (!istype(O, /obj/tank))
			return O.relaymove(mob, direct)

	if(isturf(mob.loc))

		if(mob.restrained())//Why being pulled while cuffed prevents you from moving
			for(var/mob/M in range(mob, 1))
				if(M.pulling == mob)
					if(!M.restrained() && M.stat == 0 && M.canmove && mob.Adjacent(M))
						src << "\blue You're restrained! You can't move!"
						return 0
					else
						M.stop_pulling()

		if(mob.pinned.len)
			src << "\blue You're pinned to a wall by [mob.pinned[1]]!"
			return 0

		move_delay = world.time//set move delay

		// removed config.run_speed, config.walk_speed from move_delays
		// for some reason they kept defaulting to values different from
		// the ones specified in the config.


		var/turf/floor/F = get_turf(mob)
		var/standing_on_snow = 0

		if (F && istype(F))
			var/obj/snow/S = F.has_snow()
			var/snow_message = ""
			var/snow_span = "notice"

			if (S)
				standing_on_snow = 1
				switch (S.amount)
					if (0.01 to 0.8) // more than none and up to ~1/4 feet
						standing_on_snow = 1
						snow_message = "You're slowed down a little by the snow."
					if (0.08 to 0.16) // up to ~1/2 feet
						standing_on_snow = 1.25
						snow_message = "You're slowed down a bit by the snow."
					if (0.16 to 0.30) // up to a ~1 foot
						standing_on_snow = 1.75
						snow_message = "You're slowed down quite a bit by the snow."
						snow_span = "warning"
					if (0.30 to 0.75) // ~ 2 to 2.5 feet
						standing_on_snow = 2.25
						snow_message = "You're seriously being slowed down by the snow. It's almost hard to walk in."
						snow_span = "warning"
					if (0.75 to 1.22) // up to 4 feet!
						standing_on_snow = 4.5
						snow_message = "There's way too much snow here to properly move."
						snow_span = "danger"
					if (1.22 to INFINITY) // no way we can go through this easily
						standing_on_snow = 18
						snow_message = "There's way too much snow here to move!"
						snow_span = "danger"

				if (snow_message && world.time >= mob.next_snow_message)
					mob << "<span class = '[snow_span]'>[snow_message]</span>"
					mob.next_snow_message = world.time+100
			else if (F.muddy)
				standing_on_snow = rand(2,4)
				mob << "<span class = 'warning'>The mud slows you down.</span>"

		if (mob.velocity_lastdir != -1)
			if (direct != mob.velocity_lastdir)
				mob.velocity = max(mob.velocity-pick(1,2), 0)

		switch(mob.m_intent)
			if("run")
				mob.velocity = min(mob.velocity+1, 15)
				mob.velocity_lastdir = direct
				if(mob.drowsyness > 0)
					move_delay += 6
				move_delay += mob.get_run_delay() + standing_on_snow
				if (mob_is_human)
					var/mob/living/carbon/human/H = mob
					H.nutrition -= 0.03
					--H.stamina
			if("walk")
				move_delay += mob.walk_delay + standing_on_snow
				if (mob_is_human)
					var/mob/living/carbon/human/H = mob
					H.nutrition -= 0.003

		if (mob.pulling)
			if (istype(mob.pulling, /mob))
				move_delay += 1.0
			else if (istype(mob.pulling, /obj/structure))
				move_delay += 0.75

		var/mob/living/carbon/human/H = mob

		if (mob_is_human)
			if (H.stamina == (H.max_stamina/2) && H.m_intent == "run" && world.time >= H.next_stamina_message)
				H << "<span class = 'danger'>You're starting to tire from running so much.</span>"
				H.next_stamina_message = world.time + 20

			if (H.stamina <= 0 && H.m_intent == "run")
				H << "<span class = 'danger'>You're too tired to keep running.</span>"
				for (var/obj/screen/mov_intent/mov in H.client.screen)
					H.client.Click(mov)
					break
				if (H.m_intent != "walk")
					H.m_intent = "walk" // in case we don't have a m_intent HUD, somehow

		if (!mob_is_observer)
			var/turf/T = get_turf(mob)
			if (istype(T, /turf/floor/plating/beach/water))
				if (!istype(T, /turf/floor/plating/beach/water/ice))
					move_delay += 3

		var/tickcomp = 0 //moved this out here so we can use it for vehicles
		if(config.Tickcomp)
			// move_delay -= 1.3 //~added to the tickcomp calculation below
			tickcomp = ((1/(world.tick_lag))*1.3) - 1.3
			move_delay += tickcomp

		if(istype(mob.buckled, /obj/vehicle))
			//manually set move_delay for vehicles so we don't inherit any mob movement penalties
			//specific vehicle move delays are set in code\modules\vehicles\vehicle.dm
			move_delay = world.time + tickcomp
			//drunk driving
			if(mob.confused)
				direct = pick(cardinal)
			return mob.buckled.relaymove(mob,direct)

		if(istype(mob.machine, /obj/machinery))
			if(mob.machine.relaymove(mob,direct))
				return

		if(mob.pulledby || mob.buckled) // Wheelchair driving!
			if(istype(mob.loc, /turf/space))
				return // No wheelchair driving in space
			if(istype(mob.pulledby, /obj/structure/bed/chair/wheelchair))
				return mob.pulledby.relaymove(mob, direct)
			else if(istype(mob.buckled, /obj/structure/bed/chair/wheelchair))
				if(mob_is_human)
					var/mob/living/carbon/human/driver = mob
					var/obj/item/organ/external/l_hand = driver.get_organ("l_hand")
					var/obj/item/organ/external/r_hand = driver.get_organ("r_hand")
					if((!l_hand || l_hand.is_stump()) && (!r_hand || r_hand.is_stump()))
						return // No hands to drive your chair? Tough luck!
				//drunk wheelchair driving
				if(mob.confused)
					direct = pick(cardinal)
				move_delay += 2
				return mob.buckled.relaymove(mob,direct)

		//We are now going to move
		moving = 1
		//Something with pulling things
		if(locate(/obj/item/weapon/grab, mob))
			move_delay = max(move_delay, world.time + 7)
			var/list/L = mob.ret_grab()
			if(istype(L, /list))
				if(L.len == 2)
					L -= mob
					var/mob/M = L[1]
					if(M)
						if ((get_dist(mob, M) <= 1 || M.loc == mob.loc))
							var/turf/T = mob.loc
							. = ..()
							if (isturf(M.loc))
								var/diag = get_dir(mob, M)
								if ((diag - 1) & diag)
								else
									diag = null
								if ((get_dist(mob, M) > 1 || diag))
									step(M, get_dir(M.loc, T))
				else
					for(var/mob/M in L)
						M.other_mobs = 1
						if(mob != M)
							M.animate_movement = 3
					for(var/mob/M in L)
						spawn( 0 )
							step(M, direct)
							return
						spawn( 1 )
							M.other_mobs = null
							M.animate_movement = 2
							return

		else if(mob.confused)
			step(mob, pick(cardinal))
		else
			. = mob.SelfMove(n, direct)

		for (var/obj/structure/multiz/ladder/ww2/manhole/M in mob.loc)
			spawn (1)
				M.fell(mob)

		// make animals acknowledge us
		if (mob_is_human)
			for (var/mob/living/simple_animal/complex_animal/C in living_mob_list) // living_mob_list fails here
				var/dist_x = abs(mob.x - C.x)
				var/dist_y = abs(mob.y - C.y)
				if (dist_x <= 10 && dist_y <= 10)
					C.onHumanMovement(mob)

		for (var/obj/item/weapon/grab/G in mob)
			if (G.state == GRAB_NECK)
				mob.set_dir(reverse_dir[direct])
			G.adjust_position()
		for (var/obj/item/weapon/grab/G in mob.grabbed_by)
			G.adjust_position()

		moving = 0

		mob.last_movement = world.time

		return .

	return

/mob/proc/lastMovedRecently()
	if (abs(last_movement - world.time) < 2)
		return 1
	return 0

/mob/proc/SelfMove(turf/n, direct)
	return Move(n, direct)

///Process_Incorpmove
///Called by client/Move()
///Allows mobs to run though walls
/client/proc/Process_Incorpmove(direct)
	var/turf/mobloc = get_turf(mob)

	switch(mob.incorporeal_move)
		if(1)
			var/turf/T = get_step(mob, direct)
			if(mob.check_holy(T))
				mob << "<span class='warning'>You cannot get past holy grounds while you are in this plane of existence!</span>"
				return
			else
				mob.forceMove(get_step(mob, direct))
				mob.dir = direct
		if(2)
			if(prob(50))
				var/locx
				var/locy
				switch(direct)
					if(NORTH)
						locx = mobloc.x
						locy = (mobloc.y+2)
						if(locy>world.maxy)
							return
					if(SOUTH)
						locx = mobloc.x
						locy = (mobloc.y-2)
						if(locy<1)
							return
					if(EAST)
						locy = mobloc.y
						locx = (mobloc.x+2)
						if(locx>world.maxx)
							return
					if(WEST)
						locy = mobloc.y
						locx = (mobloc.x-2)
						if(locx<1)
							return
					else
						return
				mob.forceMove(locate(locx,locy,mobloc.z))
				spawn(0)
					var/limit = 2//For only two trailing shadows.
					for(var/turf/T in getline(mobloc, mob.loc))
						spawn(0)
							anim(T,mob,'icons/mob/mob.dmi',,"shadow",,mob.dir)
						limit--
						if(limit<=0)	break
			else
				spawn(0)
					anim(mobloc,mob,'icons/mob/mob.dmi',,"shadow",,mob.dir)
				mob.forceMove(get_step(mob, direct))
			mob.dir = direct
	// Crossed is always a bit iffy
	for(var/obj/S in mob.loc)
		if(istype(S,/obj/effect/step_trigger) || istype(S,/obj/effect/beam))
			S.Crossed(mob)
		if (istype(S,/obj/fire))
			var/obj/fire/fire = S
			fire.Burn(mob)

	var/area/A = get_area_master(mob)
	if(A)
		A.Entered(mob)
	if(isturf(mob.loc))
		var/turf/T = mob.loc
		T.Entered(mob)
	mob.Post_Incorpmove()
	return 1

/mob/proc/Post_Incorpmove()
	return

///Process_Spacemove
///Called by /client/Move()
///For moving in space
///Return 1 for movement 0 for none
/mob/proc/Process_Spacemove(var/check_drift = 0)

/*	if(!Check_Dense_Object()) //Nothing to push off of so end here
		update_floating(0)
		return 0 */

	update_floating(1)

	if(restrained()) //Check to see if we can do things
		return 0

	//Check to see if we slipped
	if(prob(slip_chance(5)) && !buckled)
		src << "<span class='warning'>You slipped!</span>"
		src.inertia_dir = src.last_move
		step(src, src.inertia_dir)
		return 0
	//If not then we can reset inertia and move
	inertia_dir = 0
	return 1

/mob/proc/Check_Dense_Object() //checks for anything to push off in the vicinity. also handles magboots on gravity-less floors tiles

	var/shoegrip = Check_Shoegrip()

	for(var/turf/T in trange(1,src)) //we only care for non-space turfs
		if(T.density)	//walls work
			return 1
		else
			var/area/A = T.loc
			if(A.has_gravity || shoegrip)
				return 1

	for(var/obj/O in orange(1, src))
		if(istype(O, /obj/structure/lattice))
			return 1
		if(O && O.density && O.anchored)
			return 1

	return 0

/mob/proc/Check_Shoegrip()
	return 0

/mob/proc/slip_chance(var/prob_slip = 5)
	if(stat)
		return 0
	if(Check_Shoegrip())
		return 0
	return prob_slip

/client/verb/moveup()
	set name = ".moveup"
	set instant = 1
	Move(get_step(mob, NORTH), NORTH)

/client/verb/movedown()
	set name = ".movedown"
	set instant = 1
	Move(get_step(mob, SOUTH), SOUTH)

/client/verb/moveright()
	set name = ".moveright"
	set instant = 1
	Move(get_step(mob, EAST), EAST)

/client/verb/moveleft()
	set name = ".moveleft"
	set instant = 1
	Move(get_step(mob, WEST), WEST)