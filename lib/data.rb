require 'sqlite3'
require 'active_record'


module TagExpressions
	

	module Data

		def self.tags()
			@@tags ||= build_data_structure
		end

		def self.reset_tags
			@@tags = nil
		end

		# run this when tags server is restarted to fetch data from DB
		def self.build_data_structure
			tags = Hash.new { |hash, key| hash[key] = []}

			TagExpressions::Data::Tag.all.each do |ar|
				tags[ar.name].push(ar.topic_id)
			end
			tags.each{|key, ids| ids.sort!{|a,b| a <=> b}.uniq!}
		end

		class Tag < ActiveRecord::Base
		 	belongs_to :topic

		 	@random_tags = ["LUE", "Heartbreaks", "Programming", "Java", "Relationships", "Current_Events", "Ruby", "Adult", "Aeroplane", "Air", "Aircraft Carrier", "Airforce", "Airport", "Album", "Alphabet", "Apple", "Arm", "Army", "Baby", "Baby", "Backpack", "Balloon", "Banana", "Bank", "Barbecue", "Bathroom", "Bathtub", "Bed", "Bed", "Bee", "Bible", "Bible", "Bird", "Bomb", "Book", "Boss", "Bottle", "Bowl", "Box", "Boy", "Brain", "Bridge", "Butterfly", "Button", "Cappuccino", "Car", "Car-race", "Carpet", "Carrot", "Cave", "Chair", "Chess Board", "Chief", "Child", "Chisel", "Chocolates", "Church", "Church", "Circle", "Circus", "Circus", "Clock", "Clown", "Coffee", "Coffee-shop", "Comet", "Compact Disc", "Compass", "Computer", "Crystal", "Cup", "Cycle", "Data Base", "Desk", "Diamond", "Dress", "Drill", "Drink", "Drum", "Dung", "Ears", "Earth", "Egg", "Electricity", "Elephant", "Eraser", "Explosive", "Eyes", "Family", "Fan", "Feather", "Festival", "Film", "Finger", "Fire", "Floodlight", "Flower", "Foot", "Fork", "Freeway", "Fruit", "Fungus", "Game", "Garden", "Gas", "Gate", "Gemstone", "Girl", "Gloves", "God", "Grapes", "Guitar", "Hammer", "Hat", "Hieroglyph", "Highway", "Horoscope", "Horse", "Hose", "Ice", "Ice-cream", "Insect", "Jet fighter", "Junk", "Kaleidoscope", "Kitchen", "Knife", "Leather jacket", "Leg", "Library", "Liquid", "Magnet", "Man", "Map", "Maze", "Meat", "Meteor", "Microscope", "Milk", "Milkshake", "Mist", "Money $$$$", "Monster", "Mosquito", "Mouth", "Nail", "Navy", "Necklace", "Needle", "Onion", "PaintBrush", "Pants", "Parachute", "Passport", "Pebble", "Pendulum", "Pepper", "Perfume", "Pillow", "Plane", "Planet", "Pocket", "Post-office", "Potato", "Printer", "Prison", "Pyramid", "Radar", "Rainbow", "Record", "Restaurant", "Rifle", "Ring", "Robot", "Rock", "Rocket", "Roof", "Room", "Rope", "Saddle", "Salt", "Sandpaper", "Sandwich", "Satellite", "School", "Sex", "Ship", "Shoes", "Shop", "Shower", "Signature", "Skeleton", "Slave", "Snail", "Software", "Solid", "Space Shuttle", "Spectrum", "Sphere", "Spice", "Spiral", "Spoon", "Sports-car", "Spot Light", "Square", "Staircase", "Star", "Stomach", "Sun", "Sunglasses", "Surveyor", "Swimming Pool", "Sword", "Table", "Tapestry", "Teeth", "Telescope", "Television", "Tennis racquet", "Thermometer", "Tiger", "Toilet", "Tongue", "Torch", "Torpedo", "Train", "Treadmill", "Triangle", "Tunnel", "Typewriter", "Umbrella", "Vacuum", "Vampire", "Videotape", "Vulture", "Water", "Weapon", "Web", "Wheelchair", "Window", "Woman", "Worm", "X-ray"]
		 	def self.add(num)
		 		(0...num).each do
		 			name = @random_tags[rand(@random_tags.length - 1)]
		 			id = rand(100) + 1
		 			Tag.create({:name => name, :topic_id => id}).save
		 		end
		 	end

		end

		class Topic < ActiveRecord::Base

			has_many :tags
			def self.add(num)
				(0...num).each do
					Topic.create().save
				end
			end

			# enter tags comma separated 
			def self.create_with_tags(tags)
				topic = Topic.create()
				topic.save

				tags.split(",").each do |tag|
					Tag.create({:name => tag.strip, :topic_id => topic.id}).save
				end
				return topic
			end
		end

		module DB
			SQLITE_PATH = File.expand_path('../db/sqlite.db', File.dirname(__FILE__))

			def self.sqlite_path
				@@sqlite_path ||= SQLITE_PATH
			end

			def self.sqlite_path=(sqlite_path)
				@@sqlite_path ||= sqlite_path

			end


			

			def self.connect_db
				ActiveRecord::Base.establish_connection(
				:adapter => 'sqlite3',
				:database => sqlite_path
				)
			end

			def self.db
				@@db ||= SQLite3::Database.new sqlite_path

			end

			def self.setup
				build_tags_table
				build_topics_table
			end

			def self.clear_tables
				db.execute("DROP TABLE tags") do |sql|
					puts "TAGS DROPPED"
				end

				db.execute("DROP TABLE TOPICS") do |sql|
					puts "TOPICS DROPPED"
				end
			end

			def self.build_tags_table
				db.execute <<-SQL
				  CREATE TABLE IF NOT EXISTS tags (
				    name VARCHAR(255),
				    topic_id INT
				  );
				SQL
			end

			def self.build_topics_table
				db.execute <<-SQL
				  CREATE TABLE IF NOT EXISTS topics (
				    title VARCHAR(255),
				    message TEXT
				  );
				SQL
			end
		end
	end
end
