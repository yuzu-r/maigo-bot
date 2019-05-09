class Profile
	attr_reader :user, :profile
	
	def initialize(server, user_id)
		@user = server.member(user_id) || NilUser.new
		@profile = "#{@user.username}\##{@user.discriminator} (#{@user.display_name}) joined on #{@user.joined_at.strftime("%m/%d/%Y")}"
	end

	def show_profile
		@profile
	end


end

class NilUser
	attr_reader :user, :profile

	def initialize
		@profile = "User not found!"
	end

	def username
		""
	end

	#def profile
	#	"User not found!"
	#end

end

#if member
#  event << "#{member.username}\##{member.discriminator} (#{member.display_name}) joined on #{member.joined_at.strftime("%m/%d/%Y")}"
#  event << "user roles:"
#  member.roles.each do |r|
#    event <<# r.name
#    end
#end
#return
