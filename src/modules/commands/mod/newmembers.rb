module Bot::ModCommands
	module NewMembers
		extend Discordrb::Commands::CommandContainer
		command(:newmembers, permission_level: 1) do |_event, *days_back|
			if _event.channel.id == Bot::MOD_CHANNEL_ID
				if days_back && days_back.count > 0
					days_ago = days_back[0].to_i
				else
					days_ago = 7
				end
				_event << "Looking for members who joined in the last #{days_ago} days..."
				new_members = get_new_members(_event, days_ago).sort_by{|n| n.joined_at}
				if new_members.count == 0
					_event << "No one joined in that time period!"
        elsif new_members.count > Bot::MAX_MEMBERS_RETURNED
          _event << "Too many results found; showing first #{Bot::MAX_MEMBERS_RETURNED}..."
          new_members.each_with_index do |n, i|
            break if i+1 > Bot::MAX_MEMBERS_RETURNED
            _event << "#{n.username}\##{n.discriminator} (#{n.display_name}) joined on #{n.joined_at.strftime("%m/%d/%Y")}"
          end
				else					
					new_members.each do |n|
						_event << "#{n.username}\##{n.discriminator} (#{n.display_name}) joined on #{n.joined_at.strftime("%m/%d/%Y")}"
					end
				end
				return
			end
		end
	end
end
