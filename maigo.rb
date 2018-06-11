require 'bundler/setup'
require 'discordrb'
require_relative 'maigodb'
require_relative 'helpers'
require 'chronic'
require 'tzinfo'

# db updates
# add toots sweets as an alias
# add meet you on the corner as an alias

prefix = ENV['DISCORD_PREFIX']

bot = Discordrb::Commands::CommandBot.new token: ENV['DISCORD_TOKEN'], 
																					client_id: ENV['DISCORD_CLIENT_ID'], 
																					prefix: prefix

usage_text = prefix  + 'whereis [gym name]'

bot.command(:whereis, min_args: 1, description: 'find a PoGo gym', usage: usage_text) do |event, *gym| 
	search_term = gym.join(' ')
	message = lookup(search_term)
	if message['name']
		if message['name'].downcase != search_term.downcase
			title = search_term + ', aka ' + message['name']
		else
			title = message['name']
		end
		event << title
		event << message['address']
		if message['landmark']
			event << 'Near: ' + message['landmark']
		end
		# suppress the map preview for brevity
		google_maps = message['gmap'] ? '<' + message['gmap'] + '>' : nil
		# trying logging
		puts "successful lookup for #{search_term}"
		event << google_maps
	else
		# either multiple gyms returned, or no gyms found
		puts "not found/unique: #{search_term}"
		message
	end
end

bot.command(:help, description: 'maigo-helper help') do |event|
  event << 'Type ***?whereis*** and a gym name or nickname to look up its location.'
  event << 'Try ***?whereis happy donuts*** to see it in action.'
  event << 'It is not case sensitive. In most cases, it can guess an incomplete name, not typo-ed names.'
  event << 'In other words, ***?whereis donut*** will work, but ***?whereis hapy donts*** will not.'
  event << 'If the entered name isn\'t unique, maigo-helper will return a list of suggestions to narrow down your search.'
end

bot.command(:exit, help_available: false) do |event|
  # This is a check that only allows a user with a specific ID to execute this command. Otherwise, everyone would be
  # able to shut your bot down whenever they wanted.

  admin_array = ENV['ADMIN_IDS'].split(' ')
  break unless admin_array.include?(event.user.id.to_s)
  bot.send_message(event.channel.id, 'Bot is shutting down, byebye')
  exit
end

bot.command(:raid, min_args: 1, description: 'report a raid') do |event, *raid_info|
	server_name = event.server.name
	channels = bot.find_channel('raids', server_name)
	raid_channel_id = channels.count > 0 ? channels[0].id : bot.channel.id
	username = event.channel.server.member(event.user.id).display_name

	parsed_raid_data = comma_parse(raid_info)
	if parsed_raid_data.count != 3
		error_msg = "Usage: ,raid <boss>,<gym>,<minutes remaining> (separated by commas)"
		event.respond "<@" + event.user.id.to_s + "> " + error_msg
		return		
	else
		boss, gym, minutes_left = parsed_raid_data
	end

	tz = TZInfo::Timezone.get('America/Los_Angeles')
	despawn_time = tz.utc_to_local(Time.now + minutes_left.to_i*60).strftime("%-I:%M %p")

	#emoji_name = 'raid_ball'
	#emoji_mention = get_emoji_mention(emoji_name, event.server.emojis)

	gym_data = lookup(gym)
	if gym_data['gmap']
		gym_info = '[' + gym + ']' + '(' + gym_data['gmap'] + ')'
	else
		gym_info = gym
	end

	embed = Discordrb::Webhooks::Embed.new
	embed.title = "**#{boss.capitalize} raid until #{despawn_time}! (#{minutes_left} mins left)**"
	embed.color = 15236612
	embed.description = "Gym: #{gym_info} (reported by #{username})"
	bot.send_message(raid_channel_id, '',false, embed)

	#bot.send_message(raid_channel_id, "**#{boss.capitalize} raid until #{despawn_time}! (#{minutes_left} mins left)**")
	#bot.send_message(raid_channel_id, "Gym: #{gym} (reported by #{username})")
	event.respond "<@" + event.user.id.to_s + "> " + "Your report has been posted to the raids channel! Thanks! "

	true
	return
end

bot.command(:egg, min_args: 1, description: 'report an egg') do |egg_event, *egg_info|  
	tier_list = [1,2,3,4,5]
	#tier, gym, minutes_to_hatch = comma_parse(egg_info)
	parsed_egg_data = comma_parse(egg_info)
	puts "egg: #{parsed_egg_data}"
	if parsed_egg_data.count != 3
		usage_msg = "Usage: ,egg <tier>,<gym>,<minutes to hatch> (separated by commas)"
		egg_event.respond "<@" + egg_event.user.id.to_s + "> " + usage_msg
		return		
	else
		#tier, gym, time_to_hatch = parsed_egg_data
		tier, gym, time_string = parsed_egg_data
	end


	if tier_list.include?(tier.to_i)
		#time = "in " + minutes_to_hatch + " minutes"
		#parsed_time = Chronic.parse(time)

  	# vagrant box is UTC time zone btw
  	#tz = TZInfo::Timezone.get('America/Los_Angeles')

  	#hatch_time = tz.utc_to_local(parsed_time).strftime("%-I:%M %p")	
  	#despawn_time = tz.utc_to_local(parsed_time + 45*60).strftime("%-I:%M %p")
  	hatch_data = get_active_range(time_string)
  	if !hatch_data
  		time_error_msg = 'Please enter minutes to hatch or a valid time (e.g. 12:23)'
  		egg_event.respond "<@" + egg_event.user.id.to_s + "> " + time_error_msg
  		return
  	else
  		hatch_time, despawn_time = hatch_data
  	end
		username = egg_event.channel.server.member(egg_event.user.id).display_name
		server_name = egg_event.channel.server.name
  	channels = bot.find_channel('raids', server_name)
  	egg_channel_id = channels.count > 0 ? channels[0].id : egg_event.channel.id
  	# get emoji for egg and its id
  	case tier.to_i
  	when 1..2
  		color = 16724889
  	when 3..4
  		color = 13421568
  	else
  		color = 8028868
  	end
		#emoji_mention = get_emoji_mention(emoji_name, egg_event.server.emojis)

		gym_data = lookup(gym)
		if gym_data['gmap']
			gym_info = '[' + gym + ']' + '(' + gym_data['gmap'] + ')'
		else
			gym_info = gym
		end
  	#bot.send_message(egg_channel_id, "#{emoji_mention} **#{tier}* egg hatches #{hatch_time} (despawns #{despawn_time})**")
  	#bot.send_message(egg_channel_id, "Gym: #{gym} (reported by #{username})")
  	embed = Discordrb::Webhooks::Embed.new
  	embed.title = "**#{tier}* hatches #{hatch_time} (despawns #{despawn_time})**"
  	embed.color = color
  	embed.description = "Gym: #{gym_info} (reported by #{username})"
  	bot.send_message(egg_channel_id, '',false, embed)
  	egg_event.respond "<@" + egg_event.user.id.to_s + "> " + "Your report has been posted to the raids channel! Thanks! "
	else
		egg_event.respond "<@" + egg_event.user.id.to_s + "> " + "please start your report with the egg tier (1-5)"
	end

	return
end

bot.run