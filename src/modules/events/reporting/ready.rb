module Bot::ReportingEvents
  # This event is processed each time the bot succesfully connects to discord.
  module Ready
    extend Discordrb::EventContainer
    ready do |_event|
    	_event.bot.servers.each do |server_id, server|
    		Bot::Trains[server_id] = Train.new
    		Bot::DeleteRaidMessageQueue[server_id] = []
    		Bot::DeleteEggMessageQueue[server_id] = []
    	end
			# Bot::Scheduler.cron '*/15 13-23,0-2 * * *' do # the utc version
			# start at 6, stop at 8 local
			cron_string = "*/" + Bot::CLEAN_INTERVAL.to_s + " 6-20 * * *"
			Bot::Scheduler.cron cron_string do
				puts "cleanup time: #{Time.now}"
				_event.bot.servers.each do |server_id, server|
					silent_update(server, _event.bot)	
				end
			end
		end
  end
end
