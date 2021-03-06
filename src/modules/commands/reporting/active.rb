module Bot::ReportingCommands
  module Active
    extend Discordrb::Commands::CommandContainer
    command(:active, description: 'show a list of active and pending raids') do |_event|
			sort_and_pin(_event)
			return    	
    end
    active_text = <<~ACTIVE_HELP
      **Active Command**
      `#{Bot::PREFIX}active`
      This command will display the current/pending reported raids.
    ACTIVE_HELP
    Bot::CommandCategories['reporting'].push :active => active_text    
  end
end
