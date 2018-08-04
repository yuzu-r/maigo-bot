require_relative '../lib/maigodb'

class Train
	attr_accessor :route, :conductor, :show_boss

	def initialize
		# route is an array of _id from registered raids/eggs
		@route = []
		@conductor = nil
		@show_boss = false
	end

	def show
		if @route.count == 0
			return "Nowhere. Aw."
		else
			raid_string = ""
			@route.each_with_index do |r, i|
				raid = get_raid(r)
				first_mark = i == 0 ? '**' : ''
				next_mark = i == @route.count - 1 ? '' :  "\n   >> "
				raid_boss = @show_boss && raid['boss'] ? '(' + raid['boss'] + ') ' : ''
				raid_string += first_mark + raid['gym'] + ' (' + raid['despawn_time'].strftime("%-I:%M") + ')' + ' ' + raid_boss + first_mark + next_mark
			end
			return raid_string
		end
	end

	def count
		return @route.count
	end

	def list
		if @route.count == 0
			return 'There are no stops on the route. Add some!'
		else
			list = ""
			@route.each_with_index do |r, i|
				raid = get_raid(r)
				numbering = (i+1).to_s + ') '
				raid_boss = raid['boss'] ? '(' + raid['boss'] + ') ' : ''
				despawn_time = '(' + raid['despawn_time'].strftime("%-I:%M") + ')'
				list += numbering + raid['gym'] + ' ' + raid_boss + despawn_time + "\n"
			end
			return list
		end
	end

	def skip(route_index)
		# reminder: route_index starts at 1
		if @route.count > 0 && route_index <= @route.count && route_index > 0
			@route.delete_at(route_index - 1)
			return "Skipping a stop... the route is now #{self.show}."
		else
			return "Could not find that stop to skip."
		end
	end

	def set(raid_index, raids)
		raid_array = raid_index.split(',').map{ |i| i.to_i }
		# raid index starts at 1, raids starts at 0
		raid_array.each do |r_index|
			if r_index > raids.count
				next
			end
			raid = raids[r_index-1]['_id']
			# ignore the raid if it already in the route
			if !@route.include?(raid)
				@route.push raid
			end
		end
		return "The route is now #{self.show}."
	end

	def stop
		@route = []
		return "The route has been destroyed. Use `set` to define a new route."
	end

	def first
		if @route.first
			raid = get_raid(@route.first)
			return raid
		else
			return nil
		end
	end

	def next
		if @route
			@route.shift
			return self.show
		else
			return nil
		end
	end

	def insert(insert_before, raid_id)
		if insert_before > @route.count
			# assume user wants to stick it at the end
			@route.push raid_id
		else
			# insert_before is 1-based, not 0-based
			@route.insert(insert_before-1, raid_id)
		end
		return self.show
	end

	def toggle_boss
		@show_boss = !@show_boss
		return @show_boss
	end
end