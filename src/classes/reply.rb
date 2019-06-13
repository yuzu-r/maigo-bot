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
      begin
        prune_reason = 'Verification process time limit exceeded.'
        event.server.kick(prune, prune_reason)
      rescue Discordrb::Errors::NoPermission => err
        event.respond "Error during kick: #{err.message} "
      else
        event.respond "Goodbye to #{prune.username}."
      end
    when 'timeout'
      event.respond 'Timeout - no action taken.'
    else
      event.respond "Reprieve for #{prune.username}, not kicked."
    end
  end

  def send_warning
    warning_text = 
    <<~HEREDOC
      Hello from the El Cerrito Pokemon Go Discord group!
      Members who remain unverified for longer than 3 months are subject to removal.
      Your account will soon be removed in accordance with this policy.
      Please post in the <\##{Bot::UNVERIFIED_CHANNEL_ID}> channel or contact a moderator if you wish to get verified.
      The moderators are listed in <\##{Bot::POLICY_CHANNEL_ID}>.
      This is an automated message. Replies will not be seen. If you need assistance, ask for help in the discord channels or contact a moderator.
      If at a later time you wish to rejoin, you can find us at https://discord.gg/KBmzXJ5.
    HEREDOC
    
    case response.content
    when 'yes'
      begin
        event.respond 'sending message...'
        @prune.pm warning_text
      rescue Discordrb::Errors::NoPermission => err
        event.respond "Message not sent: #{err.message} "
      else
        event.respond "Message sent to #{prune.username}."
      end
    when 'timeout'
      event.respond 'Timeout - no action taken.'
    else
      event.respond "Warning not sent to #{prune.username}."
    end
  end

end
