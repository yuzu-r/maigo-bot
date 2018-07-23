module Bot::DiscordCommands
  module Time
    extend Discordrb::Commands::CommandContainer
    command :time do |_event, mins|
			tz = TZInfo::Timezone.get('America/Los_Angeles')
			_event.respond "#{mins} minutes from now is #{tz.utc_to_local(Time.now + mins.to_i*60).strftime("%-I:%M")}"    	
			fallback_msg = "Could not log time command to database!"
			log_command(_event, 'time', true, fallback_msg)
    end
  end
end
