var/datum/controller/process/mob/mob_process = null

/datum/controller/process/mob
	var/tmp/datum/updateQueue/updateQueueInstance

/datum/controller/process/mob/setup()
	name = "mob"
	schedule_interval = 20 // every 2 seconds
	start_delay = 16
	mob_process = src

/datum/controller/process/mob/started()
	..()
	if(!mob_list)
		mob_list = list()

/datum/controller/process/mob/doWork()
	for(last_object in mob_list)

		var/mob/M = last_object

		// if we're a spawned in, jobless mob: don't handle processing
		/* todo: these mobs SHOULD process if they have clients.
			right now, letting jobless mobs with or w/o clients process
			results in a lot of obscure runtimes, possibly associated
			with human.Life() calling back to living.Life() - Kach */

		if (ishuman(M) && !M.original_job)
			// runtime prevention hackcode
			if (M.client || M.ckey) // we have, or had, a client
				if (M.original_job_title)
					for (var/datum/job/J in job_master.occupations)
						if (J.title == M.original_job_title)
							M.original_job = J
							if (M.client) // runtimes occur otherwise
								goto skip1
			continue

		skip1

		if(isnull(M))
			continue

		if(isnull(M.gcDestroyed))
			try
				M.Life()
				if (world.time - M.last_movement > 7)
					M.velocity = 0
			catch(var/exception/e)
				catchException(e, M)
			SCHECK
		else
			catchBadType(M)
			mob_list -= M

/datum/controller/process/mob/statProcess()
	..()
	stat(null, "[mob_list.len] mobs")
