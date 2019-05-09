class NoReply
  def content
    'timeout'
  end
end

class AwaitReply
  attr_reader :response, :event, :prune

  def initialize(event, prune)
    @event = event
    @prune = prune
    @response = event.message.await!(timeout: 5, user: event.user) || NoReply.new
  end

  def take_action
    case response.content
    when 'yes'
      prune_reason = 'Verification process time limit exceeded.'
      event.server.kick(prune, prune_reason)
      event.respond "Goodbye to #{prune.username}."
    when 'timeout'
      event.respond 'Timeout - no action taken.'
    else
      event.respond "Reprieve for #{prune.username}, not kicked."
    end
  end

  def send_warning
    warning_text = "Hello from the El Cerrito Pokemon Go Discord group!\n"
    warning_text += "Members who remain unverified for longer than 3 months are subject to removal.  "
    warning_text += "Your account will soon be removed in accordance with this policy.\n"
    warning_text += "Please post in the <\##{Bot::UNVERIFIED_CHANNEL_ID}> channel or contact a moderator if you wish to get verified.\n"
    warning_text +=  'This is an automated message. Replies will not be seen. If you need assistance, '
    warning_text +=  "ask for help in the discord channels or contact a moderator.\n"
    warning_text += 'If at a later time you wish to rejoin, you can find us at '
    warning_text += "https://discord.gg/KBmzXJ5\n"

    case response.content
    when 'yes'
      message = @prune.pm warning_text
      if message
        event.respond "Message sent to #{prune.username}."
      else
        event.respond 'Message not sent!'
      end      
    when 'timeout'
      event.respond 'Timeout - no action taken.'
    else
      event.respond "Warning not sent to #{prune.username}."
    end
  end

end