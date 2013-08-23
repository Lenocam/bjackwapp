require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'pry'

set :sessions, true

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
        break if total <= 21
        total -= 10 
    end

    total
  end  
end

before do
  @show_buttons = true
end

get '/' do
  if session[:new_player]
  
  else 
    redirect '/new_player'
  end
end


get '/new_player' do
  erb :new_player
end

post '/new_player' do
  session[:new_player] = params[:new_player]
  redirect '/game'
end

get '/game' do

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
  
  if calculate(session[:player_cards]) > 21
    @error = "You lose. This hand is busted."
    @show_buttons = false

  elsif calculate(session[:player_cards]) == calculate(session[:dealer_cards])
    @tied = "A Draw has occured. No money exchanges hands."
    @show_buttons = false
  end

  erb :game
end

post '/game/player/stay' do
  @success = "Oh, Shit!"
  @show_buttons = false


  erb :game
end