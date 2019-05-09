module Bot::ModCommands
  module Whois
    extend Discordrb::Commands::CommandContainer
    command(:whois,
              min_args: 1,
              usage: 'whois <userid>',
              permission_level: 1) do |event, userid|
      if event.channel.id == Bot::MOD_CHANNEL_ID
        member = Profile.new(event.server, userid)
        event.respond member.show_profile
        return
      end
    end
  end
end
