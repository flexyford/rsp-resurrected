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
    puts 'Database \'rock_paper_scissors\' created!'
  end

  task :drop do
    `dropdb rock_paper_scissors`
    puts 'Database \'rock_paper_scissors\' dropped!'
  end

  task :create_tables => :environment do
    db = RockPaperScissors.create_db_connection 'rock_paper_scissors'
    RockPaperScissors.create_tables db
    puts 'Created tables.'
  end

  task :drop_tables => :environment do
    db = RockPaperScissors.create_db_connection 'rock_paper_scissors'
    RockPaperScissors.drop_tables db
    puts 'Dropped tables.'
  end

  task :clear => :environment do
    db = RockPaperScissors.create_db_connection 'rock_paper_scissors'
    RockPaperScissors.clear_tables db
    puts 'Cleared tables.'
  end

  task :seed => :environment do
    db = RockPaperScissors.create_db_connection 'rock_paper_scissors'
    RockPaperScissors.seed_dummy_users db
    puts 'Tables seeded.'
  end
end
