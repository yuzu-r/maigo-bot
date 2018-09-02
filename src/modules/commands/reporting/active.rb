module Bot::ReportingCommands
  module Active
    extend Discordrb::Commands::CommandContainer
    command(:active, description: 'show a list of active and pending raids') do |_event|
			sort_and_pin(_event)
			return    	
    end
    active_text = "\n**Active Command**"
    active_text += "\n`#{Bot::PREFIX}active`"
  	active_text += "\nThis command will display the current/pending reported raids."
    Bot::CommandCategories['reporting'].push :active => active_text    
  end
end
