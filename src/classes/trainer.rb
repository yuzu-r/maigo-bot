class Trainer
	attr_reader :user

	def initialize(server, user_id)
		@user = server.member(user_id) || NilTrainer.new
	end

	def show_profile
		"#{@user.username}\##{@user.discriminator} (#{@user.display_name}) joined on #{@user.joined_at.strftime("%m/%d/%Y")}"
	end

	def show_permissions
		<<~HEREDOC
			Permissions:
			Can send messages? #{@user.permission?(:send_messages)}
			Can kick users? #{@user.permission?(:kick_members)}
		HEREDOC
	end

end

class NilTrainer

	def username
		'Userid not found'
	end

	def discriminator
		'???'
	end

	def display_name
		'n/a'
	end

	def joined_at
		Time.now
	end

	def permission?(permission)
		'n/a'
	end

end
