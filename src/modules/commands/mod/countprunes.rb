module Bot::ModCommands
  module CountPrunes
    extend Discordrb::Commands::CommandContainer
    command(:countprunes,
              min_args: 1,
              usage: 'countprunes <days ago> <max>',
              permission_level: 1) do |event, days_ago, max_prunes = 10|
      if event.channel.id == Bot::MOD_CHANNEL_ID || event.channel.id == Bot:: PURGE_CHANNEL_ID
        # event.respond much faster than event << ?
        # event << "Looking for unverified members who joined over #{days_ago} days ago..."
        event.respond "Looking for unverified members who joined over #{days_ago} days ago..."
        prune_list = PruneList.new(event.server, days_ago.to_i, max_prunes.to_i)
        event.respond prune_list.show_count
        event.respond prune_list.display_prunes
        return
      end
    end
  end
end
