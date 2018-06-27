require 'bundler/setup'
require 'discordrb'
require_relative 'maigodb'
require_relative 'helpers'
require 'chronic'
require 'tzinfo'

# db updates
# add ec plaza bart as alias

prefix = ENV['DISCORD_PREFIX']

bot = Discordrb::Commands::CommandBot.new token: ENV['DISCORD_TOKEN'], 
																					client_id: ENV['DISCORD_CLIENT_ID'], 
																					prefix: prefix

usage_text = prefix  + 'whereis [gym name]'

bot.command(:whereis, min_args: 1, description: 'find a PoGo gym', usage: usage_text) do |event, *gym| 
	username = event.channel.server.member(event.user.id).display_name
	search_term = gym.join(' ')
	message = lookup(search_term)
	if message['name']
		if message['name'].downcase != search_term.downcase
			title = search_term + ', aka ' + message['name']
		else
			title = message['name']
		end
		event << title
		if message['is_ex_eligible']
			event << 'EX Raid Location!'
		end
		event << message['address']
		if message['landmark']
			event << 'Near: ' + message['landmark']
		end
		# suppress the map preview for brevity
		google_maps = message['gmap'] ? '<' + message['gmap'] + '>' : nil
		# trying logging
		puts "whereis: #{username} successful lookup for #{search_term}"
		event << google_maps
	else
		# either multiple gyms returned, or no gyms found
		puts "whereis: #{username} not found/unique: #{search_term}"
		message
	end
end

bot.command(:help, description: 'maigo-helper help') do |event|
	username = event.channel.server.member(event.user.id).display_name
	puts "help: #{username} asked for help"
  event << "Type ***#{prefix}whereis*** and a gym name or nickname to look up its location."
  event << "Try ***#{prefix}whereis happy donuts*** to see it in action."
  event << "It is not case sensitive. In most cases, it can guess an incomplete name, not typo-ed names."
  event << "In other words, ***#{prefix}whereis donut*** will work, but ***#{prefix}whereis hapy donts*** will not."
  event << "If the entered name isn\'t unique, maigo-helper will return a list of suggestions to narrow down your search."
  event << "\nType ***#{prefix}exgyms*** to see a listing of El Cerrito/Albany gyms known to hold ex raids."
end

bot.command(:exit, help_available: false) do |event|
  # This is a check that only allows a user with a specific ID to execute this command. Otherwise, everyone would be
  # able to shut your bot down whenever they wanted.

  admin_array = ENV['ADMIN_IDS'].split(' ')
  break unless admin_array.include?(event.user.id.to_s)
  bot.send_message(event.channel.id, 'Bot is shutting down, byebye')
  exit
end

bot.command(:exgyms, description: 'list gyms that are eligible to have ex raids') do |event|
	username = event.channel.server.member(event.user.id).display_name
	puts "exgyms: #{username} retrieving ex raid eligible gyms..."
	ex_gyms = ex_gym_lookup
	if !ex_gyms || ex_gyms.count == 0
		bot.send_message(event.channel.id, 'No ex raid gyms found.')
		return
	else
		embed = Discordrb::Webhooks::Embed.new
		embed.title = "__**Area Gyms Eligible for EX Raids:**__"
		embed.color = 15236612
		description = ""
		ex_gyms.each do |gym|
			if gym['gmap']
				gym_info = '[' + gym['name'] + ']' + '(' + gym['gmap'] + ')'
			else
				gym_info = gym['name']
			end
			description += "\n#{gym_info}"
		end
		if description.length > 2048
			description = description.slice(0,2048)
		end
		embed.description = description
		foot = Discordrb::Webhooks::EmbedFooter.new(text:"Click the gym name for google map.")
		embed.footer = foot
		bot.send_message(event.channel.id, '',false, embed)
	end
	return
end

bot.command(:raid, min_args: 1, description: 'report a raid') do |event, *raid_info|
	server_name = event.server.name
	channels = bot.find_channel('raids', server_name)
	#raid_channel_id = channels.count > 0 ? channels[0].id : bot.channel.id
	raid_channel = channels.count > 0 ? channels[0] : bot.channel
	username = event.channel.server.member(event.user.id).display_name

	parsed_raid_data = comma_parse(raid_info)
	if parsed_raid_data.count != 3
		error_msg = "Usage: ,raid <gym>,<minutes remaining>, <boss> (separated by commas)"
		event.respond "<@" + event.user.id.to_s + "> " + error_msg
		return		
	else
		gym, minutes_left, boss = parsed_raid_data
	end

	tz = TZInfo::Timezone.get('America/Los_Angeles')
	despawn_time = tz.utc_to_local(Time.now + minutes_left.to_i*60)
	#despawn_time = tz.utc_to_local(Time.now + minutes_left.to_i*60).strftime("%-I:%M")
	#emoji_name = 'raid_ball'
	#emoji_mention = get_emoji_mention(emoji_name, event.server.emojis)

	gym_data = lookup(gym)
	if gym_data['gmap']
		gym_info = '[' + gym + ']' + '(' + gym_data['gmap'] + ')'
	else
		gym_info = gym
	end

	response = register_raid(gym, despawn_time, boss, username)

	embed = Discordrb::Webhooks::Embed.new
	embed.title = "**#{boss.capitalize} raid until #{despawn_time.strftime("%-I:%M")}! (#{minutes_left} mins left)**"
	embed.color = 15236612
	embed.description = "Gym: #{gym_info} (reported by #{username})"
	bot.send_message(raid_channel.id, '',false, embed)

	#bot.send_message(raid_channel_id, "**#{boss.capitalize} raid until #{despawn_time}! (#{minutes_left} mins left)**")
	#bot.send_message(raid_channel_id, "Gym: #{gym} (reported by #{username})")
	#event.respond "<@" + event.user.id.to_s + "> " + "Your report has been posted to the raids channel! Thanks! "

	# look for a pinned message from the bot
	pinned_messages = raid_channel.pins
	if pinned_messages.count > 0
		bot_pin = nil
		pinned_messages.each do |message|
			#puts message.author.display_name, message.author.id, bot.profile.id
			if message.author.id == bot.profile.id
				bot_pin = message
				break
			end
		end
	end
	if bot_pin
		# edit the message already in pinned
		active_raids_msg = bot_pin.content + "\n#{boss.capitalize} (**#{despawn_time.strftime("%-I:%M")}**) @#{gym}"
		bot_pin.edit(active_raids_msg)
	else
		# create a new pinned message by the bot
		active_raids_msg = "**Active and Pending Raids** \n#{boss.capitalize} (**#{despawn_time.strftime("%-I:%M")}**) @#{gym}"
		bot_pin = bot.send_message(raid_channel.id, active_raids_msg)
		bot_pin.pin
	end
	event.message.react("✅")
	return
