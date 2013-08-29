require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'


set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17
INITIAL_POT_AMOUNT = 1000

helpers do
  def calculate(cards)
    face_values = cards.map{|e| e[1]}

      total = 0
      face_values.each do |value|
        if value == "A"
          total += 11
        elsif (2..10).include?(value.to_i) 
          total += value.to_i
        else 
          total += 10
        end
      end

      #Aces are systematic
      face_values.select { |e| e == 'A'}.count.times do
          break if total <= BLACKJACK_AMOUNT
          total -= 10 
      end

      total 
  end

  def card_image(card) #['Spades', '9']
    
    suit = case card[0]
      when 'Spades' then 'spades'
      when 'Hearts' then 'hearts'
      when 'Clubs' then 'clubs'
      when 'Diamonds' then 'diamonds'
    end

    value = card[1]
      if ['A', 'K', 'Q', 'J'].include?(value)

      value = case card[1]
        when 'A' then 'ace'
        when 'K' then 'king'
        when 'Q' then 'queen'
        when 'J' then 'jack'
      end
    end
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  def winner!(msg)
    @play_again = true
    @show_buttons = false
    session[:player_pot] = session[:player_pot] + session[:player_bet]
    @winner = "<strong>#{session[:new_player]} wins!</strong> #{msg}"
  end

  def loser!(msg)
    @play_again = true
    @show_buttons = false
    session[:player_pot] = session[:player_pot] - session[:player_bet]
    @loser = "<strong>#{session[:new_player]} loses!</strong> #{msg}"
  end

  def tie!(msg)
    @play_again = true
    @show_buttons = false
    @tied = "<strong>#{session[:new_player]} and the dealer have tied!</strong> #{msg}"
  end
end

before do
  @show_buttons = true
end

get '/' do
  if session[:new_player]
    redirect '/game'  
  else 
    redirect '/new_player'
  end
end

get '/new_player' do
  session[:player_pot] = INITIAL_POT_AMOUNT
  erb :new_player 
end

post '/new_player' do
  
  if params[:new_player].empty?
    @error = "Please enter a name to play the game."
    halt erb(:new_player)
  end

  session[:new_player] = params[:new_player]
  redirect '/bet'
end

get '/bet' do
  session[:player_bet] = nil
  erb :bet 
end

post '/bet' do
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "Must make a bet."
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:player_pot]
    @error = "Bet amount cannot be greater than what you have ($#{session[:player_pot]})"
    halt erb(:bet)
  else 
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end
end
      

get '/game' do
  session[:turn] = session[:new_player]

  #deck 
  suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades']
  values = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
  session[:deck] = suits.product(values).shuffle!
  
  
#dealer cards
session[:dealer_cards] = []

#player cards
session[:player_cards] = []

#deal cards

session[:player_cards] << session[:deck].pop
session[:dealer_cards] << session[:deck].pop
session[:player_cards] << session[:deck].pop
session[:dealer_cards] << session[:deck].pop

  erb :game
end


post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = calculate(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("Blackjack #{session[:new_player]} hit blackjack.")
  elsif calculate(session[:player_cards]) > BLACKJACK_AMOUNT
    loser!("Busted!!! #{session[:new_player]} has busted with #{player_total}.")
  end

  erb :game, layout: false 
end

post '/game/player/stay' do
  @success = "#{session[:new_player]} has chosen to stay."
  @show_buttons = false 
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
  @show_buttons = false

  dealer_total = calculate(session[:dealer_cards])

  if dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer has Blackjack! #{session[:new_player]} has lost!")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("#{session[:new_player]}'s #{session[:player_total]} beat the dealer's #{session[:dealer_total]}.")
  elsif dealer_total >= DEALER_MIN_HIT
    redirect '/game/compare'
  else
    @dealer_hit = true 
  end

  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_buttons = false

  player_total = calculate(session[:player_cards])
  dealer_total = calculate(session[:dealer_cards])

  if player_total < dealer_total
    loser!("#{session[:new_player]}'s hand is lower than the dealer's hand.")
  elsif player_total > dealer_total
    winner!("#{session[:new_player]}'s hand is better than the dealer's hand.")
  else
    tie!("Both stayed at #{player_total}.")
  end

  erb :game 
end

get '/game_over' do
  erb :game_over
end