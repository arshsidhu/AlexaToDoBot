require 'date'
require 'discordrb'
require 'json'
require 'mongo'

# Managing jsons
envfile = File.open "environment.json"
dbfile = File.open "db.json"
env = JSON.load(envfile)
doc = JSON.load(dbfile)
envfile.close
dbfile.close

# Remove to see all debug level mongodb logs
Mongo::Logger.logger.level = Logger::FATAL 

# Connecting to db
client = Mongo::Client.new("mongodb+srv://#{env["DBUSER"]}:#{env["DBPASS"]}@cluster0-hbjvs.mongodb.net/test?retryWrites=true&w=majority", :database => "ToDo")

# Globals
TASKS = client[:Tasks]
TAGS = ["School", "Work", "Misc"]

bot = Discordrb::Commands::CommandBot.new token: env["TOKEN"], client_id: env['CLIENTID'], prefix: '!'

bot.message(with_text: "Ping!") do |event|
    event.respond "Pong!"
end

bot.command(:test, description: "Used to debug.") do |event|
    TASKS.find().each do |doc|
        event.respond JSON.pretty_generate(doc)
    end
end

# Add's tasks to the DB
# Params
# Tag = School, work or misc
# Date = Due date of assignment
# Description = Assignment description
bot.command(:addtask, description: "Add a task to your ToDo list.") do |event, tag, date, *description|
    user = event.user.name
    num = TASKS.find({'user':user}).count
    id = TASKS.find.count
    datetime = DateTime.strptime(date, "%d/%m/%Y")
    
    doc['_id'] = id+1
    doc['num'] = num+1
    doc['user'] = user
    doc['tag'] = tag
    doc['date'] = datetime
    doc['description'] = description.join(" ")

    TASKS.insert_one(doc)
end

bot.run