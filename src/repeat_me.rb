require 'faraday'
require 'json'

# usage: heroku run ruby repeat_me content-to-post webhook-to-use

content = ARGV[0] || ENV['TASK_GIF_URL']
url = ARGV[1] || ENV['TASK_WEBHOOK']

puts "posting content: #{content}"

resp = Faraday.post(url) do |req|
	req.headers['Content-Type'] = 'application/json'
	req.body = {content: content, username: 'maigo-helper'}.to_json
end
