class PruneList
  attr_reader :prunes

  def initialize(event, days_ago, max_prunes)
    @prunes = get_unverified_members(event, days_ago, max_prunes) || NilPrune.new
  end

  def show_count
    "Total prunes found: #{@prunes.count}"
  end

  def display_prunes
    list = "Oldest prunes first:\n"
    prunes.each do |p|
      list += display_prune(p) + "\n"
    end
    list
  end

  def confirm_prune(prune)
    "Do you want to kick " + display_prune(prune) + "?\n"\
    "Enter **yes** to confirm, anything else to cancel."
  end

  def confirm_warn(prune)
    "Do you want to send " + display_prune(prune) + " a warning message?\n"\
    "Enter **yes** to confirm, anything else to cancel."
  end    

  private

  def display_prune(prune)
    "#{prune.username}\##{prune.discriminator} (#{prune.display_name}), joined "\
    "#{prune.joined_at.strftime("%m/%d/%Y")} #{prune.roles.map {|r| r.name}}"
  end
end

class NilPrune 
  attr_reader :prunes

  def count
    0
  end

  def each
    # derp
  end

end