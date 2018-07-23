=begin

bot.ready do |event|
	bot.servers.each do |server_id, server|
		train = Train.new # PROBLEM here: this train is across servers!!
		raids_channel = get_raids_channel(server)
		if raids_channel
			scheduler.interval(clean_interval) do
				silent_update(server, bot)
			end			
		end
	end
end

=end