# virtual server

## debian 8

```
apt-get update
apt-get install postgresql-9.4 postgresql-client-9.4 # database
apt-get install emacs24-nox tmux git # general development environment
apt-get install build-essential
apt-get install graphicsmagick
```

## basic security

In the file `/etc/ssh/sshd_config` set `PermitRootLogin no`.

```
/etc/init.d/ssh restart
```

## Install erlang + elixir 

```
wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && sudo dpkg -i erlang-solutions_1.0_all.deb
apt-get update
apt-get install esl-erlang
apt-get install elixir
```


## Installing the database

```
su postgres
createuser heimchen -P -d
createdb -h 127.0.0.1 -U heimchen
```

## installing phoenix

as some non-privileged user

```
mix local.hex
mix archive.install https://github.com/phoenixframework/archives/raw/master/phoenix_new.ez
```


## new git home

```
mkdir heimchen
```


## dependencies and db setup

```
mix deps.get
mix ecto.migrate
```


## starting the application


```
./iex.sh
```
