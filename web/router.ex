defmodule Heimchen.Router do
  use Heimchen.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
		plug Heimchen.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Heimchen do
    pipe_through :browser # Use the default browser stack

    get  "/", SessionController, :new
		get  "/session/new", SessionController, :new
		post "/session/create", SessionController, :create
		get  "/session/delete", SessionController, :delete
		
		get  "/user", UserController, :index
		get  "/user/show/:id", UserController, :show
		get  "/user/new", UserController, :new
		post "/user/create", UserController, :create
		put  "/user/update/:id", UserController, :update
		put  "/user/changepw/:id", UserController, :changepw

		get  "/item", ItemController, :index

		get  "/keyword", KeywordController, :index
		get  "/keyword/show/:id", KeywordController, :show
		get  "/keyword/new", KeywordController, :new
		post "/keyword/create", KeywordController, :create
		put  "/keyword/update/:id", KeywordController, :update

		get  "/person", PersonController, :index
		get  "/person/show/:id", PersonController, :show
		get  "/person/new", PersonController, :new
		get  "/person/edit/:id", PersonController, :edit
		post "/person/create", PersonController, :create
		put  "/person/update/:id", PersonController, :update
		get  "/person/add_keyword/:id", PersonController, :add_keyword # sorry for making this "get"
		get  "/person/keyword_select", PersonController, :keyword_select
		get  "/person/delete_keyword/:id", PersonController, :delete_keyword
		get  "/person/search/:name", PersonController, :search
		
  end

  # Other scopes may use custom stacks.
  # scope "/api", Heimchen do
  #   pipe_through :api
  # end
end
