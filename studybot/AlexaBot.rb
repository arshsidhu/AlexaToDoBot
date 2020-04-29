require 'discordrb'
require 'json'
require 'mongo'

envfile = File.open "environment.json"
dbfile = File.open "db.json"
env = JSON.load(envfile)
envfile.close

Mongo::Logger.logger.level = Logger::FATAL #remove to see all debug level mongodb logs

client = Mongo::Client.new("mongodb+srv://#{env["DBUSER"]}:#{env["DBPASS"]}@cluster0-hbjvs.mongodb.net/test?retryWrites=true&w=majority", :database => "ToDo")
TASKS = client[:Tasks]

bot = Discordrb::Commands::CommandBot.new token: env["TOKEN"], client_id: env['CLIENTID'], prefix: '!'

bot.message(with_text: "Ping!") do |event|
    event.respond "Pong!"
end

bot.command :random do |event, min, max|
    rand(min.to_i .. max.to_i)
end

bot.command :testdb do |event|
    TASKS.find.each do |document|
        event.respond JSON.pretty_generate(document)
    end
end

bot.run