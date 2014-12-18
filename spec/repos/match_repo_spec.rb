require 'spec_helper'
require 'pg'
require 'pry-byebug'

describe RockPaperScissors::MatchesRepo do

  def match_count(db)
    db.exec("SELECT COUNT(*) FROM matches")[0]["count"].to_i
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
    @user1 = db.exec("INSERT INTO users (username, password) VALUES ($1, $2) RETURNING *", ["Alice", "password1"]).entries.first
    @user2 = db.exec("INSERT INTO users (username, password) VALUES ($1, $2) RETURNING *", ["Bob", "password2"]).entries.first
  end

  it "gets all matches" do

    db.exec("INSERT INTO matches (host_id, guest_id) values ($1, $2)", [@user1['id'], @user2['id']])
    db.exec("INSERT INTO matches (host_id, guest_id) values ($1, $2)", [@user2['id'], @user1['id']])

    matches = RockPaperScissors::MatchesRepo.all(db)
    expect(matches).to be_a Array
    expect(matches.count).to eq 2

    host_ids = matches.map {|u| u['host_id'] }
    expect(host_ids).to include @user1['id'], @user2['id']
  end

  it "creates matches" do
    expect(match_count(db)).to eq 0

    match = RockPaperScissors::MatchesRepo.save(db, { 'host_id' => @user1['id'], 'guest_id' => @user2['id'] })

    expect(match).to be_a Hash
    expect(match['id']).to_not be_nil
    expect(match['host_id']).to eq @user1['id']
    expect(match['guest_id']).to eq @user2['id']
    expect(match['winner_id']).to be_nil

    # Check for persistence
    expect(match_count(db)).to eq 1

    match = db.exec("SELECT * FROM matches").first
    expect(match['host_id']).to eq @user1['id']
  end

  it "finds matches" do
    match = RockPaperScissors::MatchesRepo.save(db, { 'host_id' => @user1['id'], 'guest_id' => @user2['id'] })
    expect(match).to be_a Hash
    retrieved_match = RockPaperScissors::MatchesRepo.find(db, match['id'])
    expect(retrieved_match).to be_a Hash
    expect(retrieved_match['host_id']).to eq @user1['id']
    expect(retrieved_match['guest_id']).to eq @user2['id']
  end

  it "updates winner of match to guest" do
    match1 = RockPaperScissors::MatchesRepo.save(db, { 'host_id' => @user1['id'], 'guest_id' => @user2['id'] })
    match1_win = RockPaperScissors::MatchesRepo.save(db, { 'id' => match1['id'], 'winner_id' => match1['guest_id'] })
    expect(match1_win).to be_a Hash
    expect(match1_win['id']).to eq(match1['id'])
    expect(match1_win['host_id']).to eq(match1['host_id'])
    expect(match1_win['guest_id']).to eq(match1['guest_id'])
    expect(match1_win['winner_id']).to eq(match1['guest_id'])

    # Check for persistence
    match3 = RockPaperScissors::MatchesRepo.find(db, match1['id'])
    expect(match3).to be_a Hash
    expect(match3['winner_id']).to eq match1['guest_id']
  end

end
