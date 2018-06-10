def comma_parse(command_line)
	command_string = command_line.join('.').gsub(/\./,' ')
	command_array = command_string.split(',') 
	parsed_command = command_array.map {|s| s.strip}	
	return parsed_command
end

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

def param_check(command_line, num_required_params)
	command_line.scan(/(?=,)/).count == num_required_params ? true : false
end

def count_em(string, substring)
  string.scan(/(?=#{substring})/).count
end