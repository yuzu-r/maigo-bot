def log_command(_event, command, is_success, fallback_msg, param = nil)
	return if !Bot::LOGGING || Bot::LOGGING == 'false'
	response = log(_event.server.id, _event.user.id, command, param, is_success)
	if !response || response.n != 1
		puts fallback_msg
	end
	return
end

def get_raids_channel(bot, server)
	channel_array = bot.find_channel('raids', server.name)
	channel_array.empty? ? nil : channel_array.first
end

def get_bot_pin(raid_channel, bot_id)
	pinned_messages = raid_channel.pins
	if pinned_messages.count > 0
		bot_pin = nil
		pinned_messages.each do |message|
			if message.author.id == bot_id
				bot_pin = message
				break
			end
		end
	end
	return bot_pin
end

def convert_time(time)
	# return the current local day with the specified local time or nil
	puts "server time is: #{Time.now}"
	puts "time passed in: #{time}"
	# first see if Chronic recognizes the time as valid
	return nil if !Chronic.parse(time)
	# determine the hour which can be ambiguous at 6 am / 6 pm
	# if it is 5:30 am and 6:30 is entered, we mean 6:30 am
	# if it is 5:30 pm and 6:30 is entered, we mean 6:30 pm

	local_hour = Time.now.hour
	
	given_hour = time.slice(0,time.index(':')).to_i
	given_minutes = time.slice(time.index(':')+1..-1)
	adjusted_time = time
	
	if local_hour > 12 && given_hour < 12
		# create a 24hr time if needed
		adjusted_hour = given_hour + 12
		adjusted_time = adjusted_hour.to_s + ':' + given_minutes
		puts "new time is: #{adjusted_time}"
	end
	calculated_local_datetime = Chronic.parse('today at ' + adjusted_time)
	return calculated_local_datetime
end

def get_active_range(time_string)
	# time_string is either something like "9:30", "2:30PM", "14:00" OR "in 3 minutes", "3", "3 mins"
	# search for colon, if colon, try to call convert_time
	if time_string.include?(':')
		start_time = convert_time(time_string)
		return nil if !start_time
		# with a good start time, calculate the end time (45 mins later for eggs)
  	despawn_time = start_time + Bot::RAID_DURATION*60
  	return [start_time, despawn_time]
	else
		time = "in " + time_string + " minutes"
		parsed_time = Chronic.parse(time)
		return nil if !parsed_time
		puts "parsed_time from chronic is: #{parsed_time}"
		start_time = parsed_time
  	despawn_time = start_time + Bot::RAID_DURATION * 60
  	return [start_time, despawn_time]		
	end
end

def comma_parse(command_line)
	command_string = command_line.join('.').gsub(/\./,' ')
	command_array = command_string.split(',') 
	parsed_command = command_array.map {|s| s.strip}	
	return parsed_command
end

def param_check(command_line, num_required_params)
	command_line.scan(/(?=,)/).count == num_required_params ? true : false
end

def format_utc_to_local(utc_time)
	tz = TZInfo::Timezone.get('America/Los_Angeles')
	tz.utc_to_local(utc_time).strftime("%-I:%M")
end

def build_activity_list(bot, active_raids, current_message = '')
	return current_message if !active_raids || active_raids.count == 0
	emoji = bot.find_emoji(Bot::LEGENDARY_EMOJI)
	emoji_text = emoji ? emoji.mention : ':exclamation:'
	active_raids.each do |raid|
  	recent_indicator = raid['is_recent'] ? ':new:' : ''
  	ex_gym_indicator = is_ex?(raid['gym']) ? emoji_text : ''
  	# having more than one '' in a row breaks display on iphone (10/29/18)
  	indicators = ex_gym_indicator + recent_indicator
  	if raid['tier'] # it's an egg
  		convert_hatch_time = format_utc_to_local(raid['hatch_time'])
  		convert_despawn_time = format_utc_to_local(raid['despawn_time'])
			current_message += "#{raid['tier']}* (#{convert_hatch_time} to **#{convert_despawn_time}**) @ #{raid['gym']} #{indicators}\n"
		else # it's a raid
  		convert_despawn_time = format_utc_to_local(raid['despawn_time'])
			current_message += "#{raid['boss'].capitalize} (**#{convert_despawn_time}**) @ #{raid['gym']} #{indicators}\n"
		end
	end
	current_message
end

def silent_update(server, bot)
	active_raids = sort_raids(find_active_raids(server.id.to_s))
	raid_message = "**Reported Active and Pending Raids**\n"
	if !active_raids || active_raids.count == 0
	else
		raid_message = build_activity_list(bot, active_raids, raid_message)
	end
	# update the pinned message
	raid_channel = get_raids_channel(bot, server)
	if raid_channel
		bot_pin = get_bot_pin(raid_channel, bot.profile.id)
		if bot_pin
			# edit the message already in pinned
			bot_pin.edit(raid_message)
		else
			# create a new pinned message by the bot
			bot_pin = bot.send_message(raid_channel.id, raid_message)
			bot_pin.pin
		end
	end
end

def sort_and_pin(event)
	m = nil # init message
	raid_channel = get_raids_channel(event.bot, event.server) || event.channel
	bot_pin = get_bot_pin(raid_channel, event.bot.profile.id) 
	active_raids = sort_raids(find_active_raids(event.server.id.to_s))
	raid_message = "**Reported Active and Pending Raids**\n"
	if !active_raids || active_raids.count == 0 
		no_raid_message = "There are no active raids or pending eggs at this time. Rats."
		if bot_pin
			bot_pin.edit(raid_message)
		else
			new_pin = event.bot.send_message(raid_channel.id, raid_message)
			new_pin.pin
		end
		m = event.bot.send_message(raid_channel.id, no_raid_message)
	else
		raid_message += "Boss despawn time is shown in **bold**.\n"
		raid_message = build_activity_list(event.bot, active_raids, raid_message)
		if bot_pin
			bot_pin.edit(raid_message)
			m = event.bot.send_message(raid_channel.id, raid_message)
		else
			new_pin = event.bot.send_message(raid_channel.id, raid_message)
			new_pin.pin
		end
	end
	if Bot::LastMessage[event.server.id.to_s]
		Bot::LastMessage[event.server.id.to_s].delete
	end
	Bot::LastMessage[event.server.id.to_s] = m

end

def sort_raids(active_events)
	# take db results from get_active_raids
	tz = TZInfo::Timezone.get('America/Los_Angeles')
	recent_event_mins = 5 # reported within this many minutes ago to be considered new
	recent_cutoff = tz.local_to_utc(Time.now - recent_event_mins * 60)
	active_events.each do |e|
		create_date = e['_id'].generation_time
		e['is_recent'] = create_date > recent_cutoff 
	end
	return active_events
end

def delete_message_queue(queue,event,is_good_command = true)
	raid_channel = get_raids_channel(event.bot, event.server) || event.channel
	if is_good_command
		while queue && queue.count > 0
			message_id = queue.pop
			message = raid_channel.message(message_id)
			if message
				message.delete
			end
		end
	end
	queue.push event.message.id
end

def get_user_nickname(server, user_id)
	# to do: move this to discord_helpers
	member = server.member(user_id)
	return member.nil? ? "<unown>" : member.display_name
end

def hatch_egg(server, user, egg_id, boss)
	reported_by = user.display_name
	db_response = egg_to_raid(server.id.to_s, user.id, reported_by, egg_id, boss)
	return db_response
end

def repeat_post(event, channel_id, message)
	event.bot.send_message(channel_id, message)
end