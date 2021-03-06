// Areas.dm

/*

### This file contains a list of all the areas in your station. Format is as follows:

/area/CATEGORY/OR/DESCRIPTOR/NAME 	(you can make as many subdivisions as you want)
	name = "NICE NAME" 				(not required but makes things really nice)
	icon = "ICON FILENAME" 			(defaults to areas.dmi)
	icon_state = "NAME OF ICON" 	(defaults to "unknown" (blank))
	requires_power = 0 				(defaults to 1)

NOTE: there are two lists of areas in the end of this file: centcom and station itself. Please maintain these lists valid. --rastaf0

*/

#define AREA_INSIDE 0
#define AREA_OUTSIDE 1

/area
	var/fire = null
	level = null
	name = "Unknown"
	icon = 'icons/turf/areas.dmi'
	icon_state = "unknown"
	layer = 10
	mouse_opacity = 0
	var/lightswitch = 1

	var/eject = null

	var/debug = 0
	var/requires_power = 1
	var/always_unpowered = 0	//this gets overriden to 1 for space in area/New()

	var/power_equip = 1
	var/power_light = 1
	var/power_environ = 1
	var/used_equip = 0
	var/used_light = 0
	var/used_environ = 0

	var/has_gravity = 1
	var/obj/machinery/power/apc/apc = null
	var/no_air = null
	var/list/all_doors = list()		//Added by Strumpetplaya - Alarm Change - Contains a list of doors adjacent to this area
	var/air_doors_activated = 0
	var/list/ambience = list('sound/ambience/ambigen1.ogg','sound/ambience/ambigen3.ogg','sound/ambience/ambigen4.ogg','sound/ambience/ambigen5.ogg','sound/ambience/ambigen6.ogg','sound/ambience/ambigen7.ogg','sound/ambience/ambigen8.ogg','sound/ambience/ambigen9.ogg','sound/ambience/ambigen10.ogg','sound/ambience/ambigen11.ogg','sound/ambience/ambigen12.ogg','sound/ambience/ambigen14.ogg')
	var/list/forced_ambience = null
	var/turf/base_turf //The base turf type of the area, which can be used to override the z-level's base turf
	var/sound_env = OUTSIDE

	var/location = AREA_OUTSIDE

	var/weather = WEATHER_NONE
	var/weather_intensity = 1.0

	var/list/snowfall_valid_turfs = list()

	var/is_train_area = 0

/*Adding a wizard area teleport list because motherfucking lag -- Urist*/
/*I am far too lazy to make it a proper list of areas so I'll just make it run the usual telepot routine at the start of the game*/
var/list/teleportlocs = list()

/hook/startup/proc/setupTeleportLocs()
	for(var/area/AR in world)
		if(teleportlocs.Find(AR.name)) continue
		var/turf/picked = pick_area_turf(AR.type, list(/proc/is_station_turf))
		if (picked)
			teleportlocs += AR.name
			teleportlocs[AR.name] = AR

	teleportlocs = sortAssoc(teleportlocs)

	return 1

var/list/ghostteleportlocs = list()

/hook/startup/proc/setupGhostTeleportLocs()
	for(var/area/AR in world)
		if(ghostteleportlocs.Find(AR.name)) continue
		if(!istype(AR, /area/prishtina)) continue
		var/turf/picked = pick_area_turf(AR.type, list(/proc/is_station_turf))
		if (picked)
			ghostteleportlocs += AR.name
			ghostteleportlocs[AR.name] = AR

	ghostteleportlocs = sortAssoc(ghostteleportlocs)

	return 1


// ===
/area
	var/global/global_uid = 0
	var/uid
	var/tmp/camera_id = 0 // For automatic c_tag setting
	var/artillery_integrity = 100

/area/New()
	icon_state = ""
	layer = 10
	uid = ++global_uid
	all_areas += src

	if(!requires_power || config.machinery_does_not_use_power)
		power_light = 0
		power_equip = 0
		power_environ = 0

	..()

	update_snowfall_valid_turfs()

/area/proc/initialize()
	if(config.machinery_does_not_use_power)
		requires_power = 0
	if(!requires_power || !apc)
		power_light = 0
		power_equip = 0
		power_environ = 0
	power_change()		// all machines set to current power level, also updates lighting icon

/area/proc/get_contents()
	return contents

/area/proc/get_turfs()
	. = get_contents()
	. -= typesof(/obj)
	. -= typesof(/mob)

/area/proc/get_mobs()
	. = get_contents()
	. -= typesof(/turf)
	. -= typesof(/obj)

/area/proc/get_objs()
	. = get_contents()
	. -= typesof(/turf)
	. -= typesof(/mob)

/area/proc/lift_master()
	for (var/obj/lift_controller/master in contents)
		return master
	return null

/area/proc/get_camera_tag(var/obj/machinery/camera/C)
	return "[name] [camera_id++]"

/area/proc/atmosalert(danger_level, var/alarm_source)
	return

/area/proc/air_doors_close()
	return

/area/proc/air_doors_open()
	return

/area/proc/fire_alert()
	return

/area/proc/fire_reset()
	return

/area/proc/readyalert()
	if(!eject)
		eject = 1
		updateicon()
	return

/area/proc/readyreset()
	if(eject)
		eject = 0
		updateicon()
	return
