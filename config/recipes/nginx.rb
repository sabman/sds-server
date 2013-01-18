namespace :nginx do
  desc "Install latest stable release of nginx"
  task :install, :roles => :web do
     lsb_v = lsb_release.strip
     puts lsb_v.inspect
     puts lsb_v == "12.04"
     if lsb_v  == "12.04" || lsb_v  == "12.10"
      run "#{sudo} add-apt-repository -y ppa:nginx/stable"
    else
      run "#{sudo} add-apt-repository  ppa:nginx/stable"
    end
    run "#{sudo} apt-get -y update"
    run "#{sudo} apt-get -y install nginx"
  end
  after "deploy:install", "nginx:install"

  desc "Setup nginx configuration for this application"
  task :setup, :roles => :web do
    template "nginx_unicorn.erb", "/tmp/nginx_conf"
    run "#{sudo} mv /tmp/nginx_conf /etc/nginx/sites-enabled/#{application}"
    run "#{sudo} rm -f /etc/nginx/sites-enabled/default"
    restart
  end
  after "deploy:setup", "nginx:setup"
  
  %w[start stop restart].each do |command|
    desc "#{command} nginx"
    task command, :roles => :web do
      run "#{sudo} service nginx #{command}"
    end
  end
end
