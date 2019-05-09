def get_new_members_no_roles(event, days_ago=nil)
  no_role_members = []
  # the join date is in local time
  # if you pass in 2 days ago, you want to retrieve members who joined in the past 2 days
  # if no days_ago, you want all members who have no roles
  if days_ago
    join_cutoff = Time.now - days_ago * 24 * 60 * 60 
  end
  event.server.members.each do | member |
    if !days_ago && member.roles.empty?
      no_role_members.push member
    elsif days_ago
      if member.joined_at > join_cutoff && member.roles.empty?
        no_role_members.push member
      end
    end
  end 
  return no_role_members
end

def get_new_members(event, days_ago)
  new_members = []
  join_cutoff = Time.now - days_ago * 24 * 60 * 60

  event.server.members.each do |member|
    if member.joined_at > join_cutoff
      new_members.push member
    end   
  end
  return new_members
end

def get_unverified_members(server, days_ago, max_returned)
  unverified_members = []
  join_cutoff = Time.now - days_ago * 24 * 60 * 60

  role = get_role_from_name(server, 'unverified')
  return nil if role.nil? 
  role.members.each do |member|
    if member.joined_at < join_cutoff
      unverified_members.push member
    end
  end
  unverified_members.sort_by{|n| n.joined_at}.first(max_returned)
end

def get_role_from_name(server, role_name)
  role = server.roles.detect {|r| r.name == role_name}
end
