// At minimum every mob has a hear_say proc.

/mob/proc/hear_say(var/message, var/verb = "says", var/datum/language/language = null, var/alt_name = "",var/italics = 0, var/mob/speaker = null, var/sound/speech_sound, var/sound_vol)
	if(!client)
		return

	if(speaker && !speaker.client && isghost(src) && is_preference_enabled(/datum/client_preference/ghost_ears) && !(speaker in view(src)))
			//Does the speaker have a client?  It's either random stuff that observers won't care about (Experiment 97B says, 'EHEHEHEHEHEHEHE')
			//Or someone snoring.  So we make it where they won't hear it.
		return

	//make sure the air can transmit speech - hearer's side

	if(sleeping || stat == 1)
		hear_sleep(message)
		return

	//non-verbal languages are garbled if you can't see the speaker. Yes, this includes if they are inside a closet.
	if (language && (language.flags & NONVERBAL))
		if (!speaker || (src.sdisabilities & BLIND || src.blinded) || !(speaker in view(src)))
			message = stars(message)

	if(!(language && (language.flags & INNATE))) // skip understanding checks for INNATE languages
		if(!say_understands(speaker,language))
			if(istype(speaker,/mob/living/simple_animal))
				var/mob/living/simple_animal/S = speaker
				message = pick(S.speak)
			else
				if(language)
					message = language.scramble(message)
				else
					message = stars(message)

	var/speaker_name = speaker.name
	if(istype(speaker, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = speaker
		speaker_name = H.rank_prefix_name(H.GetVoice())

	if(italics)
		message = "<i>[message]</i>"

	var/track = null
	if(isghost(src))
		if(italics && is_preference_enabled(/datum/client_preference/ghost_radio))
			return
		if(speaker_name != speaker.real_name && speaker.real_name)
			speaker_name = "[speaker.real_name] ([speaker_name])"
		track = "([ghost_follow_link(speaker, src)]) "
		if(is_preference_enabled(/datum/client_preference/ghost_ears) && (speaker in view(src)))
			message = "<b>[message]</b>"

	if(sdisabilities & DEAF || ear_deaf)
		if(!language || !(language.flags & INNATE)) // INNATE is the flag for audible-emote-language, so we don't want to show an "x talks but you cannot hear them" message if it's set
			if(speaker == src)
				src << "<span class='warning'>You cannot hear yourself speak!</span>"
			else
				src << "<span class='name'>[speaker_name]</span>[alt_name] talks but you cannot hear \him."
	else
		if(language)
			on_hear_say("<span class='game say'><span class='name'>[speaker_name]</span>[alt_name] [track][language.format_message(message, verb)]</span>")
		else
			on_hear_say("<span class='game say'><span class='name'>[speaker_name]</span>[alt_name] [track][verb], <span class='message'><span class='body'>\"[message]\"</span></span></span>")
		if (speech_sound && (get_dist(speaker, src) <= world.view && src.z == speaker.z))
			var/turf/source = speaker? get_turf(speaker) : get_turf(src)
			src.playsound_local(source, speech_sound, sound_vol, 1)

/mob/proc/on_hear_say(var/message)
	src << message

/mob/proc/hear_radio(var/message, var/verb="says", var/datum/language/language=null, var/mob/speaker = null, var/obj/item/device/radio/source, var/hard_to_hear = 0)

	if(!client)
		return

	message = capitalize(message)

	playsound(loc, 'sound/effects/radio_chatter.ogg', 25, 0, -1)//They won't always be able to read the message, but the sound will play regardless.

	if(sleeping || stat==1) //If unconscious or sleeping
		hear_sleep(message)
		return

	var/track = null
	var/jobname // the mob's "job"

	//non-verbal languages are garbled if you can't see the speaker. Yes, this includes if they are inside a closet.
	if (language && (language.flags & NONVERBAL))
		if (!speaker || (src.sdisabilities & BLIND || src.blinded) || !(speaker in view(src)))
			message = stars(message)

	if(!(language && (language.flags & INNATE))) // skip understanding checks for INNATE languages
		if(!say_understands(speaker,language))
			if(istype(speaker,/mob/living/simple_animal))
				var/mob/living/simple_animal/S = speaker
				if(S.speak && S.speak.len)
					message = pick(S.speak)
				else
					return
			else
				if(language)
					message = language.scramble(message)
				else
					message = stars(message)

		if(hard_to_hear)
			message = stars(message)

	var/speaker_name = speaker.name

	if(istype(speaker, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = speaker
		if(H.voice)
			speaker_name = H.voice
	/*	for(var/datum/data/record/G in data_core.general)
			if(G.fields["name"] == speaker_name)
				speaker_name = H.rank_prefix_name(speaker_name)
				break*/

		if(H.age && H.gender)//If they have an age and gender
			var/ageAndGender
			jobname = H.get_assignment_noid()
			if (jobname != "N/A")
				jobname = "[jobname] "

			ageAndGender = ageAndGender2Desc(H.age, H.gender)//Get their age and gender
			if (jobname == "N/A")
				ageAndGender = ""

			speaker_name += " \[" + "[jobname]" + "[ageAndGender]" + "]"//Print it out.

	if(hard_to_hear)
		speaker_name = "unknown"

	if(isghost(src))
		if(speaker_name != speaker.real_name && !isAI(speaker)) //Announce computer and various stuff that broadcasts doesn't use it's real name but AI's can't pretend to be other mobs.
			speaker_name = "[speaker.real_name] ([speaker_name])"
		track = /*"[speaker_name] */"([ghost_follow_link(speaker, src)])"

	if (dd_hasprefix(message, " "))
		message = copytext(message, 2)

	message = "<span class = [source.span_class()]>[verb],</b> \"[message]\"</span>"

	if(sdisabilities & DEAF || ear_deaf)
		if(prob(20))
			src << "<span class='warning'>You feel your headset vibrate but can hear nothing from it!</span>"
	else
		var/fontsize = 2

		if (speaker.original_job.is_officer) // experimental
			fontsize = 3
/*
		if (istype(speaker.original_job, /datum/job/german/commander))
			fontsize = 3
		else if (istype(speaker.original_job, /datum/job/german/staff_officer))
			fontsize = 3
		else if (istype(speaker.original_job, /datum/job/german/squad_leader))
			fontsize = 3
		else if (istype(speaker.original_job, /datum/job/german/stabsgefreiter))
			fontsize = 3
		else if (istype(speaker.original_job, /datum/job/german/artyman))
			fontsize = 3
		else if (istype(speaker.original_job, /datum/job/german/conductor))
			fontsize = 3
		else if (istype(speaker.original_job, /datum/job/german/squad_leader_ss))
			fontsize = 3
		else if (istype(speaker.original_job, /datum/job/russian/commander))
			fontsize = 3
		else if (istype(speaker.original_job, /datum/job/russian/staff_officer))
			fontsize = 3
		else if (istype(speaker.original_job, /datum/job/russian/squad_leader))
			fontsize = 3
		else if (istype(speaker.original_job, /datum/job/russian/zavhoz))
			fontsize = 3
*/
		var/full_message = "<font size = [fontsize]><b><span class = [source.span_class()]>[source.bracketed_name()] [speaker_name] [message]</span></font>"
		if (track)
			full_message = "<font size = [fontsize]><b><span class = [source.span_class()]>[source.bracketed_name()] [speaker_name] ([track]) [message]</span></font>"
		on_hear_radio(source, full_message)

/proc/say_timestamp()
	return "<span class='say_quote'>\[[stationtime2text()]\]</span>"

/mob/proc/on_hear_radio(var/obj/item/device/radio/source, var/fullmessage)
	src << "\icon[getFlatIcon(source)] [fullmessage]"

/mob/observer/ghost/on_hear_radio(var/obj/item/device/radio/source, var/fullmessage)
	src << "\icon[getFlatIcon(source)] [fullmessage]"

/mob/proc/hear_signlang(var/message, var/verb = "gestures", var/datum/language/language, var/mob/speaker = null)
	if(!client)
		return

	if(say_understands(speaker, language))
		message = "<B>[src]</B> [verb], \"[message]\""
	else
		message = "<B>[src]</B> [verb]."

	if(src.status_flags & PASSEMOTES)
		for(var/obj/item/weapon/holder/H in src.contents)
			H.show_message(message)
		for(var/mob/living/M in src.contents)
			M.show_message(message)
	src.show_message(message)

/mob/proc/hear_sleep(var/message)
	var/heard = ""
	if(prob(15))
		var/list/punctuation = list(",", "!", ".", ";", "?")
		var/list/messages = splittext(message, " ")
		var/R = rand(1, messages.len)
		var/heardword = messages[R]
		if(copytext(heardword,1, 1) in punctuation)
			heardword = copytext(heardword,2)
		if(copytext(heardword,-1) in punctuation)
			heardword = copytext(heardword,1,lentext(heardword))
		heard = "<span class = 'game_say'>...You hear something about...[heardword]</span>"

	else
		heard = "<span class = 'game_say'>...<i>You almost hear someone talking</i>...</span>"

	src << heard
