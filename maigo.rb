require 'bundler/setup'
require 'discordrb'
require_relative 'maigodb'

prefix = ENV['DISCORD_PREFIX']

bot = Discordrb::Commands::CommandBot.new token: ENV['DISCORD_TOKEN'], 
																					client_id: ENV['DISCORD_CLIENT_ID'], 
																					prefix: prefix
def format_embed(search_term, gym) 
	embed = Discordrb::Webhooks::Embed.new 
	if gym['name']
		embed.color = 0x1EFFBC
		if gym['gmap']
			embed.title = gym['name'] + ' (click for google map)'	
			embed.url = gym['gmap']
		else
			embed.title = gym['name']
			embed.url = nil
		end
		# echo back an aka if name is different from search term
		if gym['name'].downcase != search_term.downcase
			embed.title = search_term + ', aka ' + embed.title
		end

		embed.description = gym['address']

		if gym['landmark']
			embed.description = embed.description + "\n" + gym['landmark']
		end
	end

	return embed
end


usage_text = prefix  + 'whereis [gym name]'

bot.command(:whereis, min_args: 1, description: 'find a Pogo gym', usage: usage_text) do |event, *gym| 
	search_term = gym.join(' ')
	message = lookup(search_term)
	if message['name']
		embed_gym = format_embed(search_term, message)
		bot.send_message(event.channel.id,'',false, embed_gym)
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

bot.run