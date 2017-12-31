var/global/datum/controller/process/ticker/tickerProcess

/datum/controller/process/ticker
	var/lastTickerTimeDuration
	var/lastTickerTime

/datum/controller/process/ticker/setup()
	name = "ticker"
	schedule_interval = 20 // every 2 seconds

	lastTickerTime = world.timeofday

	if(!ticker)
		ticker = new

	tickerProcess = src

	spawn(0)
		if(ticker)
			ticker.pregame()
		start_serverswap_loop()

/datum/controller/process/ticker/doWork()
	var/currentTime = world.timeofday

	if(currentTime < lastTickerTime) // check for midnight rollover
		lastTickerTimeDuration = (currentTime - (lastTickerTime - TICKS_IN_DAY)) / TICKS_IN_SECOND
	else
		lastTickerTimeDuration = (currentTime - lastTickerTime) / TICKS_IN_SECOND

	lastTickerTime = currentTime

	ticker.process()

	// todo: relocate this code - Kachnov
	for (var/obj/item/device/radio/intercom/I in world)
		I.supply_points += (rand(0.1*100, 0.3*100))/100


/datum/controller/process/ticker/proc/getLastTickerTimeDuration()
	return lastTickerTimeDuration
