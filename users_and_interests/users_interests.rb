#create a Gemfile with the requirements
#enable Gemfile.lock using bundle install


require 'yaml'
require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

#this will return the filename as a Ruby object
before do 
  @users = YAML.load_file("users.yaml") #these are array values of te content of the yaml file
end

get "/" do
  redirect "/users" 
end

get "/users" do
  erb :users
end

get "/:user_name" do
  @user_name = params[:user_name].to_sym
  @email = @users[@user_name][:email]
  @interests = @users[@user_name][:interests]

  erb :user
end

helpers do 
  def count_interests(users)
    users.reduce(0) do |sum, (name, user)|
      sum + user[:interests].size
    end
  end
end
