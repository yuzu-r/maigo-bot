def get_emoji_mention(emoji_name, server_emojis)
	emoji_mention = ''
	server_emojis.each do |key, e|
	  if e.name == emoji_name
	  	emoji_mention = e.mention
	  	break
	  end
	end
	return emoji_mention
end

def get_raids_channel(server)
	# return the 'raids' channel if it exists on the server
	server_name = server.name
	raids_channel = nil
	server.channels.each do |channel|
		if channel.name == 'raids'
			raids_channel = channel
			break
		end
	end
	return raids_channel
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
	# return the current local day with the specified time (which is already local) or nil
	tz = TZInfo::Timezone.get('America/Los_Angeles')
	puts "server time is: #{Time.now}"
	puts "time passed in: #{time}"
	# first see if Chronic recognizes the time as valid
	return nil if !Chronic.parse(time)
	# determine the current date in local time and then add the time back in
	t = Time.now
	local_now = tz.utc_to_local(t)
	local_date = local_now.to_date
	local_hour = local_now.hour
	
	given_hour = time.slice(0,time.index(':')).to_i
	given_minutes = time.slice(time.index(':')+1..-1)
	adjusted_time = time
	
	if local_hour > 12 && given_hour < 12
		# cut off the part after the colon, fix the starting part, put back together and give to chronic
		adjusted_hour = given_hour + 12
		adjusted_time = adjusted_hour.to_s + ':' + given_minutes
		puts "new time is: #{adjusted_time}"
	end
	calculated_local_datetime = Chronic.parse(local_date.to_s + ' at ' + adjusted_time)

	# the above starts to fail when the time hits about 6 pm, thinks it's 6 am
	# can I convert to 16 minutes from now instead, which doesn't fail?
	# if it is 5:30 am and 6:30 is entered, we mean 6:30 am
	# if it is 5:30 pm and 6:30 is entered, we mean 6:30 pm
	# if current hour is less than 12, we mean the time passed in
	# if current hour is greater than 12, we mean the time passed in + 12 hours (e.g. 18:30)

	return calculated_local_datetime
end

def get_active_range(time_string)
	# time_string is either something like "9:30", "2:30PM", "14:00" OR "in 3 minutes", "3", "3 mins"
	# search for colon, if colon, try to call convert_time
	tz = TZInfo::Timezone.get('America/Los_Angeles')
	if time_string.include?(':')
		start_time = convert_time(time_string) # note: sometimes this will asssume AM when it should be PM
		return nil if !start_time
		# with a good start time, calculate the end time (45 mins later for eggs)
  	despawn_time = start_time + 45*60
  	return [start_time, despawn_time]
	else
		time = "in " + time_string + " minutes"
		parsed_time = Chronic.parse(time)
		return nil if !parsed_time
  	start_time = tz.utc_to_local(parsed_time)
  	despawn_time = start_time + 45 * 60
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
