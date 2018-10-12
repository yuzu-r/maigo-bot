# Gems
require 'discordrb'
require 'bundler/setup'
require_relative 'lib/maigodb'
require_relative 'lib/helpers'
require_relative 'classes/train'
require 'chronic'
require 'tzinfo'
require 'rufus-scheduler'

# The main bot module.
module Bot
  # Bot configuration
  client_id = ENV['DISCORD_CLIENT_ID']
  token = ENV['DISCORD_TOKEN']
  PREFIX = ENV['DISCORD_PREFIX']
  LOGGING = ENV['LOGGING'].to_s
  MOD_ROLE_ID = ENV['MOD_ROLE_ID'].to_i || nil
  MOD_CHANNEL_ID = ENV['MOD_CHANNEL_ID'].to_i || nil
  MAX_MEMBERS_RETURNED = ENV['MAX_MEMBERS_RETURNED'].to_i || 100
  CLEAN_INTERVAL = ENV['CLEAN_INTERVAL']
  EGG_DURATION = ENV['EGG_DURATION'].to_i
  RAID_DURATION = ENV['RAID_DURATION'].to_i
  WHEREIS_ACTIVE = ENV['WHEREIS_ACTIVE'] || nil
  REPORTING_ACTIVE = ENV['REPORTING_ACTIVE'] || nil
  TRAIN_ACTIVE = ENV['TRAIN_ACTIVE'] || nil
  ENV = ENV['ENV'] || nil

  Scheduler = Rufus::Scheduler.new
  Trains = Hash.new
  CommandCategories = Hash.new
  CommandCategoriesHelp = Hash.new
  LastMessage = Hash.new
  DeleteRaidMessageQueue = Hash.new
  DeleteEggMessageQueue = Hash.new

  # Load non-Discordrb modules
  Dir['src/modules/*.rb'].each { |mod| load mod }

  # This structure is adapted from Gemstone: https://github.com/z64/gemstone
  # Create the bot.
  # The bot is created as a constant, so that you
  # can access the cache anywhere.
  BOT = Discordrb::Commands::CommandBot.new(client_id: client_id,
                                            token: token,
                                            prefix: PREFIX)

  # This class method wraps the module lazy-loading process of discordrb command
  # and event modules. Any module name passed to this method will have its child
  # constants iterated over and passed to `Discordrb::Commands::CommandBot#include!`
  # Any module name passed to this method *must*:
  #   - extend Discordrb::EventContainer
  #   - extend Discordrb::Commands::CommandContainer
  # @param klass [Symbol, #to_sym] the name of the module
  # @param path [String] the path underneath `src/modules/` to load files from

  def self.load_modules(klass,path)
    new_module = Module.new
    const_set(klass.to_sym, new_module)
    Dir["src/modules/#{path}/*.rb"].each { |file| load file }
    new_module.constants.each do |mod|
      BOT.include! new_module.const_get(mod)
    end
  end

#  load_modules(:DiscordEvents, 'events')
#  load_modules(:DiscordCommands, 'commands')

  if WHEREIS_ACTIVE && WHEREIS_ACTIVE == 'true'
    load_modules(:WhereisCommands, 'commands/whereis')
  else
    CommandCategoriesHelp.delete('lookup')
  end
  if REPORTING_ACTIVE && REPORTING_ACTIVE == 'true'
    load_modules(:ReportingEvents, 'events/reporting')
    load_modules(:ReportingCommands, 'commands/reporting')
  else
    CommandCategoriesHelp.delete('reporting')
  end
  if TRAIN_ACTIVE && TRAIN_ACTIVE == 'true'
    load_modules(:TrainCommands, 'commands/train')
  else
    CommandCategoriesHelp.delete('train')
  end

  if MOD_ROLE_ID
    BOT.set_role_permission(MOD_ROLE_ID,1)
    load_modules(:ModCommands, 'commands/mod')
  end
  
  load_modules(:MiscCommands, 'commands/misc')
  load_modules(:HelpCommands, 'commands/help')
  

  # Run the bot
  #p CommandCategories
  BOT.run
end
