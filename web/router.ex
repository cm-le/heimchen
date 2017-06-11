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
		get  "/keyword/edit/:id", KeywordController, :edit
		post "/keyword/create", KeywordController, :create
		put  "/keyword/update/:id", KeywordController, :update
		get  "/keyword/add_keyword/:id/:what", KeywordController, :add_keyword
		get  "/keyword/delete_keyword/:id/:what/:keyword_id", KeywordController, :delete_keyword

		get  "/person", PersonController, :index
		get  "/person/show/:id", PersonController, :show
		get  "/person/new", PersonController, :new
		get  "/person/edit/:id", PersonController, :edit
		post "/person/create", PersonController, :create
		put  "/person/update/:id", PersonController, :update
		get  "/person/delete_keyword/:person_id/:keyword_id", PersonController, :delete_keyword
		get  "/person/search/:name", PersonController, :search
		post "/person/add_place", PersonController, :add_place
		get  "/person/mark_person/:id", PersonController, :mark_person
		get  "/person/merge_person/:id/:doit", PersonController, :merge_person
		get  "/person/delete_place/:id", PersonController, :delete_place
		post "/person/add_relative", PersonController, :add_relative
		get  "/person/del_relative/:id/:person_id", PersonController, :del_relative


		get  "/place", PlaceController, :index
		get  "/place/show/:id", PlaceController, :show
		get  "/place/new", PlaceController, :new
		get  "/place/edit/:id", PlaceController, :edit
		post "/place/create", PlaceController, :create
		put  "/place/update/:id", PlaceController, :update
		get  "/place/getlatlong/:id", PlaceController, :getlatlong
		get  "/place/delete_keyword/:place_id/:keyword_id", PlaceController, :delete_keyword
		get  "/place/search/:name", PlaceController, :search
		get  "/place/mark_place/:id", PlaceController, :mark_place
		get  "/place/merge_place/:id/:doit", PlaceController, :merge_place
		get  "/place/allplaces", PlaceController, :allplaces

		
		get  "/image", ImageController, :index
  	get  "/image/untagged", ImageController, :untagged
		get  "/image/new", ImageController, :new
		post "/image/create", ImageController, :create
		get  "/image/image/:id/:size", ImageController, :image
   	get  "/image/attachment/:id", ImageController, :attachment
		get  "/image/show/:id", ImageController, :show
		put  "/image/update/:id", ImageController, :update
		get  "/image/clipboard", ImageController, :clipboard
		get  "/image/clipboard_mark", ImageController, :clipboard_mark
		get  "/image/clipboard_empty", ImageController, :clipboard_empty
		get  "/image/add_and_show_clipboard/:id", ImageController, :add_and_show_clipboard
		get  "/image/mark/:what/:id", ImageController, :mark
		get  "/image/marklist", ImageController, :marklist
		get  "/image/del_imagetag/:id", ImageController, :del_imagetag
		get  "/image/create_imagetag/:id/:what", ImageController, :create_imagetag
		get  "/image/edit_imagetag/:id/:what/:what_id", ImageController, :edit_imagetag
		get  "/image/rotate/:id", ImageController, :rotate
		get  "/image/delete_all", ImageController, :delete_all
		post "/image/update_imagetag/:id", ImageController, :update_imagetag

		get  "/item/new", ItemController, :new
		post "/item/create", ItemController, :create
		get  "/item/show/:id", ItemController, :show
		get  "/item/edit/:id", ItemController, :edit
		get  "/item/delete_keyword/:item_id/:keyword_id", ItemController, :delete_keyword # ~
		post "/item/create", ItemController, :create
		put  "/item/update/:id", ItemController, :update
		post "/item/add_place", ItemController, :add_place
		get  "/item/delete_place/:id", ItemController, :delete_place
		get  "/item/mark_item/:id", ItemController, :mark_item
		get  "/item/merge_item/:id/:doit", ItemController, :merge_item


		get  "/search/index/:id", SearchController, :index
		get  "/search/personlist", SearchController, :personlist
  end

  # Other scopes may use custom stacks.
  # scope "/api", Heimchen do
  #   pipe_through :api
  # end
end
