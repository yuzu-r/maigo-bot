module Bot::DiscordEvents
  # This event is processed each time the bot succesfully connects to discord.
  module Ready
    extend Discordrb::EventContainer
    ready do |_event|
    	_event.bot.servers.each do |server_id, server|
    		Bot::Trains[server_id] = Train.new
    	end
			tz = TZInfo::Timezone.get('America/Los_Angeles')
			cron_string = "*/" + Bot::CLEAN_INTERVAL.to_s + " 13-23,0-2 * * *"
			#Bot::Scheduler.cron '*/15 13-23,0-2 * * *' do
			# start at 6, stop at 8 local
			Bot::Scheduler.cron cron_string do
				puts "cleanup time: #{Time.now}, #{tz.utc_to_local(Time.now)}"
				_event.bot.servers.each do |server_id, server|
					raids_channel = get_raids_channel(server)
					silent_update(server, _event.bot)	
				end
			end
		end
  end
end
