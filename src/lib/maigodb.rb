require 'mongo'

Mongo::Logger.logger.level = Logger::INFO
puts "connecting to database: #{ENV['DB_CONNECTION']}"
CLIENT = Mongo::Client.new(ENV['DB_CONNECTION'])

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
	).sort({ 'name': 1 })
	return documents
end

def is_ex?(gym)
	collection = CLIENT[:gyms]
	exact_string =  '"' + gym + '"'
	documents = collection.find({ '$text': { '$search': exact_string } })

	return documents.count == 1 && documents.first['is_ex_eligible'] == true
end

def log(server_id, user_id, command, params, is_success)
	collection = CLIENT[:logs]
	entry = { server_id: server_id.to_s, user_id: user_id.to_s, command: command, params: params, is_success: is_success, insert_date: Time.now }
	response = collection.insert_one(entry)
	return response	
end

def register_egg(gym, hatch_time, despawn_time, tier, reported_by, server_id, user_id)
	collection = CLIENT[:raid_reports]
	egg = { gym: gym, hatch_time: hatch_time, despawn_time: despawn_time, tier: tier, reported_by: reported_by, server_id: server_id.to_s, user_id: user_id }
	response = collection.insert_one(egg)
	return response
end

def find_active_raids(server_id)
	# raid and eggs
	# don't return if is_visible is false
	collection = CLIENT[:raid_reports]

	active_raids = collection.find(
		{ 'server_id': server_id,
			'despawn_time': {'$gt' => Time.now},
			'is_visible': {'$ne' => false }
		}
	).sort({ 'despawn_time': 1 }).to_a
	return active_raids
end

def find_active_eggs(server_id)
	# eggs only
	collection = CLIENT[:raid_reports]	
	active_eggs = collection.find(
			{
				'server_id': server_id,
				'despawn_time': {'$gt' => Time.now},
				'tier': {'$ne' => nil},
				'is_visible': {'$ne' => false}
			}
		).sort({'despawn_time': 1}).to_a
	return active_eggs
end

def register_raid(gym, despawn_time, boss, reported_by, server_id, user_id)
	collection = CLIENT[:raid_reports]
	raid = { gym: gym, despawn_time: despawn_time, boss: boss, reported_by: reported_by, server_id: server_id.to_s, user_id: user_id }
	response = collection.insert_one(raid)
	return response
end

def egg_to_raid(server_id, user_id, reported_by, egg_id, boss)
	collection = CLIENT[:raid_reports]
	egg = collection.find({"_id" => egg_id}).limit(1).first
	return false if !egg
	raid = {gym: egg['gym'], 
					despawn_time: egg['despawn_time'],
					boss: boss, 
					reported_by: reported_by,
					server_id: server_id.to_s,
					user_id: user_id}
	response = collection.insert_one(raid)
	if response
		egg_response = make_invisible(egg_id)
	end
	return egg_response 
end

def get_reporters(server_id)
	collection = CLIENT[:raid_reports]

	response = collection.aggregate([
								{'$match' => {'server_id' => server_id}},
								{'$group' => {'_id' => "$user_id", 'total' => {'$sum' => 1}}},
								{'$sort' => {total: -1}},
								{'$limit' => 10}
							])
	return response
end

def make_invisible(egg_id)
	collection = CLIENT[:raid_reports]
	#updateOne({filter that identifies the document to be updated},{$set:{year: 1999}})
	response = collection.update_one(
		{'_id' => egg_id},
		{'$set' => {'is_visible': false}}
	)
	puts response
	return response
end

def get_weeks_reporters(server_id, start_date_utc)
	collection = CLIENT[:raid_reports]

	starting_object_id = BSON::ObjectId.from_time(start_date_utc)
	response = collection.aggregate([
								{'$match' => {
									'server_id' => server_id,
									'_id' => {'$gte' => starting_object_id}}
								},
								{'$group' => {'_id' => "$user_id", 'total' => {'$sum' => 1}}},
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

	t = Time.now
	interval = 15 * 60 # every 15 mins, schedule another raid/egg

	server_id = server.id.to_s

	gym_set = gyms.aggregate([ { '$sample' => { size: 7 } } ])
	gym_set.each_with_index do |gym, i|
		hatch_time = t + interval * i
		despawn_time = hatch_time + Bot::RAID_DURATION*60
		gym_name = !gym['aliases'].nil? && !gym['aliases'].empty? ? gym['aliases'][0] : gym['name']
		if rand(2) == 0
			egg = { gym: gym_name, 
							hatch_time: hatch_time, 
							despawn_time: despawn_time, 
							tier: rand(5) + 1, 
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
