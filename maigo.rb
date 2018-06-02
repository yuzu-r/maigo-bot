require 'bundler/setup'
require 'discordrb'
require_relative 'maigodb'
require 'chronic'
require 'tzinfo'

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
		event << google_maps
	else
		# either multiple gyms returned, or no gyms found
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

CROSS_MARK = "\u274c".freeze
bot.command(:egg, min_args: 2, description: 'report an egg') do |event, tier, *time|  
	tier_list = [1,2,3,4,5]

	if tier_list.include?(tier.to_i)
		time_string = time.length > 0 ? time.join(' ') : nil
		if time_string
			parsed_time = Chronic.parse(time_string)
			if !parsed_time
				parsed_time = Chronic.parse('this second')
			end
		else
			parsed_time = Chronic.parse('this second')
		end
		puts parsed_time
  	# vagrant box is UTC time zone btw
  	tz = TZInfo::Timezone.get('America/Los_Angeles')

  	hatch_time = tz.utc_to_local(parsed_time).strftime("%-I:%M %p")	
  	despawn_time = tz.utc_to_local(parsed_time + 45*60).strftime("%-I:%M %p")

		message = event.respond "You are reporting a tier #{tier} egg hatching at #{hatch_time}. Please enter the gym name, or click the X to cancel this report."
		message.react CROSS_MARK
		is_message = true

	  event.user.await(:"gym#{event.user.id}") do |gym_event|
	    # why do I have to do this
	    if !is_message
	    	# should i return something to kill the event
	    	true
	    else
	    	gym = gym_event.message.content
	    	gym_lookup = lookup(gym)
	    	if gym_lookup['name']
					if gym_lookup['name'].downcase != gym.downcase
						egg_location = gym + ', aka ' + gym_lookup['name']
					else
						egg_location = gym_lookup['name']
					end
					gmap_link = gym_lookup['gmap'] ? '(<' + gym_lookup['gmap'] + '>)' : ''
	    	else
	    		egg_location = gym
	    	end
	    	server_name = event.channel.server.name
	    	channels = bot.find_channel('raids', server_name)
	    	raid_channel_id = channels.count > 0 ? channels[0].id : event.channel.id
	    	bot.send_message(raid_channel_id, "__Tier #{tier} raid will begin at #{hatch_time} (despawns #{despawn_time})__")
	    	bot.send_message(raid_channel_id, "Raid boss: not yet known")
	    	bot.send_message(raid_channel_id, "Location: #{egg_location}  #{gmap_link}")
	    	bot.send_message(raid_channel_id, "reported by: #{event.channel.server.member(event.user.id).nick}")
	    	gym_event.respond "<@" + event.user.id.to_s + "> " + "Your report has been posted to the raids channel! Thanks! "
	   		message.delete
	   		true
	    end
	  end

	  bot.add_await(:"delete_#{message.id}", Discordrb::Events::ReactionAddEvent, emoji: CROSS_MARK) do |reaction_event|
	    # Since this code will run on every CROSS_MARK reaction, it might not
	    # be on our time message we sent earlier. We use `next` to skip the rest
	    # of the block unless it was our message that was reacted to.
	    next true unless reaction_event.message.id == message.id
	    # Delete the matching message.
	    message.delete
	    is_message = false
	    true
	  end
	else
		event.respond "<@" + event.user.id.to_s + "> " + "please start your report with the egg tier (1-5)"
	end
	return
end

bot.run