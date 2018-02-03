require 'bundler/setup'
require 'discordrb'
require_relative 'maigodb'

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
		event << message['landmark']
		event << message['gmap']
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

bot.command(:link, description: 'advice for people with link preview turned off') do |event|
	event << 'If you don\'t see the google maps link, you should turn your Link Preview on.'
	event << 'You can find this in User Settings > Text & Images > Link Preview'
end	

bot.command(:exit, help_available: false) do |event|
  # This is a check that only allows a user with a specific ID to execute this command. Otherwise, everyone would be
  # able to shut your bot down whenever they wanted.

  admin_array = ENV['ADMIN_IDS'].split(' ')
  break unless admin_array.include?(event.user.id.to_s)
  bot.send_message(event.channel.id, 'Bot is shutting down, byebye')
  exit
end

bot.run