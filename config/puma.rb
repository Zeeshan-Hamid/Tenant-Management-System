# config/puma.rb
# Set the number of workers. This should generally be set to the number of CPU cores available.
workers Integer(ENV['WEB_CONCURRENCY'] || 2)
# Set the number of threads per worker.
threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
threads threads_count, threads_count
# Set the environment (this should be 'production', 'development', or 'test').
environment ENV['RAILS_ENV'] || 'production'
# Bind to a Unix socket.
bind "unix:///home/ubuntu/project/kiraaya/tmp/sockets/puma.sock"
# Set the path for the PID file.
pidfile ENV.fetch('PIDFILE') { 'tmp/pids/puma.pid' }
# Set the path for the state file (this is used by Puma for process management).
state_path 'tmp/pids/puma.state'
# Enable the preload_app! feature for performance in production.
preload_app!
# On worker boot, re-establish ActiveRecord connections.
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end
# Logging configuration (optional).
stdout_redirect 'log/puma.stdout.log', 'log/puma.stderr.log', true
# Worker timeout (in seconds).
worker_timeout 60