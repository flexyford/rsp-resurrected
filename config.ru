require './server'

db = RockPaperScissors.create_db_connection 'blogtastic'
RockPaperScissors.create_tables db

run RockPaperScissors::Server
