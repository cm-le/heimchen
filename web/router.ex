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
		get  "/keyword/keywords", KeywordController, :keywords
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
		get  "/person/delete_keyword/:id", PersonController, :delete_keyword
		get  "/person/search/:name", PersonController, :search

		get  "/image", ImageController, :index
		get  "/image/new", ImageController, :new
		post "/image/create", ImageController, :create
		get  "/image/image/:id/:size", ImageController, :image
		get  "/image/show/:id", ImageController, :show
		put  "/image/update/:id", ImageController, :update
		get  "/image/clipboard", ImageController, :clipboard
		get  "/image/clipboard_mark", ImageController, :clipboard_mark
		get  "/image/clipboard_empty", ImageController, :clipboard_empty
		get  "/image/add_and_show_clipboard/:id", ImageController, :add_and_show_clipboard
		get  "/image/mark/:what/:id", ImageController, :mark
		get  "/image/marklist", ImageController, :marklist
		get  "/image/del_imagetag/:id", ImageController, :del_imagetag
		get  "/image/edit_imagetag/:id", ImageController, :edit_imagetag
		post "/image/update_imagetag/:id", ImageController, :update_imagetag

		get  "/item/new", ItemController, :new
		post "/item/create", ItemController, :create
		get  "/item/show/:id", ItemController, :show
		get  "/item/edit/:id", ItemController, :edit
		get  "/item/add_keyword/:id", ItemController, :add_keyword # sorry for making this "get"
		get  "/item/delete_keyword/:item_id/:keyword_id", ItemController, :delete_keyword # ~
		post "/item/create", ItemController, :create
		put  "/item/update/:id", ItemController, :update

		
  end

  # Other scopes may use custom stacks.
  # scope "/api", Heimchen do
  #   pipe_through :api
  # end
end
