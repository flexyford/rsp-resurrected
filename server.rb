require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'pry-byebug'

require './lib/rockPaperScissors.rb'

# set :bind, '0.0.0.0' # This is needed for Vagrant

class RockPaperScissors::Server < Sinatra::Application

  # use thin instead of webrick
  configure do
    # enable :sessions
    set server: 'thin'
  end

  # helpers for connecting to db and prerparing json responses
  helpers do
    def db
      RockPaperScissors.create_db_connection 'rock_paper_scissors'
    end

    def timestamp
      Time.now.to_i
    end

    #def respond sender, message
    #  {
    #    :sender    => sender,
    #    :message   => message,
    #    :timestamp => timestamp
    #  }.to_json
    #end

  end

  # run this before every endpoint to get the current user
  before do
    # this condition assign the current user if someone is logged in
    if params[:token]
      @current_user = RockPaperScissors::UsersRepo.find_by_token db, params[:token]
    end

    # the next few lines are to allow cross domain requests
    headers["Access-Control-Allow-Origin"] = "*"
    headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
    headers["Access-Control-Allow-Headers"] = "Origin, X-Requested-With, Content-Type, Accept"
    headers['Content-Type'] = 'application/json'
  end

  # Array used to store event streams
  # connections = []

  messages, message_count = [], 0

  ############ MAIN ROUTES ###############

  get '/' do
    headers['Content-Type'] = 'text/html'
    send_file 'public/index.html'
  end

  # POST /signup : This endpoint is for signing up for an account with RockPaperScissors.
  #     Params : `username` - The username of the user signing in
  #              `password` - The password of the user signing in
  #    Returns : An empty 200 response.
  post '/signup' do
    errors = []
    if !params[:password] || params[:password] == ''
      errors << 'blank_password'
    end
    if !params[:username] || params[:username] == ''
      errors << 'blank_username'
    end
    if RockPaperScissors::UsersRepo.find_by_name(db, params[:username])
      errors << 'username_taken'
    end

    if errors.count == 0
      user_data = {'username' => params[:username], 'password' => params[:password]}
      user = RockPaperScissors::UsersRepo.save db, user_data
      # session[:user_id] = user['id']
      status 200
      '{}'
    else
      status 400
      { errors: errors }.to_json
    end
  end
  # POST /signin : This endpoint accepts two parameters for the sign in process.
  #     Params : `username` - The username of the user signing in
  #              `password` - The password of the user signing in
  #    Returns : An `token` to make future authorized requests with.
  post '/signin' do
    errors = []
    user = RockPaperScissors::UsersRepo.find_by_name db, params[:username]

    if user
      if user['password'] == params[:password]
        token = RockPaperScissors::UsersRepo.sign_in db, user['id']
        { token: token, id: user['id']}.to_json ### JASON CHANGED THIS TO INCLUDE ID
      else
        status 401
        errors << "invalid password"
        { errors: errors }.to_json
      end
    else
      status 401
    end
  end
  # DELETE /signout : This endpoint accepts two parameters for the sign in process.
  #     Params : `token` - The username of the user signing in
  #    Returns : An empty 200 response.
  delete '/signout' do
    RockPaperScissors::UsersRepo.sign_out db, params[:token]
    status 200
    '{}'
  end

  ##########################################
  # event stream stuff.

  # get  /users  : This endpoint will allow you to receive users from the server.
  #     Params : None.
  #     Return : An Array containing user_ids
  #              [
  #                user_data { 
  #                  'user_id' => INTEGER user_id
  #                  'username' => STRING username
  #                }
  #              ]
  get '/users' do
    users = RockPaperScissors::UsersRepo.all(db)
    status 200
    if !users.nil?
      users.map {|u| { 'user_id' => u['id'], 'username' => u['username'] } }.to_json
    else
      '[]'
    end
  end

  # get  /users/:user_id  : This endpoint will allow you to receive users from the server.
  #     Params : None.
  #     Return : An Hash containing user_data for user_id
  #              user_data {
  #                 'username' => STRING username
  #                 'wins'      => INTEGER num of wins
  #                 'losses'     => INTEGER num of losses     
  #              }
  get '/users/:user_id' do
    user = RockPaperScissors::UsersRepo.find(db, params[:user_id])
    if user
      record = RockPaperScissors::MatchesRepo.user_match_record(db, user['id'])
      status 200
      {
        'username' => user['username'],
        'wins' => record['wins'],
        'losses' => record['losses']
      }.to_json
    else
      errors << 'user not found'
      status 401
      { errors: errors }.to_json
    end
  end

  # get  /users/:user_id/matches  : This endpoint will allow you to receive users from the server.
  #     Params : None.
  #     Return : A Hash containing keys whose values are arrays
  #              {
  #                'active'   => [match_ids of all currently active matches]
  #                'complete' => [match_ids of all completed matches]
  #              }
  get '/users/:user_id/matches' do
    user = RockPaperScissors::UsersRepo.find(db, params[:user_id])
    if user
      active = RockPaperScissors::MatchesRepo.find_active_by_user(db, user['id']) || []
      complete = RockPaperScissors::MatchesRepo.find_complete_by_user(db, user['id']) || []
      status 200
      { 'active' => active.map! {|m| m['id'] }, 'complete' => complete.map! {|m| m['id'] } }.to_json
    else
      errors << 'user not found'
      status 401
      { errors: errors }.to_json
    end
  end

  # get  /users/:user_id/matches  : This endpoint will allow you to receive users from the server.
  #     Params : None.
  #     Return : An Array of Hashes containing rounds_data for user_id
  # get '/users/:user_id/rounds' do

  # end

  # get  /matches  : This endpoint will allow you to receive matches from the server.
  #     Params : None.
  #     Return : An Hash containing match_ids of all matches
  #              [INTEGER match_ids]
  get '/matches' do
    matches = RockPaperScissors::MatchesRepo.all(db)
    status 200
    if !matches.nil?
        matches.map {|m| m['id'] }.to_json
    else
      '[]'
    end
  end

  # POST  /matches  : This endpoint will allow you to create a new match and new round for that match
  #     Params : `token` - The api token of the signed in user.
  #              `guest_name` - The username of the challenged guest
  #     Return : A Hash containing { 'match_id' => match_id}
  post '/matches' do
    errors = []
    host = RockPaperScissors::UsersRepo.find_by_token(db, params[:token])
    guest = RockPaperScissors::UsersRepo.find_by_name(db, params[:guest_name])

    if host && guest
      # Update Round
      if guest
        # Create Match
        match = RockPaperScissors::MatchesRepo.save(db, { 'host_id' => host['id'], 'guest_id' => guest['id'] })

        {
          'match_id' => match['id']
        }.to_json     
      else
        errors << 'user is not a valid guest'
        status 400
        { errors: errors }.to_json
      end
    else
      errors << 'user not found or user not logged in'
      status 401
      { errors: errors }.to_json
    end
  end

  # get  /matches/:match_id  : This endpoint will allow you to receive match_data for match_id from the server.
  #     Params : None.
  #     Return : A Hash containing match_data for match_id
  #                match_data {
  #                  'id'        => INTEGER match_id 
  #                  'host_id'   => INTEGER host_id
  #                  'guest_d'   => INTEGER guest_id
  #                  'winner_id' => INTEGER winner_id
  #                  'rounds'    => [INTEGER round_ids] # An Array of rounds for that :match_id
  #                }
  get '/matches/:match_id' do
    errors = []
    match = RockPaperScissors::MatchesRepo.find(db, params[:match_id])
    rounds = RockPaperScissors::RoundsRepo.find_by_match(db, params[:match_id])
    if match
        {
          'id' => match['id'],
          'host_id' => match['host_id'],
          'guest_id' => match['guest_id'],
          'winner_id' => match['winner_id'],
          'rounds' => rounds
        }.to_json
    else
      errors << 'match not found'
      status 401
      { errors: errors }.to_json
    end
  end

  # post  /matches/:match_id/rounds  : This endpoint will create a new round for :match_id
  #     Params : None.
  #     Return : A Hash containing match_data for match_id
  #                match_data {
  #                  'id'        => INTEGER match_id 
  #                  'host_id'   => INTEGER host_id
  #                  'guest_d'   => INTEGER guest_id
  #                  'winner_id' => INTEGER winner_id
  #                  'rounds'    => [INTEGER round_ids] # An Array of rounds for that :match_id
  #                }
  post '/matches/:match_id/rounds' do
    errors = []
    match = RockPaperScissors::MatchesRepo.find(db, params[:match_id])
    if match
        # Create Round
        round = RockPaperScissors::RoundsRepo.save(db, {'match_id' => match['id']} )
        rounds = RockPaperScissors::RoundsRepo.find_by_match(db, params[:match_id])
        {
          'id' => match['id'],
          'host_id' => match['host_id'],
          'guest_id' => match['guest_id'],
          'winner_id' => match['winner_id'],
          'rounds' => rounds
        }.to_json
    else
      errors << 'match not found'
      status 401
      { errors: errors }.to_json
    end
  end

  # PUT  /matches:match_id  : This endpoint will allow you to update the winner of match_id on the server.
  #     Params : `winner_id` - The id of the decalred winner; Expecting Host or Guest of Match
  #     Return : A Hash containing match_data for match_id
  #                match_data {
  #                  'id'        => INTEGER match_id 
  #                  'host_id'   => INTEGER host_id
  #                  'guest_d'   => INTEGER guest_id
  #                  'winner_id' => INTEGER winner_id
  #                  'rounds'    => [INTEGER round_ids] # An Array of rounds for that :match_id
  #                }
  put '/matches/:match_id' do
    errors = []
    user = RockPaperScissors::UsersRepo.find_by_token(db, params[:winner_id])
    
    rounds = RockPaperScissors::RoundsRepo.find_by_match(db, params[:match_id])
    if user && match && rounds
      if user['id'] == match['host_id'] || user['id'] == match['guest_id']
        # Update Winner
        match = RockPaperScissors::MatchesRepo.save(db, { 'id' => match['id'], 'winner_id' => user['id'] })

        {
          'id' => match['id'],
          'host_id' => match['host_id'],
          'guest_id' => match['guest_id'],
          'winner_id' => match['winner_id'],
          'rounds' => rounds
        }.to_json
      else
        errors << "user does not exist for this match"
        { errors: errors }.to_json
      end
    else
      status 401
    end
  end

  # DELETE  /matches/:match_id  : This endpoint will delete a match and all rounds for that match
  #     Params : `token` - The api token of the signed in user; Must be Host or Guest of Match
  #     Returns : An empty 200 response.
  delete '/matches/:match_id' do
    user = RockPaperScissors::UsersRepo.find_by_token(db, params[:token])
    if user
      match = RockPaperScissors::MatchesRepo.find(db, params[:match_id])
      rounds = RockPaperScissors::RoundsRepo.find_by_match(db, params[:match_id])
      if (user['id'] == match['host_id'] || user['id'] == match['guest_id'])
        RockPaperScissors::MatchesRepo.destory(db, match['id']).to_json
      else
        errors << 'user is not a host or guest for this match'
        status 400
        { errors: errors }.to_json
      end
    else
      errors << 'user not found or user not logged in'
      status 401
      { errors: errors }.to_json
    end
  end

  # get  /rounds  : This endpoint will allow you to receive rounds from the server.
  #     Params : None.
  #     Return : An Array containing round_data for all rounds
  #              [INTEGER round_ids]
  get '/rounds' do
    rounds = RockPaperScissors::MatchesRepo.all(db)
    status 200
    if !rounds.nil?
        rounds.map {|r| r['id'] }.to_json
    else
      '[]'
    end
    
  end

  # get  /rounds:round_id  : This endpoint will allow you to receive round_data for round_id from the server.
  #     Params : None.
  #     Return : A Hash containing round_data for round_id
  #                round_data { 
  #                  'id'           => INTEGER round_id
  #                  'match_id'     => INTEGER match_id
  #                  'host_choice'  => VARCHAR 'r'/'p'/'s'
  #                  'guest_choice' => VARCHAR 'r'/'p'/'s'
  #                  'winner_id'    => INTEGER winner_id
  #                }
  get '/rounds/:round_id' do
    round = RockPaperScissors::RoundsRepo.find(db, params[:round_id])
    if round
      round.to_json
    else
      errors << 'round not found'
      status 401
      { errors: errors }.to_json
    end
    
  end

  # PUT  /rounds:round_id  : This endpoint will allow you to update round_data for round_id on the server.
  #     Params : `token` - The api token of the signed in user; Expecting Host or Guest of Match
  #              'user_choice' - The choice that the currently signed-in user makes
  #     Return : A Hash containing round_data for round_id
  #                round_data {
  #                  'id'           => INTEGER round_id
  #                  'match_id'     => INTEGER match_id
  #                  'host_choice'  => VARCHAR 'r'/'p'/'s'
  #                  'guest_choice' => VARCHAR 'r'/'p'/'s'
  #                  'winner_id'    => INTEGER winner_id
  #                }
  put '/rounds/:round_id' do
    errors = []
    user = RockPaperScissors::UsersRepo.find_by_token(db, params[:token])
    
    if user
      # Update Round
      round = RockPaperScissors::RoundsRepo.find(db, params[:round_id])
      match = RockPaperScissors::MatchesRepo.find(db, round['match_id'])
      if round && match

        if user['id'] == match['host_id']
          round = RockPaperScissors::RoundsRepo.save(db, { 'id' => round['id'], 'host_choice' => params[:user_choice]} )
          updateRoundWinner(round, match['host_id'], match['guest_id']).to_json
        elsif user['id'] == match['guest_id']
          round = RockPaperScissors::RoundsRepo.save(db, { 'id' => round['id'], 'guest_choice' => params[:user_choice]} )
          updateRoundWinner(round, match['host_id'], match['guest_id']).to_json
        else
          errors << 'user is not a hot or guest for this round'
          status 400
          { errors: errors }.to_json
        end
      else
        errors << 'no round or match data found'
        status 401
        { errors: errors }.to_json
      end
    else
      errors << 'user not found or user not logged in'
      status 401
      { errors: errors }.to_json
    end
  end

  def updateRoundWinner round_data, host_id, guest_id
    if round_data['host_choice'] && round_data['guest_choice']
      if round_data['host_choice'] != round_data['guest_choice']
        if round_data['host_choice'] == RockPaperScissors::ROCK
          if round_data['guest_choice'] == RockPaperScissors::PAPER
            # Guest Wins
            RockPaperScissors::RoundsRepo.save(db, { 'id' => round_data['id'], 'winner_id' => guest_id} )
          elsif round_data['guest_choice'] == RockPaperScissors::SCISSORS
            # Host Wins
            RockPaperScissors::RoundsRepo.save(db, { 'id' => round_data['id'], 'winner_id' => host_id} )
          end
        elsif round_data['host_choice'] == RockPaperScissors::PAPER
          if round_data['guest_choice'] == RockPaperScissors::ROCK
            # Host Wins
            RockPaperScissors::RoundsRepo.save(db, { 'id' => round_data['id'], 'winner_id' => host_id} )
          elsif round_data['guest_choice'] == RockPaperScissors::SCISSORS
            # Guest Wins
            RockPaperScissors::RoundsRepo.save(db, { 'id' => round_data['id'], 'winner_id' => guest_id} )
          end
        elsif round_data['host_choice'] == RockPaperScissors::SCISSORS
          if round_data['guest_choice'] == RockPaperScissors::PAPER
            # Host Wins
            RockPaperScissors::RoundsRepo.save(db, { 'id' => round_data['id'], 'winner_id' => host_id} )
          elsif round_data['guest_choice'] == RockPaperScissors::ROCK
            # Guest Wins
            RockPaperScissors::RoundsRepo.save(db, { 'id' => round_data['id'], 'winner_id' => guest_id} )
          end
        end
      end
    end
    RockPaperScissors::RoundsRepo.find(db, round_data['id'])
  end

end
