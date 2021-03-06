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
    @user1 = db.exec("INSERT INTO users (username, password) VALUES ($1, $2) RETURNING *", ["Alice", "password1"]).entries.first
    @user2 = db.exec("INSERT INTO users (username, password) VALUES ($1, $2) RETURNING *", ["Bob", "password2"]).entries.first
    @match1 = db.exec("INSERT INTO matches (host_id, guest_id) values ($1, $2) RETURNING *", [@user1['id'], @user2['id']]).entries.first
    @match2 = db.exec("INSERT INTO matches (host_id, guest_id) values ($1, $2) RETURNING *", [@user2['id'], @user1['id']]).entries.first
  end

  it "gets all rounds" do
    db.exec("INSERT INTO rounds (match_id) values ($1)", [@match1['id']])
    db.exec("INSERT INTO rounds (match_id) values ($1)", [@match2['id']])

    rounds = RockPaperScissors::RoundsRepo.all(db)
    expect(rounds).to be_a Array
    expect(rounds.count).to eq 2

    match_ids = rounds.map {|u| u['match_id'] }
    expect(match_ids).to include @match1['id'], @match2['id']
  end

  it "creates rounds" do
    expect(round_count(db)).to eq 0

    round = RockPaperScissors::RoundsRepo.save(db, {'match_id' => @match1['id']} )
    expect(round).to be_a Hash
    expect(round['id']).to_not be_nil
    expect(round['match_id']).to eq @match1['id']
    expect(round['host_choice']).to be_nil
    expect(round['guest_choice']).to be_nil
    expect(round['winner_id']).to be_nil

    # Check for persistence
    expect(round_count(db)).to eq 1

    round = db.exec("SELECT * FROM rounds").first
    expect(round['match_id']).to eq @match1['id']
  end

  it "finds rounds" do
    round = RockPaperScissors::RoundsRepo.save(db, {'match_id' => @match1['id']} )
    retrieved_round = RockPaperScissors::RoundsRepo.find(db, round['id'])
    expect(retrieved_round).to be_a Hash
    expect(retrieved_round['match_id']).to eq @match1['id']
  end

  it "makes selections in round" do
    round1 = RockPaperScissors::RoundsRepo.save(db, {'match_id' => @match1['id']} )
    round2 = RockPaperScissors::RoundsRepo.save(db, {'match_id' => @match2['id']} )

    expect(RockPaperScissors::ROCK).to eq 'r'
    expect(RockPaperScissors::PAPER).to eq 'p'
    expect(RockPaperScissors::SCISSORS).to eq 's'

    # Make 1 Selection at a time
    round1_sel = RockPaperScissors::RoundsRepo.save(db, { 'id' => round1['id'], 'host_choice' => RockPaperScissors::ROCK} )
    expect(round1_sel).to be_a Hash
    expect(round1_sel['host_choice']).to eq RockPaperScissors::ROCK

    round1_sel = RockPaperScissors::RoundsRepo.save(db, { 'id' => round1['id'], 'guest_choice' => RockPaperScissors::SCISSORS} )
    expect(round1_sel).to be_a Hash
    expect(round1_sel['guest_choice']).to eq RockPaperScissors::SCISSORS

    # Make 2 Selections at a time
    round2_sel = RockPaperScissors::RoundsRepo.save(db, { 'id' => round2['id'], 'host_choice' => RockPaperScissors::PAPER, 'guest_choice' => RockPaperScissors::PAPER} )
    expect(round2_sel).to be_a Hash
    expect(round2_sel['host_choice']).to eq RockPaperScissors::PAPER
    expect(round2_sel['guest_choice']).to eq RockPaperScissors::PAPER

    # Check for persistence
    round3 = RockPaperScissors::RoundsRepo.find(db, round1['id'])
    expect(round3).to be_a Hash
    expect(round3['host_choice']).to eq RockPaperScissors::ROCK
  end

  it "updates winners of rounds" do
    round1 = RockPaperScissors::RoundsRepo.save(db, {'match_id' => @match1['id']} )
    round2 = RockPaperScissors::RoundsRepo.save(db, {'match_id' => @match2['id']} )

    # Make 1 Selection at a time
    round1 = RockPaperScissors::RoundsRepo.save(db, { 'id' => round1['id'], 'host_choice' => RockPaperScissors::ROCK} )
    round1 = RockPaperScissors::RoundsRepo.save(db, { 'id' => round1['id'], 'guest_choice' => RockPaperScissors::SCISSORS} )

    round1 = RockPaperScissors::RoundsRepo.save(db, { 'id' => round1['id'], 'winner_id' => @user1['id']} )
    expect(round1).to be_a Hash
    expect(round1['winner_id']).to eq @user1['id']

    # Make 2 Selections at a time
    round2 = RockPaperScissors::RoundsRepo.save(db, { 'id' => round2['id'], 'guest_choice' => RockPaperScissors::PAPER, 'guest_choice' => RockPaperScissors::PAPER} )

    # Check that outcome is a draw
    expect(round2['winner_id']).to be_nil
  end

it "check user match records" do
    # Init Users
    host = RockPaperScissors::UsersRepo.save db, { 'username' => "Alice", 'password' => "password1" }
    guest = RockPaperScissors::UsersRepo.save db, { 'username' => "Bob", 'password' => "password2" }

    # Init Match
    match = RockPaperScissors::MatchesRepo.save(db, { 'host_id' => host['id'], 'guest_id' => guest['id'] })

    # Init a Round 1
    round1 = RockPaperScissors::RoundsRepo.save(db, {'match_id' => match['id']} )

    # Make 1 Selection at a time
    round1 = RockPaperScissors::RoundsRepo.save(db, { 'id' => round1['id'], 'host_choice' => RockPaperScissors::ROCK} )

    round1 = RockPaperScissors::RoundsRepo.save(db, { 'id' => round1['id'], 'guest_choice' => RockPaperScissors::SCISSORS} )

    # Declare Winner of Round 1
    round1 = RockPaperScissors::RoundsRepo.save(db, { 'id' => round1['id'], 'winner_id' => host['id']} )

    # Init a Round 2
    round2 = RockPaperScissors::RoundsRepo.save(db, {'match_id' => match['id']} )

    # Make 2 Selections at a time
    round2_sel = RockPaperScissors::RoundsRepo.save(db, { 'id' => round1['id'], 'guest_choice' => RockPaperScissors::PAPER, 'host_choice' => RockPaperScissors::PAPER} )

    host_record = RockPaperScissors::RoundsRepo.user_round_record(db, host['id'])
    guest_record = RockPaperScissors::RoundsRepo.user_round_record(db, guest['id'])


    expect(host_record['wins']).to eq "1"
    expect(host_record['losses']).to eq "0"
    expect(host_record['draws']).to eq "1"

    expect(guest_record['wins']).to eq "0"
    expect(guest_record['losses']).to eq "1"
    expect(guest_record['draws']).to eq "1"

  end
end
