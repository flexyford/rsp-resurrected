require 'spec_helper'
require 'pg'

describe RockPaperScissors::RoundsRepo do

  def round_count(db)
    db.exec("SELECT COUNT(*) FROM rounds")[0]["count"].to_i
  end

  # A let(:db) define means you can use db in an it statement below
  # Also, the code in {} does not run until it sees a 'db' statement in an 'it' block
  # Therefore, the code will run for each 'it' block
  let(:db) {
    RockPaperScissors.create_db('rock_paper_scissors_test')
    RockPaperScissors.create_db_connection('rock_paper_scissors_test')
  }

  # Before each 'it' block we are clearing the data base
  # That way when we crete users we know exactly how many should be in the db
  before(:each) do
    RockPaperScissors.clear(db)
    RockPaperScissors.create_tables(db)
    user1 = db.exec("INSERT INTO users (username, password) VALUES ($1, $2)", ["Alice", "password1"])
    user2 = db.exec("INSERT INTO users (username, password) VALUES ($1, $2)", ["Bob", "password2"])
    match1 = db.exec("INSERT INTO matches (host_id, guest_id) values ($1, $2)", [user1['id'], user2['id']])
    match2 = db.exec("INSERT INTO matches (host_id, guest_id) values ($1, $2)", [user2['id'], user1['id']])
  end

  xit "gets all rounds" do
    db.exec("INSERT INTO rounds (match_id) values ($1, $2)", [match1['id']])
    db.exec("INSERT INTO rounds (match_id) values ($1, $2)", [match2['id']])

    rounds = RockPaperScissors::RoundsRepo.all(db)
    expect(rounds).to be_a Array
    expect(rounds.count).to eq 2

    match_ids = rounds.map {|u| u['match_id'] }
    expect(match_ids).to include match1['id'], match2['id']
  end

  xit "creates rounds" do
    expect(round_count(db)).to eq 0

    round = RockPaperScissors::RoundsRepo.save(db, {'match_id' => match1['id']} )
    expect(round).to be_a Hash
    expect(round['id']).to_not be_nil
    expect(round['match_id']).to eq match1['id']
    expect(round['host_choice']).to be_nil
    expect(round['guest_choice']).to be_nil
    expect(round['winner_id']).to be_nil

    # Check for persistence
    expect(round_count(db)).to eq 1

    round = db.exec("SELECT * FROM rounds").first
    expect(round['match_id']).to eq match1['id']
  end

  xit "finds rounds" do
    round = RockPaperScissors::RoundsRepo.save(db, {'match_id' => match1['id']} )
    retrieved_round = RockPaperScissors::RoundsRepo.find(db, round['id'])
    expect(retrieved_round).to be_a Hash
    expect(retrieved_round['match_id']).to eq match1['id']
  end

  xit "makes selections in round" do
    round1 = RockPaperScissors::RoundsRepo.save(db, {'match_id' => match1['id']} )
    round2 = RockPaperScissors::RoundsRepo.save(db, {'match_id' => match2['id']} )

    expect(RockPaperScissors.ROCK).to eq 'r'
    expect(RockPaperScissors.PAPER).to eq 'p'
    expect(RockPaperScissors.SCISSORS).to eq 's'

    # Make 1 Selection at a time
    round1_sel = RockPaperScissors::RoundsRepo.save(db, { 'id' => round1['id'], 'host_choice' => RockPaperScissors.ROCK} )
    expect(round1_sel).to be_a Hash
    expect(round1['host_choice']).to eq RockPaperScissors.ROCK

    round1_sel = RockPaperScissors::RoundsRepo.save(db, { 'id' => round1['id'], 'guest_choice' => RockPaperScissors.SCISSORS} )
    expect(round1_sel).to be_a Hash
    expect(round1['guest_choice']).to eq RockPaperScissors.ROCK

    # Make 2 Selections at a time
    round2_sel = RockPaperScissors::RoundsRepo.save(db, { 'id' => round1['id'], 'guest_choice' => RockPaperScissors.PAPER, 'guest_choice' => RockPaperScissors.PAPER} )
    expect(round2_sel).to be_a Hash
    expect(round2['host_choice']).to eq RockPaperScissors.PAPER
    expect(round2['guest_choice']).to eq RockPaperScissors.PAPER

    # Check for persistence
    round3 = RockPaperScissors::RoundsRepo.find(db, round1['id'])
    expect(round3).to be_a Hash
    expect(round3['host_choice']).to eq RockPaperScissors.ROCK
  end

  xit "updates winners of rounds" do
    round1 = RockPaperScissors::RoundsRepo.save(db, {'match_id' => match1['id']} )
    round2 = RockPaperScissors::RoundsRepo.save(db, {'match_id' => match2['id']} )

    # Make 1 Selection at a time
    round1 = RockPaperScissors::RoundsRepo.save(db, { 'id' => round1['id'], 'host_choice' => RockPaperScissors.ROCK} )
    round1 = RockPaperScissors::RoundsRepo.save(db, { 'id' => round1['id'], 'guest_choice' => RockPaperScissors.SCISSORS} )

    round1 = RockPaperScissors::RoundsRepo.save(db, { 'id' => round1['id'], 'winnner_id' => user1['id']} )
    expect(round1).to be_a Hash
    expect(round1['winner_id']).to eq user1['id']

    # Make 2 Selections at a time
    round2 = RockPaperScissors::RoundsRepo.save(db, { 'id' => round2['id'], 'guest_choice' => RockPaperScissors.PAPER, 'guest_choice' => RockPaperScissors.PAPER} )
    expect(round1['winner_id']).to be_nil
  end
end
