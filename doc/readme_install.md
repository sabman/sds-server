
Instructions for Installing the application on a clean Debian based / Ubuntu (10.04, 11.10, 12.04) server
=============

Introduction
------------

These instructions allow you fully remotely provision a new server with all the libraries, database, and webserver. It will
also deploy the SDS application to this remote server and start it for you. It will install:

- postgresql
- Ruby + all the gems and associated libraries
- Nginx webserver
- Unicorn (to run the Rails app on the server)

If you are familiar with deploying rails applications, or already have a server set up to run a rails application,
then you can still use the usual capistrano deploy calls - you may need to do some configuring, however.

Client Requirements
-------------
You don't need all the things to run the application on the computer, however you should have the following at least:

Requirements to install from client
-------------
- Git, Ruby 1.8.7
- rubygems, capistrano, bundler:

Example: a ubuntu LTS 12-04 desktop
- sudo apt-get install rubygems
- sudo gem install capistrano --version=2.13.5
- sudo gem install bundler


Server Requirements
-------------

- On the server, it should be a new empty server, running a new debian based system. Ideally an ubuntu server.
- The firewall should be configured to allow port 80 etc.
- It should have a user which is configured to have sudo access, and is able to ssh in.
- You should know the username and password of this user. You will be promted by the scripts for the password at times.

- Get the source
` git clone git://github.com/hotosm/sds-server.git `

Pre configuration.
-------------

You must do some configuration

- in config/deploy.rb
- change the line that says
- ` server "192.168.15.142" `
- change it to the IP address, or the domain of your server
- ie. ` server "sds.geothings.net" `

- Find the line that says
- `set :user, "tim" `
- change it to the username for the user you set up on your new server

###Optional - Database configuration:###
The setup process creates a postgres database and user and sets the password based on what you give the prompt.
You can overwrite this by uploading the database.yml to app_path/shared/config directory
After this run ` cap deploy ` again

###Optional - Change default admin logins:###
Edit deploy.rb and find the line saying
` db:create_admin[Admin,Adminson,admin@example.com,changemeplease] `

and change the line according to ` db:create_admin[firstname,lastname,email,password] `

###Optional - Change OSM API urls configuration:###
On the server, edit the file at ` app_path/shared/config/app_config.yml`



Get deploying!
-------------

1.  `cap deploy:install` - This installs postgres, unicorn, nginx, ruby etc
2.  `cap deploy:setup`
    during this step prompted for the postgresql user's password. This sets up the database, links for capistrano, sets up directories, etc
3.  `cap deploy:cold`
    This deploys the actual application

Go to server in browser

4 - Create admin user
`cap deploy:create_admin`


Trouble?
-------------

if server not working try:

- `cap nginx:setup`
- `cap unicorn:start`

Look in logs

- app_path/shared/logs/unicorn.log
- app_path/shared/logs/production.log