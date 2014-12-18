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
      DELETE FROM users;
      DELETE FROM sessions;
      DELETE FROM matches;
      DELETE FROM rounds;
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
        id integer,
        match_id integer references matches(id),
        host_choice VARCHAR,
        guest_choice VARCHAR,
        winner_id integer references users(id)
      );
    SQL
  end

  def self.drop_tables db
    db.exec <<-SQL
      DROP TABLE IF EXISTS users;
      DROP TABLE IF EXISTS sessions;
      DROP TABLE IF EXISTS matches;
      DROP TABLE IF EXISTS rounds;
    SQL
  end

  def self.seed_dummy_users db
    db.exec <<-SQL
      INSERT INTO users (username, password)
      VALUES ('nick','nick'), ('kate','kate');
    SQL
  end
end
