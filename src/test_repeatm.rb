require 'faraday'
require 'json'

url = ENV['TASK_WEBHOOK']
content = ENV['TASK_GIF_URL']

resp = Faraday.post(url) do |req|
	req.headers['Content-Type'] = 'application/json'
	req.body = {content: content, username: 'maigo-helper'}.to_json
end

