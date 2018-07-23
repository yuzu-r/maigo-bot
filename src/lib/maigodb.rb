require 'mongo'

Mongo::Logger.logger.level = Logger::INFO
CLIENT = Mongo::Client.new(ENV['MONGO_URI'])

def lookup(gym)
	collection = CLIENT[:gyms]
	exact_string =  '"' + gym + '"'
	documents = collection.find(
		{ '$text': { '$search': exact_string } },
	)

	if documents.count > 1
		msg = "**Multiple matches found. Did you mean one of these?**\n"
		multiples = []
		documents.each_with_index do |doc, index|
			multiples.push(doc['name'])
			if index >= 9
				msg = "**10+ matches found. Returning the first 10 suggestions:**\n"
				break
			end
		end
		return msg + multiples.join("\n")
	elsif documents.count == 1
		return documents.first
	else
		return "I don't know where that is."
	end
end

def ex_gym_lookup
	collection = CLIENT[:gyms]
	documents = collection.find(
		{ 'is_ex_eligible': true },
	)
	return documents
end

def log(server_id, user_id, command, params, is_success)
	collection = CLIENT[:logs]
	entry = { server_id: server_id.to_s, user_id: user_id.to_s, command: command, params: params, is_success: is_success, insert_date: Time.now }
	response = collection.insert_one(entry)
	return response	
end