end

bot.command(:egg, min_args: 1, description: 'report an egg') do |egg_event, *egg_info|  
	tier_list = [1,2,3,4,5]
	parsed_egg_data = comma_parse(egg_info)
	puts "egg: #{parsed_egg_data}"
	if parsed_egg_data.count < 2 || parsed_egg_data.count > 3
		usage_msg = "Usage: ,egg <gym>,<minutes to hatch>, <tier> (separated by commas)"
		egg_event.respond "<@" + egg_event.user.id.to_s + "> " + usage_msg
		return
	else
		tier = parsed_egg_data.count == 2 ? 5 : parsed_egg_data[2]
		gym = parsed_egg_data[0]
		time_string = parsed_egg_data[1]
	end

	if tier_list.include?(tier.to_i)
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
  	egg_channel = channels.count > 0 ? channels[0] : egg_event.channel
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

  	response = register_egg(gym, hatch_time, despawn_time, tier.to_i, username)
  	puts "response: #{response}"
  	p response
  	embed = Discordrb::Webhooks::Embed.new
  	embed.title = "**#{tier}* hatches #{hatch_time.strftime("%-I:%M")} (despawns #{despawn_time.strftime("%-I:%M")})**"
  	embed.color = color
  	embed.description = "Gym: #{gym_info} (reported by #{username})"
  	bot.send_message(egg_channel.id, '',false, embed)

		# look for a pinned message from the bot
		pinned_messages = egg_channel.pins
		if pinned_messages.count > 0
			bot_pin = nil
			pinned_messages.each do |message|
				if message.author.id == bot.profile.id
					bot_pin = message
					break
				end
			end
		end
		if bot_pin
			# edit the message already in pinned
			active_raids_msg = bot_pin.content + "\n#{tier}* (#{hatch_time.strftime("%-I:%M")} to **#{despawn_time.strftime("%-I:%M")}**) @ #{gym}"
			bot_pin.edit(active_raids_msg)
		else
			# create a new pinned message by the bot
			active_raids_msg = "**Active and Pending Raids** \n#{tier}* (#{hatch_time.strftime("%-I:%M")} to **#{despawn_time.strftime("%-I:%M")}**) @ #{gym}"
			bot_pin = bot.send_message(egg_channel.id, active_raids_msg)
			bot_pin.pin
		end
  	egg_event.message.react("✅")
	else
		egg_event.respond "<@" + egg_event.user.id.to_s + "> " + "please check the egg tier (1-5 allowed)"
	end

	return
end

bot.command(:update, description: 'retrieve active raids') do |event|
	active_raids = find_active_raids
	raid_message = "**Active and Pending Raids**"
	if !active_raids || active_raids.count == 0 
		event.respond "There are no active raids or pending eggs at this time. Rats."
	else
	  active_raids.each do |raid|
	  	# prepare an egg message or a raid message
	  	if raid['tier']
				raid_message += "\n#{raid['tier']}* (#{raid['hatch_time'].strftime("%-I:%M")} to **#{raid['despawn_time'].strftime("%-I:%M")}**) @ #{raid['gym']}"
			else
				raid_message += "\n#{raid['boss'].capitalize} (**#{raid['despawn_time'].strftime("%-I:%M")}**) @ #{raid['gym']} "
			end
		end
		event.respond raid_message
	end
	# update the pinned message
	# look for a pinned message from the bot
	server_name = event.channel.server.name
	channels = bot.find_channel('raids', server_name)
	raid_channel = channels.count > 0 ? channels[0] : event.channel

	pinned_messages = raid_channel.pins
	if pinned_messages.count > 0
		bot_pin = nil
		pinned_messages.each do |message|
			if message.author.id == bot.profile.id
				bot_pin = message
				break
			end
		end
	end
	if bot_pin
		# edit the message already in pinned
		#active_raids_msg = bot_pin.content + "\n#{tier}* (#{hatch_time.strftime("%-I:%M")} to **#{despawn_time.strftime("%-I:%M")}**) @#{gym}"
		bot_pin.edit(raid_message)
	else
		# create a new pinned message by the bot
		#active_raids_msg = "**Active and Pending Raids** \n#{tier}* (#{hatch_time.strftime("%-I:%M")} to **#{despawn_time.strftime("%-I:%M")}**) @#{gym}"
		bot_pin = bot.send_message(raid_channel.id, raid_message)
		bot_pin.pin
	end

	return
end

bot.run