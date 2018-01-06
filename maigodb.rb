require 'mongo'
require 'chronic'

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
		puts "unsuccessful lookup for #{gym}"
		return "I don't know where that is."
	end
end

def raid_report(gym, boss, time)
	return false if !gym || !boss
	client = Mongo::Client.new(ENV['MONGO_URI'])
	db = client.database
	raids = client[:raids]
	raid_bosses = client[:raid_bosses]
	gym_aliases = {'long' => 'Long Song Sculpture', 
							'vets' => 'Veterans Memorial Hall (Albany)', 
							'frog' => 'Frog Habitat',
							'sprint' => 'Sprint Store'}
	gyms = client[:gyms]
	raid_gym = gyms.find({'name': gym_aliases[gym]}).first
	if !raid_gym 
		return false
	end
	raid_boss_collection = raid_bosses.find({'name': boss.downcase})
	if raid_boss_collection.count == 1
		raid_boss = raid_boss_collection.first
		time_string = time.length > 0 ? time.join(' ') : nil
		if time_string
			parsed_time = Chronic.parse(time_string)
		else
			parsed_time = Chronic.parse('this second')
		end
		raid_info = {gym: raid_gym['_id'], boss: raid_boss['_id'], start_time: parsed_time}
		result = raids.insert_one(raid_info)
		if result.n == 1
			return true
		else
			return false
		end
	else
		return false
	end
end
