require 'bundler/setup'
require 'discordrb'
require_relative 'maigodb'
require_relative 'helpers'
require 'chronic'
require 'tzinfo'

prefix = ENV['DISCORD_PREFIX']

bot = Discordrb::Commands::CommandBot.new token: ENV['DISCORD_TOKEN'], 
																					client_id: ENV['DISCORD_CLIENT_ID'], 
																					prefix: prefix

usage_text = prefix  + 'whereis [gym name]'

bot.command(:whereis, min_args: 1, description: 'find a PoGo gym', usage: usage_text) do |event, *gym| 
	username = event.user.display_name
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
	username = event.user.display_name
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
	username = event.user.display_name
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
	raid_channel = get_raids_channel(event.server) || bot.channel
	username = event.user.display_name

	parsed_raid_data = comma_parse(raid_info)
	if parsed_raid_data.count != 3
		error_msg = "Usage: ,raid <gym>,<minutes remaining>, <boss> (separated by commas)"
		event.respond event.user.mention + ' ' + error_msg
		return		
	else
		gym, minutes_left, boss = parsed_raid_data
	end

	tz = TZInfo::Timezone.get('America/Los_Angeles')
	despawn_time = tz.utc_to_local(Time.now + minutes_left.to_i*60)

	gym_data = lookup(gym)
	if gym_data['gmap']
		gym_info = '[' + gym + ']' + '(' + gym_data['gmap'] + ')'
	else
		gym_info = gym
	end

	response = register_raid(gym, despawn_time, boss, username, event.server.id)
	if !response || response.n != 1
		puts "could not log raid to database"
	end
	embed = Discordrb::Webhooks::Embed.new
	embed.title = "**#{boss.capitalize} raid until #{despawn_time.strftime("%-I:%M")}! (#{minutes_left} mins left)**"
	embed.color = 15236612
	embed.description = "Gym: #{gym_info} (reported by #{username})"
	bot.send_message(raid_channel.id, '',false, embed)

	# look for a pinned message from the bot
	bot_pin = get_bot_pin(raid_channel, bot.profile.id)
	if bot_pin
		# edit the message already in pinned
		active_raids_msg = bot_pin.content + "\n#{boss.capitalize} (**#{despawn_time.strftime("%-I:%M")}**) @ #{gym}"
		bot_pin.edit(active_raids_msg)
	else
		# create a new pinned message by the bot
		active_raids_msg = "**Active and Pending Raids** \n#{boss.capitalize} (**#{despawn_time.strftime("%-I:%M")}**) @ #{gym}"
		bot_pin = bot.send_message(raid_channel.id, active_raids_msg)
		bot_pin.pin
	end
	event.message.react("✅")
	return
end

bot.command(:egg, min_args: 1, description: 'report an egg') do |egg_event, *egg_info|  
	tier_list = [1,2,3,4,5]
	parsed_egg_data = comma_parse(egg_info)
	if parsed_egg_data.count < 2 || parsed_egg_data.count > 3
		usage_msg = "Usage: ,egg <gym>,<minutes to hatch>, <tier> (separated by commas)"
		egg_event.respond egg_event.user.mention + ' ' + usage_msg
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
  		egg_event.respond egg_event.user.mention + ' ' + time_error_msg
  		return
  	else
  		hatch_time, despawn_time = hatch_data
  	end
  	egg_channel = get_raids_channel(egg_event.server) || bot.channel
		username = egg_event.user.display_name

  	# match color to tier
  	case tier.to_i
  	when 1..2
  		color = 16724889
  	when 3..4
  		color = 13421568
  	else
  		color = 8028868
  	end

		gym_data = lookup(gym)
		if gym_data['gmap']
			gym_info = '[' + gym + ']' + '(' + gym_data['gmap'] + ')'
		else
			gym_info = gym
		end

  	response = register_egg(gym, hatch_time, despawn_time, tier.to_i, username, egg_event.server.id)
		if !response || response.n != 1
			puts "could not log egg to database"
		end

  	embed = Discordrb::Webhooks::Embed.new
  	embed.title = "**#{tier}* hatches #{hatch_time.strftime("%-I:%M")} (despawns #{despawn_time.strftime("%-I:%M")})**"
  	embed.color = color
  	embed.description = "Gym: #{gym_info} (reported by #{username})"
  	bot.send_message(egg_channel.id, '',false, embed)

		# look for a pinned message from the bot
		bot_pin = get_bot_pin(egg_channel, bot.profile.id)
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
		egg_event.respond egg_event.user.mention + ' Please check the egg tier (1-5 allowed)'
	end

	return
