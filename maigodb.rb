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
	collection = CLIENT[:gyms]

	documents = collection.find(
		{ 'is_ex_eligible': true },
	)
	return documents
end

def register_egg(gym, hatch_time, despawn_time, tier, reported_by)
	collection = CLIENT[:raid_reports]

	egg = { gym: gym, hatch_time: hatch_time, despawn_time: despawn_time, tier: tier, reported_by: reported_by }
	response = collection.insert_one(egg)
	return response
end

def find_active_raids
	collection = CLIENT[:raid_reports]

	tz = TZInfo::Timezone.get('America/Los_Angeles')
	puts "server time is: #{Time.now}"
	local_server_time = tz.utc_to_local(Time.now)	
	puts "local server time: #{local_server_time}"

	active_raids = collection.find(
		{ 'despawn_time': {'$gt' => local_server_time} }
	).sort({ 'despawn_time': 1 }).to_a
	return active_raids
end

def register_raid(gym, despawn_time, boss, reported_by)
	collection = CLIENT[:raid_reports]
	raid = { gym: gym, despawn_time: despawn_time, boss: boss, reported_by: reported_by }
	response = collection.insert_one(raid)
	return response
end