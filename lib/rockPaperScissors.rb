require 'pg'
require_relative 'rockPaperScissors/repos/users_repo.rb'
require_relative 'rockPaperScissors/repos/matches_repo.rb'
require_relative 'rockPaperScissors/repos/rounds_repo.rb'

module RockPaperScissors

  ROCK = 'r'
  PAPER = 'p'
  SCISSORS = 's'

  def self.create_db(dbname)
    success = system("createdb #{dbname}")
  end

  def self.create_db_connection dbname
    PG.connect(host: 'localhost', dbname: dbname)
  end

  def self.clear db
    db.exec <<-SQL
      DELETE FROM rounds;
      DELETE FROM matches;
      DELETE FROM sessions;
      DELETE FROM users;    
    SQL
  end

  def self.create_tables db
    db.exec <<-SQL
      CREATE TABLE IF NOT EXISTS users(
        id SERIAL PRIMARY KEY,
        username VARCHAR,
        password VARCHAR
      );
      CREATE TABLE IF NOT EXISTS sessions(
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users (id),
        token TEXT UNIQUE
      );
      CREATE TABLE IF NOT EXISTS matches(
        id SERIAL PRIMARY KEY,
        host_id integer references users(id),
        guest_id integer references users(id),
        winner_id integer references users(id)
      );
      CREATE TABLE IF NOT EXISTS rounds(
        id SERIAL PRIMARY KEY,
        match_id integer references matches(id),
        host_choice VARCHAR,
        guest_choice VARCHAR,
        winner_id integer references users(id)
      );
    SQL
  end

  def self.drop_tables db
    db.exec <<-SQL
      DROP TABLE IF EXISTS rounds;
      DROP TABLE IF EXISTS matches;
      DROP TABLE IF EXISTS sessions;
      DROP TABLE IF EXISTS users;
    SQL
  end

  def self.seed_dummy_users db

    # Seed Users
    user1 = RockPaperScissors::UsersRepo.save db, { 'username' => "alex",  'password' => "password1" }
    user2 = RockPaperScissors::UsersRepo.save db, { 'username' => "jason", 'password' => "password2" }
    user3 = RockPaperScissors::UsersRepo.save db, { 'username' => "john",  'password' => "password3" }
    user4 = RockPaperScissors::UsersRepo.save db, { 'username' => "julia", 'password' => "password4" }

    # Seed Matches
    match1a = RockPaperScissors::MatchesRepo.save(db, { 'host_id' => user1['id'], 'guest_id' => user2['id'] })
    match2a = RockPaperScissors::MatchesRepo.save(db, { 'host_id' => user2['id'], 'guest_id' => user3['id'] })
    match3a = RockPaperScissors::MatchesRepo.save(db, { 'host_id' => user3['id'], 'guest_id' => user4['id'] })
    match4a = RockPaperScissors::MatchesRepo.save(db, { 'host_id' => user4['id'], 'guest_id' => user1['id'] })

    # Seed Rounds
    round1a = RockPaperScissors::RoundsRepo.save(db, {'match_id' => match1a['id']} )
    round2a = RockPaperScissors::RoundsRepo.save(db, {'match_id' => match2a['id']} )
    round3a = RockPaperScissors::RoundsRepo.save(db, {'match_id' => match3a['id']} )
    round4a = RockPaperScissors::RoundsRepo.save(db, {'match_id' => match4a['id']} )

  end
end