/*
/area/proc/partyalert()
	if (!( party ))
		party = 1
		updateicon()
		mouse_opacity = 0
	return

/area/proc/partyreset()
	return
*/
/area/proc/updateicon()
	if ((fire || eject) && (!requires_power||power_environ) && !istype(src, /area/space))//If it doesn't require power, can still activate this proc.
		if(fire)
			//icon_state = "blue"
			for(var/obj/machinery/light/L in src)
				if(istype(L, /obj/machinery/light/small))
					continue
				L.set_red()
	/*	else if (atmosalm == 2)
			for(var/obj/machinery/light/L in src)
				if(istype(L, /obj/machinery/light/small))
					continue
				L.set_blue()
		else if(!fire && eject && !party && !(atmosalm == 2))
			icon_state = "red"
		else if(party && !fire && !eject && !(atmosalm == 2))
			icon_state = "party"*/
		//else
			//icon_state = "blue-red"
	else
	//	new lighting behaviour with obj lights
		icon_state = null
		for(var/obj/machinery/light/L in src)
			if(istype(L, /obj/machinery/light/small))
				continue
			L.reset_color()


/*
#define EQUIP 1
#define LIGHT 2
#define ENVIRON 3
*/

/area/proc/powered(var/chan)		// return true if the area has power to given channel

	if(!requires_power)
		return 1
	if(always_unpowered)
		return 0
	switch(chan)
		if(EQUIP)
			return power_equip
		if(LIGHT)
			return power_light
		if(ENVIRON)
			return power_environ

	return 0

// called when power status changes
/area/proc/power_change()
	for(var/obj/machinery/M in src)	// for each machine in the area
		M.power_change()			// reverify power status (to update icons etc.)
	if (fire || eject)
		updateicon()

/area/proc/usage(var/chan)
	var/used = 0
	switch(chan)
		if(LIGHT)
			used += used_light
		if(EQUIP)
			used += used_equip
		if(ENVIRON)
			used += used_environ
		if(TOTAL)
			used += used_light + used_equip + used_environ
	return used

/area/proc/clear_usage()
	used_equip = 0
	used_light = 0
	used_environ = 0

/area/proc/use_power(var/amount, var/chan)
	switch(chan)
		if(EQUIP)
			used_equip += amount
		if(LIGHT)
			used_light += amount
		if(ENVIRON)
			used_environ += amount


var/list/mob/living/forced_ambiance_list = new

/area/Entered(A)
	if(!istype(A,/mob/living))	return

	var/mob/living/L = A
	if(!L.ckey)	return

	if(!L.lastarea)
		L.lastarea = get_area(L.loc)

	var/area/newarea = get_area(L.loc)
	var/area/oldarea = L.lastarea
	if((oldarea.has_gravity == 0) && (newarea.has_gravity == 1) && (L.m_intent == "run")) // Being ready when you change areas gives you a chance to avoid falling all together.
		thunk(L)
		L.update_floating( L.Check_Dense_Object() )

	L.lastarea = newarea
	play_ambience(L)

/area/proc/play_ambience(var/mob/living/L)
    // Ambience goes down here -- make sure to list each area seperately for ease of adding things in later, thanks! Note: areas adjacent to each other should have the same sounds to prevent cutoff when possible.- LastyScratch
	if(!(L && L.is_preference_enabled(/datum/client_preference/play_ambiance)))    return

	var/client/CL = L.client

	if(CL.ambience_playing) // If any ambience already playing
		if(forced_ambience && forced_ambience.len)
			if(CL.ambience_playing in forced_ambience)
				return 1
			else
				var/new_ambience = pick(pick(forced_ambience))
				CL.ambience_playing = new_ambience
				L << sound(new_ambience, repeat = 1, wait = 0, volume = 30, channel = SOUND_CHANNEL_AMBIENCE)
				return 1
		if(CL.ambience_playing in ambience)
			return 1

	if(ambience.len && prob(35))
		if(world.time >= L.client.played + 600)
			var/sound = pick(ambience)
			CL.ambience_playing = sound
			L << sound(sound, repeat = 0, wait = 0, volume = 10, channel = SOUND_CHANNEL_AMBIENCE)
			L.client.played = world.time
			return 1
	/*else // disabled ship ambience because this is WORLD WAR II - Kachnov
		var/sound = 'sound/ambience/shipambience.ogg'
		CL.ambience_playing = sound
		L << sound(sound, repeat = 1, wait = 0, volume = 30, channel = SOUND_CHANNEL_AMBIENCE)
*/
/area/proc/gravitychange(var/gravitystate = 0, var/area/A)
	A.has_gravity = gravitystate

	for(var/mob/M in A)
		if(has_gravity)
			thunk(M)
		M.update_floating( M.Check_Dense_Object() )

/area/proc/thunk(mob)
	if(istype(get_turf(mob), /turf/space)) // Can't fall onto nothing.
		return

	if(istype(mob,/mob/living/carbon/human/))
		var/mob/living/carbon/human/H = mob
		if(istype(H.shoes, /obj/item/clothing/shoes/magboots) && (H.shoes.item_flags & NOSLIP))
			return

		if(H.m_intent == "run")
			H.AdjustStunned(2)
			H.AdjustWeakened(2)
		else
			H.AdjustStunned(1)
			H.AdjustWeakened(1)
		mob << "<span class='notice'>The sudden appearance of gravity makes you fall to the floor!</span>"

/area/proc/has_gravity()
	return has_gravity

/area/space/has_gravity()
	return 0

/proc/has_gravity(atom/AT, turf/T)
	return 1
