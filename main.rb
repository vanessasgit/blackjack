require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17

helpers do
   def calculate(arr)
    total = 0
    aces = 0
    arr.each do |v|
      if v.first.eql?("Jack") || v.first.eql?("Queen") || v.first.eql?("King")
        total += 10
      elsif v.first == "Ace"
        total += 11
        aces += 1
      else  
      total += v.first
      end
    end

    while aces > 0 && total > 21 
      total -=10
      aces -= 1
    end
    total
  end 

  def card_image(card)
    suit = case card[1]
      when "of clubs" then 'clubs'
      when "of diamonds" then 'diamonds'
      when "of hearts" then 'hearts'
      when "of spades" then 'spades'
    end

    value = card[0]
    if ["Jack", "Queen", "King", "Ace"].include?(value)
      value = case card[0]
        when "Jack" then 'jack'
        when "Queen" then 'queen'
        when "King" then 'king'
        when "Ace" then 'ace'
      end
    end

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  def winner!(msg)
    @play_again = true
    @show_hit_or_hit_stay_buttons = false
    @success = "<strong> #{session[:username]} wins!</strong> #{msg}"
  end

  def loser!(msg)
    @play_again = true
    @show_hit_or_hit_stay_buttons = false
    @error = "<strong> #{session[:username]} lost!</strong> #{msg}"
  end

  def tie!(msg)
    @play_again = true
    @success = "<strong> #{session[:username]} tied!</strong> #{msg}"
  end
end

before do
  @show_hit_or_hit_stay_buttons = true
  @show_dealer_hit_button = false
end

get '/' do
  if session[:username]
    redirect '/game'
  else
    redirect 'set_name'
  end
    
end

get '/set_name' do 
  erb :set_name
end

post '/set_name' do
  if params[:username].empty?
    @error = "Name is required"
    halt erb(:set_name)
  end

  session['username'] = params['username'] # saves the name before redirecting
  redirect '/game'
end

get '/game' do
  session[:turn] = "player"

  # create a deck and store it in a session

  suit = ["of clubs", "of diamonds", "of hearts", "of spades"]
  card = [ "Ace", 2, 3, 4, 5, 6, 7, 8, 9, 10, "Jack", "Queen", "King"]

  session[:deck] = card.product(suit).shuffle!

  #deal cards
  session[:player_cards] = []
  session[:dealers_cards] = []
  session[:dealers_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealers_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  erb :game        
 
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  player = calculate(session[:player_cards])
  
  if player == BLACKJACK_AMOUNT 
    winner!("#{session['username']} hit blackjack!")
  elsif player > BLACKJACK_AMOUNT 
    loser!("#{session['username']} busted!")
  end
  erb :game  
end

post '/game/player/stay' do
  @success = "#{session['username']} chose to stay."
  @show_hit_or_hit_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
  @show_hit_or_hit_stay_buttons = false
  dealer = calculate(session[:dealers_cards])

  if dealer == BLACKJACK_AMOUNT 
    loser!("Sorry the dealer hit blackjack!")
  elsif dealer < DEALER_MIN_HIT
    @show_dealer_hit_button = true
  elsif dealer > BLACKJACK_AMOUNT 
    winner!("The Dealer busted!")
  elsif dealer >= DEALER_MIN_HIT
    redirect'/game/winner'
  end 
  erb :game 
end

get '/game/winner' do
  player = calculate(session[:player_cards])
  dealer = calculate(session[:dealers_cards])
  @show_hit_or_hit_stay_buttons = false
  if dealer > player
    loser!("#{session[:username]} stayed at #{player}, and the dealer stayed at #{dealer}.")
  elsif dealer < player
    winner!("#{session[:username]} stayed at #{player}, and the dealer stayed at #{dealer}.")
  elsif dealer == player 
    winner!("Both #{session[:username]} stayed at #{player}, and the dealer stayed at #{dealer}.")
  end
  erb :game  
end

post '/game/dealer/hit' do
  session[:dealers_cards] << session[:deck].pop
  redirect '/game/dealer' 
end

get '/game_over' do
  erb :game_over
end



