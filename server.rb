require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'pry-byebug'

require './lib/rockPaperScissors.rb'

# set :bind, '0.0.0.0' # This is needed for Vagrant

class RockPaperScissors::Server < Sinatra::Application

  # use thin instead of webrick
  configure do
    enable :sessions
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
    if params[:apiToken]
      @current_user = RockPaperScissors::UsersRepo.find_by_token db, params[:apiToken]
    end

    # the next few lines are to allow cross domain requests
    headers["Access-Control-Allow-Origin"] = "*"
    headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS"
    headers["Access-Control-Allow-Headers"] = "Origin, X-Requested-With, Content-Type, Accept"
  end

  # Array used to store event streams
  # connections = []

  messages, message_count = [], 0

  ############ MAIN ROUTES ###############

  get '/' do
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
      user_data = {username: params[:username], password: params[:password]}
      user = RockPaperScissors::UsersRepo.save db, user_data
      session[:user_id] = user['id']
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
  #    Returns : An `apiToken` to make future authorized requests with.
  post '/signin' do
    user = RockPaperScissors::UsersRepo.find_by_name db, params[:username]

    if user && user['password'] == params[:password]
      token = RockPaperScissors::UsersRepo.sign_in db, user['id']
      { apiToken: token }.to_json
    else
      status 401
    end
  end
  # DELETE /signout : This endpoint accepts two parameters for the sign in process.
  #     Params : `apiToken` - The username of the user signing in
  #    Returns : An empty 200 response.
  delete '/signout' do
    RockPaperScissors::UsersRepo.sign_out db, params[:apiToken]
    status 200
    '{}'
  end

  ##########################################
  # event stream stuff.

  # GET  /users  : This endpoint will allow you to receive users from the server.
  #     Params : None.
  #     Return : An Array containing user_ids
  #              [
  #                user_data { 
  #                  'user_id' => INTEGER user_id
  #                  'username' => STRING username
  #                }
  #              ]
  GET '/users' do

  end

  # GET  /users/:user_id  : This endpoint will allow you to receive users from the server.
  #     Params : None.
  #     Return : An Hash containing user_data for user_id
  #              user_data {
  #                 'username' => STRING username
  #                 'win'      => INTEGER num of wins
  #                 'loss'     => INTEGER num of losses
  #                 'draw'     => INTEGER num of draws      
  #              }
  GET '/users/:user_id' do

  end

  # GET  /users/:user_id/matches  : This endpoint will allow you to receive users from the server.
  #     Params : None.
  #     Return : An Hash containing match_ids of all matches
  #              [INTEGER match_ids]
  GET '/users/:user_id/matches' do

  end

  # GET  /users/:user_id/matches  : This endpoint will allow you to receive users from the server.
  #     Params : None.
  #     Return : An Array of Hashes containing rounds_data for user_id
  # GET '/users/:user_id/rounds' do

  # end

  # GET  /matches  : This endpoint will allow you to receive matches from the server.
  #     Params : None.
  #     Return : An Hash containing match_ids of all matches
  #              [INTEGER match_ids]
  GET '/matches' do

  end

  # POST  /matches  : This endpoint will allow you to create a new match and new round for that match
  #     Params : `apiToken` - The api token of the signed in user.
  #              `guest_name` - The username of the challenged guest
  #     Return : A Hash containing { 'match_id' => match_id, 'round_id' => round_id}
  POST '/matches' do

  end

  # GET  /matches/:match_id  : This endpoint will allow you to receive match_data for match_id from the server.
  #     Params : None.
  #     Return : A Hash containing match_data for match_id
  #                hash { 
  #                  'host_id'   => INTEGER host_id
  #                  'guest_d'   => INTEGER guest_id
  #                  'winner_id' => INTEGER winner_id
  #                  'rounds'    => [INTEGER round_ids] # An Array of rounds for that :match_id
  #                }
  GET '/matches/:match_id' do

  end

  # PUT  /matches:match_id  : This endpoint will allow you to update the winner of match_id on the server.
  #     Params : `winner_id` - The id of the decalred winner; Expecting Host or Guest of Match
  #     Return : A Hash containing match_data for match_id
  #                match_data { 
  #                  'host_id'   => INTEGER host_id
  #                  'guest_d'   => INTEGER guest_id
  #                  'winner_id' => INTEGER winner_id
  #                  'rounds'    => [INTEGER round_ids] # An Array of rounds for that :match_id
  #                }
  PUT '/matches/:match_id' do

  end

  # DELETE  /matches/:match_id  : This endpoint will delete a match and all rounds for that match
  #     Params : `apiToken` - The api token of the signed in user; Must be Host or Guest of Match
  #     Returns : An empty 200 response.
  DELETE '/matches/:match_id' do

  end

  # GET  /rounds  : This endpoint will allow you to receive rounds from the server.
  #     Params : None.
  #     Return : An Array containing round_data for all rounds
  #              [INTEGER round_ids]
  GET '/rounds' do

  end

  # GET  /rounds:round_id  : This endpoint will allow you to receive round_data for round_id from the server.
  #     Params : None.
  #     Return : A Hash containing round_data for round_id
  #                round_data { 
  #                  'match_id'     => INTEGER match_id
  #                  'host_choice'  => VARCHAR 'r'/'p'/'s'
  #                  'guest_choice' => VARCHAR 'r'/'p'/'s'
  #                  'winner_id'    => INTEGER winner_id
  #                }
  GET '/rounds/:round_id' do

  end

  # PUT  /rounds:round_id  : This endpoint will allow you to update round_data for round_id on the server.
  #     Params : `apiToken` - The api token of the signed in user; Expecting Host or Guest of Match
  #              'user_choice' - The choice that the currently signed-in user makes
  #     Return : A Hash containing round_data for round_id
  #                round_data { 
  #                  'match_id'     => INTEGER match_id
  #                  'host_choice'  => VARCHAR 'r'/'p'/'s'
  #                  'guest_choice' => VARCHAR 'r'/'p'/'s'
  #                  'winner_id'    => INTEGER winner_id
  #                }
  PUT '/rounds/:round_id' do

  end

end
