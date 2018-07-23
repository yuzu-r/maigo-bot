def log_command(_event, command, is_success, fallback_msg, param = nil)
	return if !Bot::LOGGING || Bot::LOGGING == 'false'
	response = log(_event.server.id, _event.user.id, command, param, is_success)
	if !response || response.n != 1
		puts fallback_msg
	end
	return
end
