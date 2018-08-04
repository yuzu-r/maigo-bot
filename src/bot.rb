# Gems
require 'discordrb'
require 'bundler/setup'
require_relative 'lib/maigodb'
require_relative 'lib/helpers'
require 'chronic'
require 'tzinfo'
require 'rufus-scheduler'

# The main bot module.
module Bot
  # Load non-Discordrb modules
  Dir['src/modules/*.rb'].each { |mod| load mod }

  # Bot configuration
  client_id = ENV['DISCORD_CLIENT_ID']
  token = ENV['DISCORD_TOKEN']
  PREFIX = ENV['DISCORD_PREFIX']
  LOGGING = ENV['LOGGING'].to_s  
  CLEAN_INTERVAL = ENV['CLEAN_INTERVAL']

  # This structure is adapted from Gemstone: https://github.com/z64/gemstone
  # Create the bot.
  # The bot is created as a constant, so that you
  # can access the cache anywhere.
  BOT = Discordrb::Commands::CommandBot.new(client_id: client_id,
                                            token: token,
                                            prefix: PREFIX)

  Scheduler = Rufus::Scheduler.new

  # This class method wraps the module lazy-loading process of discordrb command
  # and event modules. Any module name passed to this method will have its child
  # constants iterated over and passed to `Discordrb::Commands::CommandBot#include!`
  # Any module name passed to this method *must*:
  #   - extend Discordrb::EventContainer
  #   - extend Discordrb::Commands::CommandContainer
  # @param klass [Symbol, #to_sym] the name of the module
  # @param path [String] the path underneath `src/modules/` to load files from
  def self.load_modules(klass, path)
    new_module = Module.new
    const_set(klass.to_sym, new_module)
    Dir["src/modules/#{path}/*.rb"].each { |file| load file }
    new_module.constants.each do |mod|
      BOT.include! new_module.const_get(mod)
    end
  end

  load_modules(:DiscordEvents, 'events')
  load_modules(:DiscordCommands, 'commands')

  # Run the bot
  BOT.run
end
