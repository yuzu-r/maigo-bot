module Bot::ModCommands
  module WarnPrunes
    extend Discordrb::Commands::CommandContainer
    command(:warnprunes,
              min_args: 1,
              usage: 'warnprunes <days ago> <max>',
              permission_level: 1) do |event, days_ago, max_prunes = 10|
      if event.channel.id == Bot::PURGE_CHANNEL_ID
        event.respond "Looking for unverified members who joined over #{days_ago} days ago..."
        prune_list = PruneList.new(event.server, days_ago.to_i, max_prunes.to_i)
        event.respond prune_list.show_count
        prune_list.prunes.each do |p|
          event.respond prune_list.confirm_warn(p)
          user_response = AwaitReply.new(event, p)
          user_response.send_warning
        end
        event.respond 'All done!'     
        return
      end
    end
  end
end