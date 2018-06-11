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

def convert_time(time)
	# return the current local day with the specified time (which is already local) or nil
	tz = TZInfo::Timezone.get('America/Los_Angeles')
	puts "server time is: #{Time.now}"
	puts "time passed in: #{time}"
	# first see if Chronic recognizes the time as valid
	return nil if !Chronic.parse(time)
	# determine the current date in local time and then add the time back in
	local_date = tz.utc_to_local(Time.now).to_date
	calculated_local_datetime = Chronic.parse(local_date.to_s + ' at ' + time)
	return calculated_local_datetime
end

def get_active_range(time_string)
	# time_string is either something like "9:30", "2:30PM", "14:00" OR "in 3 minutes", "3", "3 mins"
	# search for colon, if colon, try to call convert_time
	tz = TZInfo::Timezone.get('America/Los_Angeles')
	if time_string.include?(':')
		start_time = convert_time(time_string)
		return nil if !start_time
		# with a good start time, calculate the end time (45 mins later for eggs)
  	hatch_time = start_time.strftime("%-I:%M")	
  	despawn_time = (start_time + 45*60).strftime("%-I:%M")
  	return [hatch_time, despawn_time]
	else
		# to do: strip out all but the number and allow user to do "in x minutes" in the command line
		time = "in " + time_string + " minutes"
		parsed_time = Chronic.parse(time)
		return nil if !parsed_time
  	hatch_time = tz.utc_to_local(parsed_time).strftime("%-I:%M")	
  	despawn_time = tz.utc_to_local(parsed_time + 45*60).strftime("%-I:%M")
  	return [hatch_time, despawn_time]		
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
