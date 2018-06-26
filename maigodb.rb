require 'mongo'

Mongo::Logger.logger.level = Logger::INFO

def lookup(gym)
	client = Mongo::Client.new(ENV['MONGO_URI'])

	db = client.database
	collection = client[:gyms]
	exact_string =  '"' + gym + '"'
	documents = collection.find(
		{ '$text': { '$search': exact_string } },
	)

	if documents.count > 1
		msg = "Multiple matches found. Did you mean one of these? "
		multiples = []
		documents.each_with_index do |doc, index|
			multiples.push(doc['name'])
			if index > 9
				msg = "10+ matches found. Returning the first 10 suggestions: "
				break
			end
		end
		return msg + multiples.join(', ')
	elsif documents.count == 1
		return documents.first
	else
		return "I don't know where that is."
	end
end

def ex_gym_lookup
	client = Mongo::Client.new(ENV['MONGO_URI'])

	db = client.database
	collection = client[:gyms]
	documents = collection.find(
		{ 'is_ex_eligible': true },
	)
	return documents
end
