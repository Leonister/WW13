/mob/living/carbon/human
	//Hair colour and style
	var/r_hair = 0
	var/g_hair = 0
	var/b_hair = 0
	var/h_style = "Bald"

	//Facial hair colour and style
	var/r_facial = 0
	var/g_facial = 0
	var/b_facial = 0
	var/f_style = "Shaved"

	//Eye colour
	var/r_eyes = 0
	var/g_eyes = 0
	var/b_eyes = 0

	var/s_tone = 0	//Skin tone

	//Skin colour
	var/r_skin = 0
	var/g_skin = 0
	var/b_skin = 0

	var/size_multiplier = 1 //multiplier for the mob's icon size
	var/damage_multiplier = 1 //multiplies melee combat damage
	var/icon_update = 1 //whether icon updating shall take place

	var/datum/body_build/body_build = null

	var/lip_style = null	//no lipstick by default- arguably misleading, as it could be used for general makeup

	var/age = 30		//Player's age (pure fluff)
	var/b_type = "A+"	//Player's bloodtype

	var/list/all_underwear = list()
	var/backbag = 2		//Which backpack type the player has chosen. Nothing, Satchel or Backpack.

	// General information
	var/religion = ""

	//Equipment slots
	var/obj/item/wear_suit = null
	var/obj/item/w_uniform = null
	var/obj/item/shoes = null
	var/obj/item/belt = null
	var/obj/item/gloves = null
	var/obj/item/glasses = null
	var/obj/item/head = null
	var/obj/item/l_ear = null
	var/obj/item/r_ear = null
	var/obj/item/wear_id = null
	var/obj/item/r_store = null
	var/obj/item/l_store = null
	var/obj/item/s_store = null

	var/icon/stand_icon = null
	var/icon/lying_icon = null

	var/voice = ""	//Instead of new say code calling GetVoice() over and over and over, we're just going to ask this variable, which gets updated in Life()
	var/sayverb = "says"

	var/speech_problem_flag = 0

	var/miming = null //Toggle for the mime's abilities.
	var/special_voice = "" // For changing our voice. Used by a symptom.

	var/last_dam = -1	//Used for determining if we need to process all organs or just some or even none.
	var/list/bad_external_organs = list()// organs we check until they are good.

	var/xylophone = 0 //For the spoooooooky xylophone cooldown

	var/mob/remoteview_target = null
	var/hand_blood_color

	var/gunshot_residue
	var/pulling_punches // Are you trying not to hurt your opponent?

	mob_bump_flag = HUMAN
	mob_push_flags = ~HEAVY
	mob_swap_flags = ~HEAVY

	var/flash_protection = 0				// Total level of flash protection
	var/equipment_tint_total = 0			// Total level of visualy impairing items
	var/equipment_darkness_modifier			// Darkvision modifier from equipped items
	var/equipment_vision_flags				// Extra vision flags from equipped items
	var/equipment_see_invis					// Max see invibility level granted by equipped items
	var/equipment_prescription				// Eye prescription granted by equipped items
	var/list/equipment_overlays = list()	// Extra overlays from equipped items

	var/med_record = ""
	var/sec_record = ""
	var/gen_record = ""
	var/exploit_record = ""

	var/stance_damage = 0 //Whether this mob's ability to stand has been affected
	var/identifying_gender // In case the human identifies as another gender than it's biological

	var/list/all_factions = list()
	var/datum/faction/base_faction = null
	var/datum/faction/officer_faction = null
	var/datum/faction/squad/squad_faction = null
	var/datum/faction/spy_faction = null

	var/list/faction_images[100] // names are keys, values are images

	var/is_spy = 0
	var/is_jew = 0

	var/embedded_flag	  //To check if we've need to roll for damage on movement while an item is imbedded in us.
	var/obj/item/weapon/rig/wearing_rig // This is very not good, but it's much much better than calling get_rig() every update_canmove() call.

	var/list/hud_list[200]

	var/job_spawn_location = null // used to override job.spawn_location for a single mob

	var/stamina = 100
	var/max_stamina = 100

	var/shoveling_snow = 0

	/* These are stats. They affect how fast and how well you can do certain
	 * actions. All stats have a min (stats[stat][1]) and a max (stats[stat][2]),
	 * but currently no stats 'deteriorate' (in the future strength will),
	 * so stats will remain the same over the entire round. */

	/* All stat names MUST be lowercase. */

	var/list/stats = list(
		"strength" = list(100,100),
		"engineering" = list(100,100),
		"rifle" = list(100,100),
		"mg" = list(100,100),
		"medical" = list(100,100))

/mob/living/carbon/human/proc/getStat(statname)
	return stats[lowertext(statname)][1]

/mob/living/carbon/human/proc/getMaxStat(statname)
	return stats[lowertext(statname)][2]

/mob/living/carbon/human/proc/getStatCoeff(statname)
	return stats[lowertext(statname)][1]/100

/mob/living/carbon/human/proc/setStat(statname, statval)
	statval += rand(-5,5)
	// realism + balancing
	if (gender == FEMALE)
		switch (statname)
			if ("strength")
				statval -= 4
			if ("medical")
				statval += 4
	stats[statname] = list(statval, statval)