end

def sort_and_pin(event, bot)
	active_raids = find_active_raids(event.server.id.to_s)	
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
	raid_channel = get_raids_channel(event.server) || bot.channel
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

bot.command(:update, description: 'sort and pin active raids') do |event|
	sort_and_pin(event, bot)
	return
end

bot.command(:leaderboard, description: 'raid/egg reporter leaderboard') do |event|
	response = get_reporters(event.server.id.to_s)
	rank = 1
	reporter_text = "Thank you to *all* reporters!"
	reporter_text += "\n**+=+=+=+=+=+=+=+=+=+=+**\n"
	response.each do |reporter|
		if rank == 1
			reporter_text += "\n:first_place: #{reporter['_id']} (#{reporter['total']})"
		else
			reporter_text += "\n    #{reporter['_id']} (#{reporter['total']})"
		end
		rank += 1
	end
	reporter_text += "\n\n**+=+=+=+=+=+=+=+=+=+=+**"
	embed = Discordrb::Webhooks::Embed.new
	embed.title = "__**Raid Reporter Leaderboard**__"
	embed.color = 15236612
	embed.description = reporter_text
	embed.timestamp = Time.now
	bot.send_message(event.channel.id,'',false, embed)
	return
end

bot.command(:rm) do |event|
	raids = find_active_raids(event.server.id.to_s)
	if !raids || raids.count == 0
		no_message = bot.send_message(event.channel.id, 'There are no raids to delete.')
		event.message.delete
		sleep 3
		no_message.delete
	else
		raid_id = 1
		delete_text = "Enter the number of the raid you wish to delete, or 0 to cancel.\n0) **Cancel delete request**"
		raids.each do |raid|
	  	if raid['tier']
				delete_text += "\n#{raid_id.to_s}) #{raid['tier']}* (#{raid['hatch_time'].strftime("%-I:%M")} to **#{raid['despawn_time'].strftime("%-I:%M")}**) @ #{raid['gym']}"
			else
				delete_text += "\n#{raid_id.to_s}) #{raid['boss'].capitalize} (**#{raid['despawn_time'].strftime("%-I:%M")}**) @ #{raid['gym']} "
			end
			raid_id += 1
		end
		initial_message = event.respond delete_text
		response = event.message.await!(timeout: 5, user: event.user)
		if response 
			target_raid = response.content.to_i
			if target_raid == 0
				cancel_message = event.respond "Delete cancelled - no changes made. Cleaning up and bugging out!"
				initial_message.delete
				response.message.delete
				event.message.delete
				sleep 3
				cancel_message.delete
			elsif target_raid > raid_id - 1
				invalid_message = event.respond "Can't find that raid to delete. Cleaning up and carrying on."
				initial_message.delete
				response.message.delete
				event.message.delete
				sleep 3
				invalid_message.delete
			else
				raid_delete_message = event.respond "ok, I will delete raid #{target_raid.to_s}."
				db_response = delete_raid(raids[target_raid-1]["_id"])
				if !db_response || db_response.n != 1
					puts "Unable to delete raid."
				else
					initial_message.delete
					response.message.delete
					event.message.delete
					sort_and_pin(event, bot)
					sleep 3
					raid_delete_message.delete
				end
			end
		else
			timeout_message = event.respond "Timeout - nothing will be deleted."
			initial_message.delete
			event.message.delete
			sleep 3
			timeout_message.delete
		end
	end
end

bot.run