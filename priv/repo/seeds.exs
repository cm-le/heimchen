# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Heimchen.Repo.insert!(%Heimchen.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Heimchen.Repo

Repo.insert!(%Heimchen.Itemtype{
			sid: "THING",
			name: "Gegenstand",
			has_room: true
})

Repo.insert!(%Heimchen.Itemtype{
			sid: "PHOTO",
			name: "Bild",
			has_room: true
})

Repo.insert!(%Heimchen.Itemtype{
			sid: "FILM",
			name: "Film",
			has_room: true
})

Repo.insert!(%Heimchen.Itemtype{
			sid: "EVENT",
			name: "Ereignis",
			has_room: false
})


Repo.insert!(%Heimchen.Room{
			name: "Archiv",
})

Repo.insert!(%Heimchen.Room{
			name: "Keller",
})

Repo.insert!(%Heimchen.Room{
			name: "Ausstellungsraum",
})
