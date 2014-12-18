task :environment do
  require './lib/rockPaperScissors'
end

task :console => :environment do
  require 'irb'
  ARGV.clear
  IRB.start
end

namespace :db do
  task :create do
    `createdb rock_paper_scissors`
    `createdb rock_paper_scissors_test`
    puts 'Database \'rock_paper_scissors\' created!'
    puts 'Database \'rock_paper_scissors_test\' created!'
  end

  task :drop do
    `dropdb rock_paper_scissors`
    `dropdb rock_paper_scissors_test`
    puts 'Database \'rock_paper_scissors\' dropped!'
    puts 'Database \'rock_paper_scissors_test\' dropped!'
  end

  task :create_tables => :environment do
    db = RockPaperScissors.create_db_connection 'rock_paper_scissors'
    db_test = RockPaperScissors.create_db_connection 'rock_paper_scissors_test'
    RockPaperScissors.create_tables db
    RockPaperScissors.create_tables db_test
    puts 'Created tables.'
  end

  task :drop_tables => :environment do
    db = RockPaperScissors.create_db_connection 'rock_paper_scissors'
    db_test = RockPaperScissors.create_db_connection 'rock_paper_scissors_test'
    RockPaperScissors.drop_tables db
    RockPaperScissors.drop_tables db_test
    puts 'Dropped tables.'
  end

  task :clear => :environment do
    db = RockPaperScissors.create_db_connection 'rock_paper_scissors'
    db_test = RockPaperScissors.create_db_connection 'rock_paper_scissors_test'
    RockPaperScissors.clear db
    RockPaperScissors.clear db_test
    puts 'Cleared tables.'
  end

  task :seed => :environment do
    db = RockPaperScissors.create_db_connection 'rock_paper_scissors'
    RockPaperScissors.seed_dummy_users db
    puts 'Tables seeded.'
  end
end
