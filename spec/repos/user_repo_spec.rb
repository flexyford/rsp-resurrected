require 'spec_helper'
require 'pg'
require 'pry-byebug'

describe RockPaperScissors::UsersRepo do

  def user_count(db)
    db.exec("SELECT COUNT(*) FROM users")[0]["count"].to_i
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
  end

  it "gets all users" do
    db.exec("INSERT INTO users (username, password) VALUES ($1, $2)", ["Alice", "password1"])
    db.exec("INSERT INTO users (username, password) VALUES ($1, $2)", ["Bob", "password2"])

    users = RockPaperScissors::UsersRepo.all(db)
    expect(users).to be_a Array
    expect(users.count).to eq 2

    names = users.map {|u| u['username'] }
    expect(names).to include "Alice", "Bob"
  end

  it "creates users" do
    expect(user_count(db)).to eq 0
    user = RockPaperScissors::UsersRepo.save db, { 'username' => "Alice", 'password' => "password1" }
    expect(user).to be_a Hash
    expect(user['id']).to_not be_nil
    expect(user['username']).to eq "Alice"

    # Check for persistence
    expect(user_count(db)).to eq 1

    user = db.exec("SELECT * FROM users").first
    expect(user['username']).to eq "Alice"
  end

  it "finds users" do
    user = RockPaperScissors::UsersRepo.save db, { 'username' => "Alice", 'password' => "password1" }
    retrieved_user = RockPaperScissors::UsersRepo.find(db, user['id'])
    expect(retrieved_user).to be_a Hash
    expect(retrieved_user['username']).to eq "Alice"
  end

  it "updates users" do
    user1 = RockPaperScissors::UsersRepo.save db, { 'username' => "Alice", 'password' => "password1" }
    user2 = RockPaperScissors::UsersRepo.save(db, { 'id' => user1['id'], 'username' => "Alicia" })
    expect(user2).to be_a Hash
    expect(user2['id']).to eq(user1['id'])
    expect(user2['username']).to eq "Alicia"

    # Check for persistence
    user3 = RockPaperScissors::UsersRepo.find(db, user1['id'])
    expect(user3).to be_a Hash
    expect(user3['username']).to eq "Alicia"
  end

  it "destroys users" do
    user = RockPaperScissors::UsersRepo.save db, { 'username' => "Alice", 'password' => "password1" }
    expect(user_count(db)).to eq 1

    RockPaperScissors::UsersRepo.destroy(db, user['id'])
    expect(user_count(db)).to eq 0
  end

  it "sign in user" do
    user = RockPaperScissors::UsersRepo.save db, { 'username' => "Alice", 'password' => "password1" }
    token = RockPaperScissors::UsersRepo.sign_in db, user['id']
    expect(token).to_not be_nil
  end

  

end
