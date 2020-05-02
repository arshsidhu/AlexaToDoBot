require 'base64'
require 'bson'
require 'date'
require 'discordrb'
require 'json'
require 'mongo'
require 'table_print'
require 'rufus-scheduler'

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
TAGS = ["School", "Work", "Misc", "All"]
scheduler = Rufus::Scheduler.new

bot = Discordrb::Commands::CommandBot.new token: env["TOKEN"], client_id: env['CLIENTID'], prefix: '!'

bot.message(with_text: "Ping!") do |event|
    event.respond "Pong!"
end

bot.command(:test, description: "Used to debug.") do |event|
    TASKS.find.each do |doc|
        event.respond JSON.pretty_generate(doc)
    end
    return
end

# Add's tasks to the DB.
# Params
# Tag = School, work or misc.
# Date = Due date of assignment in dd/mm/yyyy.
# Description = Assignment description.
bot.command(:addtask, description: "Add a task to your ToDo list.") do |event, tag, date, *description|

    unless TAGS.include? tag 
        event.respond "Improper tag"
        return
    end

    begin
        datetime = DateTime.strptime(date, "%d/%m/%Y")
    rescue ArgumentError
        event.respond "Improper date (dd/mm/YYYY)"
        return
    end

    desc = description.join(" ")

    if desc.length > 255
        event.respond "Description too long"
    end

    user = event.user.name
    num = TASKS.find({'user':user}).count
    id = TASKS.find.count
    
    doc['_id'] = BSON::ObjectId.new
    doc['num'] = num+1
    doc['user'] = user
    doc['tag'] = tag
    doc['date'] = datetime
    doc['description'] = desc

    TASKS.insert_one(doc)

    return "Insert Successful"
end

# Display the tasks based on username.
# Params
# Tag = ToDo task tag, leave blank to display all tasks.
bot.command(:display, description: "Display your tasks.") do |event, tag = "All"|
    
    unless TAGS.include? tag
        event.respond "Improper tag"
        return
    end

    output = generate_todo(tag, event.user.name)
    return output
    
end

# Generate a string to represent your ToDo list
# Params 
# Tag = task tag
def generate_todo(tag, user)
    if tag == "All"
        items = TASKS.find({'user':user})
    else
        items = TASKS.find({'user':user, 'tag':tag})    
    end

    # figure out how to properly print this later
    # tp items, :num, :tag, :date, :description

    output_str = "```TODO LIST\n- - - - - - - - - - - - - - -\n"
    items.each do |doc|
        output_str << task_to_s(doc) << "- - - - - - - - - - - - - - -\n"
    end
    output_str << "```"

    return output_str
end


# Mark task as finsihed and delete from database
# Params
# num - task number
bot.command(:complete, description: "Mark tasks as complete by number.") do |event, num|

    doc = TASKS.find({'user':event.user.name, 'num':num.to_i}).limit(1).first
    
    unless doc.nil?
        TASKS.delete_one(doc)
        TASKS.update_many({'num': {'$gt': num.to_i}}, {'$inc': {'num':-1}})
        return "Congrats, task complete!"
    else
        return "Task num not found"
    end
end

# Method to change a TASK json to a str
# Params
# task = task json
def task_to_s(task)
    return "num:#{task['num']}\ntag:#{task['tag']}\ndue date:#{task['date'].to_s}\ndescription:#{task['description']}\n"
end

# CRON task to remind user of tasks
# Set for 10AM every day
scheduler.cron '00 10 * * *' do
    # Make this generic later on
    output = generate_todo("All", "Arsh")
    bot.send_message(683790662885572851, output)
end

bot.run