module Bot::ModCommands
  module NoRoles
    extend Discordrb::Commands::CommandContainer
    command(:noroles, permission_level: 1) do |_event, *days_old|
      if _event.channel.id == Bot::MOD_CHANNEL_ID
        if days_old && days_old.count > 0
          joined_days_ago = days_old[0].to_i
          days_ago_text = "who joined less than #{joined_days_ago.to_s} days ago..."
        else
          joined_days_ago = nil
          days_ago_text = "(all-time list)..."
        end
		  	_event << "Polling #{_event.server.member_count} members for people who have no roles #{days_ago_text}"
        no_role_members = get_new_members_no_roles(_event, joined_days_ago).sort_by{|m| m.joined_at}
        if no_role_members.nil? || no_role_members.empty?
         _event << "Could not find new members without roles in the last #{joined_days_ago} days."
        elsif no_role_members.count > Bot::MAX_MEMBERS_RETURNED
          _event << "Too many results found; showing first #{Bot::MAX_MEMBERS_RETURNED}..."
          no_role_members.each_with_index do |m, i|
            break if i+1 > Bot::MAX_MEMBERS_RETURNED
            _event << m.display_name + ', joined on: ' + m.joined_at.strftime("%m/%d/%Y")            
          end
        else
          _event << "Found #{no_role_members.count} members with no roles defined:"
          no_role_members.each do | m |
            _event << "#{m.username}\##{m.discriminator} (#{m.display_name}) joined on #{m.joined_at.strftime("%m/%d/%Y")}"
          end
        end
        return    	
      end
    end
  end
end