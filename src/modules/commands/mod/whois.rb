module Bot::ModCommands
  module Whois
    extend Discordrb::Commands::CommandContainer
    command(:whois,
              min_args: 1,
              usage: 'whois <userid>',
              permission_level: 1) do |event, userid|
      if event.channel.id == Bot::MOD_CHANNEL_ID || event.channel.id == Bot::PURGE_CHANNEL_ID
        member = Trainer.new(event.server, userid)
        event.respond member.show_profile
        event.respond member.show_permissions
        return
      end
    end
  end
end
