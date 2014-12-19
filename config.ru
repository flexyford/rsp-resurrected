require './server'

db = RockPaperScissors.create_db_connection 'rock_paper_scissors'
RockPaperScissors.create_tables db

run RockPaperScissors::Server
