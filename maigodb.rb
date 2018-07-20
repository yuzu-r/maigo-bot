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

def register_egg(gym, hatch_time, despawn_time, tier, reported_by, server_id)
	collection = CLIENT[:raid_reports]

	egg = { gym: gym, hatch_time: hatch_time, despawn_time: despawn_time, tier: tier, reported_by: reported_by, server_id: server_id.to_s }
	response = collection.insert_one(egg)
	return response
end

def find_active_raids(server_id)
	collection = CLIENT[:raid_reports]

	tz = TZInfo::Timezone.get('America/Los_Angeles')
	puts "server time is: #{Time.now}"
	local_server_time = tz.utc_to_local(Time.now)	
	puts "local server time: #{local_server_time}"

	active_raids = collection.find(
		{ 'server_id': server_id,
			'despawn_time': {'$gt' => local_server_time} }
	).sort({ 'despawn_time': 1 }).to_a
	return active_raids
end

def register_raid(gym, despawn_time, boss, reported_by, server_id)
	collection = CLIENT[:raid_reports]
	raid = { gym: gym, despawn_time: despawn_time, boss: boss, reported_by: reported_by, server_id: server_id.to_s }
	response = collection.insert_one(raid)
	return response
end

def get_reporters(server_id)
	collection = CLIENT[:raid_reports]

	response = collection.aggregate([
								{'$match' => {'server_id' => server_id}},
								{'$group' => {'_id' => "$reported_by", 'total' => {'$sum' => 1}}},
								{'$sort' => {total: -1}},
								{'$limit' => 10}
							])
	return response
end

def delete_raid(raid_id)
	collection = CLIENT[:raid_reports]

	response = collection.delete_one({'_id' => raid_id})
end

def get_raid(raid_id)
	collection = CLIENT[:raid_reports]

	collection.find({'_id' => raid_id}).limit(1).first
end

def insert_test(server)
	gyms = CLIENT[:gyms]
	raid_reports = CLIENT[:raid_reports]

	tz = TZInfo::Timezone.get('America/Los_Angeles')
	t = Time.now
	interval = 15 * 60 # every 15 mins, schedule another raid/egg

	server_id = server.id.to_s

	gym_set = gyms.aggregate([ { '$sample' => { size: 7 } } ])
	gym_set.each_with_index do |gym, i|
		hatch_time = tz.utc_to_local(t + interval * i)
		despawn_time = hatch_time + 45*60
		gym_name = !gym['aliases'].nil? && !gym['aliases'].empty? ? gym['aliases'][0] : gym['name']
		if rand(2) == 0
			egg = { gym: gym_name, 
							hatch_time: hatch_time, 
							despawn_time: despawn_time, 
							tier: 5, 
							reported_by: 'test', 
							server_id: server_id }
			response = raid_reports.insert_one(egg)
			puts "inserting egg: #{response}"
		else
			if rand(2) == 0
				boss = 'Lugia'
			else
				boss = 'Regice'
			end
			raid = { gym: gym_name, 
							 despawn_time: despawn_time, 
							 boss: boss, 
							 reported_by: 'test', 
							 server_id: server_id }
			response = raid_reports.insert_one(raid)
			puts "inserting raid: #{response}"
		end
	end
end
