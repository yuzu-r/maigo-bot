module Bot::HelpCommands
  module Help
    extend Discordrb::Commands::CommandContainer
    command :help do |_event, command = nil|
      help_string = <<~HELP_HELP
        Type `#{Bot::PREFIX}help [command/category]` for bot help.
        Examples:
        `#{Bot::PREFIX}help` (see all available help topics)
        `#{Bot::PREFIX}help lookup`
        `#{Bot::PREFIX}help whereis`
        __Available help topics:__
      HELP_HELP

      if command.nil?
        Bot::CommandCategories.each do |category, commands|
          if commands.count > 0
            help_string += "**#{category.to_s}:**\n"
            commands.each do |command_hash|
              command_hash.each do |c, help_text|
                help_string += '  ' + c.to_s + ': ' + Bot::BOT.commands[c].attributes[:description] + "\n"
              end
            end
          end
        end
      else
        Bot::CommandCategories.each do |category, commands|
          if command.downcase == category
            help_string = Bot::CommandCategoriesHelp[category] || "No help is forthcoming for #{command}."
            _event << help_string
            return
          else
            if commands.count > 0
              commands.each do |command_hash|
                if command_hash.has_key?(command.downcase.to_sym)
                  help_string = command_hash[command.downcase.to_sym]
                  _event << help_string
                  return
                end
              end
            end            
          end
        end
        help_string += "No help is forthcoming for #{command}."
      end
      _event << help_string
    end
  end
end
