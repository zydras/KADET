#define MAX_SPAWN_ATTEMPT 3


/datum/round_event/ghost_role
	fakeable = FALSE
	/// The minimum number of signups required for the event to continue past the polling period
	var/minimum_required = 1
	/// The name of the role, to be displayed in logs/polls/etc.
	var/role_name = "debug rat with cancer" // Q U A L I T Y  M E M E S
	/// A list of mobs generated by this event.
	var/list/spawned_mobs = list()
	/// Used to communicate the progress of the event firing, and whether or not the event was successfuly run.
	var/status
	/// A stored value of the event's announcement chance. Cached and not immediately used to prevent announcements for a failed event roll.
	var/cached_announcement_chance

/datum/round_event/ghost_role/start()
	try_spawning()

/**
 * Attempts to spawn the role, and cancels the event if it fails.
 *
 * Pauses the event right as it begins, and waits for setup/polling to end.
 * If successful, continues running the rest of the event and notifies ghosts.
 */

/datum/round_event/ghost_role/proc/try_spawning()
	// The event does not run until the spawning has been attempted
	// to prevent us from getting gc'd halfway through
	processing = FALSE

	status = spawn_role()
	if(isnull(cached_announcement_chance))
		cached_announcement_chance = announce_chance //only announce once we've finished the spawning loop.
	announce_chance = (status == SUCCESSFUL_SPAWN ? cached_announcement_chance : 0)
	if((status == WAITING_FOR_SOMETHING))
		var/retry_count = 0
		if(retry_count >= MAX_SPAWN_ATTEMPT)
			message_admins("[role_name] event has exceeded maximum spawn attempts. Aborting and refunding.")
			if(control && control.occurrences > 0) //Don't refund if it hasn't
				control.occurrences--
			return
		var/waittime = 300 * (2**retry_count)
		message_admins("The event will not spawn a [role_name] until certain \
			conditions are met. Waiting [waittime/10]s and then retrying.")
		addtimer(CALLBACK(src, PROC_REF(try_spawning), 0, ++retry_count), waittime)
		return

	if(!status)
		message_admins("An attempt to spawn [role_name] returned [status], this is a bug.")
		kill()
		return

	switch(status)
		if(MAP_ERROR)
			message_admins("[role_name] cannot be spawned due to a map error.")
			kill()
			return
		if(NOT_ENOUGH_PLAYERS)
			message_admins("[role_name] cannot be spawned due to lack of players signing up.")
			deadchat_broadcast(" did not get enough candidates ([minimum_required]) to spawn.", "<b>[role_name]</b>", message_type=DEADCHAT_ANNOUNCEMENT)
			kill()
			return
		if(SUCCESSFUL_SPAWN)
			message_admins("[role_name] spawned successfully.")
			if(spawned_mobs.len)
				for (var/mob/mobs as anything in spawned_mobs)
					announce_to_ghosts(mobs)
			else
				message_admins("No mobs found in the `spawned_mobs` list, this is a bug.")

	processing = TRUE

/**
 * Performs the spawning of our role. Entirely specific to the event itself.
 *
 * Should return SUCCESSFUL_SPAWN if role was successfully spawned,
 * return NOT_ENOUGH_PLAYERS if less than mimimum_required was found,
 * and return MAP_ERROR if a spawn location could not be found.
 */

/datum/round_event/ghost_role/proc/spawn_role()
	return FALSE

#undef MAX_SPAWN_ATTEMPT