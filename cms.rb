require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
require 'yaml'
require 'bcrypt'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def render_markdown(txt)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(txt)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    erb render_markdown(content)
  end
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/users.yml", __FILE__)
  else
    File.expand_path("../public/users.yml", __FILE__)
  end
  YAML.load_file(credentials_path)
end

def valid_credentials?(username, password)
  credentials = load_user_credentials

  if credentials.key?(username)
    pw = BCrypt::Password.create(credentials[username])

    bcrypt_password = BCrypt::Password.new(pw)
    bcrypt_password == password
  else
    false
  end
end

def user_signed_in?
  session.key?(:username)
end

def require_signed_in_user
  unless user_signed_in?
    session[:message] = "You must be signed in to do that."
    redirect "/"
  end
end

get "/" do
    pattern = File.join(data_path, "*")
    @files = Dir.glob(pattern).map do |path|
        File.basename(path)
      end
    erb :index
end

get "/new" do
  require_signed_in_user

  erb :new
end

post "/create" do
require_signed_in_user

  filename = params[:filename].to_s

  if filename.size == 0
    session[:message] = "Your file must have a name"
    status 442
    erb :new
  else
    file_path = File.join(data_path, filename)

    File.write(file_path, "")
    session[:message] = "#{params[:filename]} has been created."

    redirect "/"
  end
end

get "/:file_name" do
  path = File.join(data_path, params[:file_name])

    if File.exist?(path)
      load_file_content(path)
    else
      session[:message] = "#{params[:file_name]} does not exist"
      redirect '/'
    end
  end

get "/:file_name/edit" do
  require_signed_in_user

  path = File.join(data_path, params[:file_name])

  @file_name = params[:file_name]
  @content = File.read(path)

  erb :edit
end

post "/:file_name" do
  require_signed_in_user

  path = File.join(data_path, params[:file_name])

  File.write(path, params[:content])

  session[:message] = "The text for #{params[:file_name]} was saved successfully"
  redirect "/"
end

post "/delete/:file_name" do
  require_signed_in_user
  path = File.join(data_path, params[:file_name])

  FileUtils.rm(path)

  session[:message] = "#{params[:file_name]} was deleted"
  redirect "/"
end

get "/users/signin" do
  erb :signin
end

post "/users/signin" do
  username = params[:username]

    if valid_credentials?(username, params[:password])
      session[:username] = username
      session[:message] = "Welcome!"
      redirect "/"
    else
      session[:message] = "Invalid Credentials"
      status 422
      erb :signin
    end
  end

post "/users/signout" do
  session.delete(:username)
  session[:message] ="You have been signed out."
  redirect "/"
end
