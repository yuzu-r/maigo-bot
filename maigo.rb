require 'bundler/setup'
require 'discordrb'
require_relative 'maigodb'

prefix = ENV['DISCORD_PREFIX']
logging = ENV['LOGGING']

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
		if message['is_ex_eligible']
			event << 'EX Raid Location!'
		end
		event << message['address']
		if message['landmark']
			event << 'Near: ' + message['landmark']
		end
		# suppress the map preview for brevity
		google_maps = message['gmap'] ? '<' + message['gmap'] + '>' : nil
		if logging.to_s == 'true'
			response = log(event.server.id, event.user.id, 'whereis', search_term, true)
			if !response || response.n != 1
				puts "could not log whereis to database, successful search for #{search_term}"
			end
		end
		event << google_maps
	else
		# either multiple gyms returned, or no gyms found
		if logging.to_s == 'true'
			response = log(event.server.id, event.user.id, 'whereis', search_term, false)
	 		if !response || response.n != 1
	 			puts "could not log whereis to database, unsuccessful search for #{search_term}"
			end
		end
		message
	end
end

bot.command(:help, description: 'maigo-helper help') do |event|
  event << "Type ***#{prefix}whereis*** and a gym name or nickname to look up its location."
  event << "Try ***#{prefix}whereis happy donuts*** to see it in action."
  event << "It is not case sensitive. In most cases, it can guess an incomplete name, not typo-ed names."
  event << "In other words, ***#{prefix}whereis donut*** will work, but ***#{prefix}whereis hapy donts*** will not."
  event << "If the entered name isn\'t unique, maigo-helper will return a list of suggestions to narrow down your search."
  event << "\nType ***#{prefix}exgyms*** to see a listing of El Cerrito/Albany gyms known to hold ex raids."
	if logging.to_s == 'true'
		response = log(event.server.id, event.user.id, 'help', nil, true)
		if !response || response.n != 1
			puts "could not log help command to database"
		end
	end
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
		if logging.to_s == 'true'
			response = log(event.server.id, event.user.id, 'exgyms', nil, true)
			if !response || response.n != 1
				puts "could not log exgyms command to database"
			end
		end
	end
	return
end

bot.run