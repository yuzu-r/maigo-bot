module Bot::StaticText
  module HelpText
    # define command categories and text in hash here
    # remove from hash if the command isn't loaded by the bot
    Bot::CommandCategories['lookup'] = []
    Bot::CommandCategories['reporting'] = []
    Bot::CommandCategories['train'] = []
    Bot::CommandCategories['misc'] = []
    Bot::CommandCategories['help'] = []

    lookup_text = <<~LOOKUP_HELP
      **Gym Lookup Commands**
      Use `#{Bot::PREFIX}whereis` to locate gyms local to El Cerrito/Albany.
      Use `#{Bot::PREFIX}exgyms` to locate confirmed ex raid locations in the El Cerrito-Albany area.
      Some nearby gyms from Berkeley/Kensington/Richmond are included but this bot does not provide a comprehensive list for these cities.
      The bot does not provide pokestop lookups.
    LOOKUP_HELP

    Bot::CommandCategoriesHelp['lookup'] = lookup_text

    reporting_text = <<~REPORTING_HELP
      **Raid/Egg Reporting**
      Use `#{Bot::PREFIX}active` for a list of active and pending raids, sorted by despawn time.
      Use `#{Bot::PREFIX}egg` to report an egg.
      Use `#{Bot::PREFIX}raid` to report an active raid.
      Use `#{Bot::PREFIX}hatch` to update a reported egg after hatch.
      Use `#{Bot::PREFIX}rm` to remove a mis-reported egg or raid.
      Use `#{Bot::PREFIX}leaderboard` to view a list of raid/egg reporters.
      Active eggs and raids are pinned in the raids channel.
      Expired eggs/raids are cleared out every 15 minutes.
    REPORTING_HELP

    Bot::CommandCategoriesHelp['reporting'] = reporting_text

    train_text = "**Raid Train Routing**"
    Bot::CommandCategoriesHelp['train'] = train_text

    help_text = <<~HELP_HELP
      Type `#{Bot::PREFIX}help [command/category]` for help.
      Type `#{Bot::PREFIX}help` for a list of available categories and commands.
    HELP_HELP

    Bot::CommandCategoriesHelp['help'] = help_text    
  end
end