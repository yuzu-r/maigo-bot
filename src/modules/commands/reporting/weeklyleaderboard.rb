module Bot::ReportingCommands
  module Weeklyleaderboard
    extend Discordrb::Commands::CommandContainer
  	command(:leaderboard, description: 'egg/raid reporter weekly leaderboard') do |_event|
			tz = TZInfo::Timezone.get('America/Los_Angeles')
			TZInfo::Timezone.default_dst = true
			start_day_local = Chronic.parse('last ' + Bot::REPORTING_START_DAY + ' at 00:00:00')
			end_day_local = Chronic.parse('6 days from last ' + Bot::REPORTING_START_DAY + ' at 23:59:00')
			if start_day_local.wday == Time.now.wday
				start_day_local = Chronic.parse('today at 00:00:00')
				end_day_local = Chronic.parse('6 days from today at 23:59:00')
			end
			puts "Leaderboard reporting period: #{start_day_local} to #{end_day_local}"
			report_period = '__(' + start_day_local.strftime("%A, %m/%d") + ' - ' + (end_day_local).strftime("%A, %m/%d") + ')__'
			start_day_utc = tz.local_to_utc(start_day_local)
	  	response = get_weeks_reporters(_event.server.id.to_s, start_day_utc)
			rank = 1
			reporter_text = report_period +"\n"
			reporter_text += "\nThank you to *all* reporters!\n"
			reporter_text += "\n**+=+=+=+=+=+=+=+=+=+=+**\n"
			response.each do |reporter|
				reporter_nickname = get_user_nickname(_event.server, reporter['_id'])
				if rank == 1
					reporter_text += "\n:first_place: #{reporter_nickname} (#{reporter['total']})"
				else
					reporter_text += "\n    #{reporter_nickname} (#{reporter['total']})"
				end
				rank += 1
			end
			reporter_text += "\n\n**+=+=+=+=+=+=+=+=+=+=+**"
			embed = Discordrb::Webhooks::Embed.new
			embed.title = "**Raid Reporter Leaderboard**"
			embed.color = 15236612
			embed.description = reporter_text
			embed.timestamp = Time.now
			_event.bot.send_message(_event.channel.id,'',false, embed)
			return
    end
    leaderboard_text = <<~LEADERBOARD_HELP
    	**Leaderboard Command**
    	`#{Bot::PREFIX}leaderboard`
    	This experimental command will display information about who reports the most raids/eggs. It resets weekly.
    LEADERBOARD_HELP
    Bot::CommandCategories['reporting'].push :leaderboard => leaderboard_text            	
  end
end