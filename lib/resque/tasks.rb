# require 'resque/tasks'
# will give you the resque tasks

namespace :resque do
  task :setup

  desc "Start a Resque worker"
  task :work => :setup do
    require 'resque'

    worker = nil
    queues = (ENV['QUEUES'] || ENV['QUEUE']).to_s.split(',')

    begin
      worker = Resque::Worker.new(*queues)
      worker.verbose = ENV['LOGGING'] || ENV['VERBOSE']
      worker.very_verbose = ENV['VVERBOSE']
    rescue Resque::NoQueueError
      abort "set QUEUE env var, e.g. $ QUEUE=critical,high rake resque:work"
    end

    worker.log "Starting worker #{worker}"

    # Use blocking pop if Redis version >= 1.3.1
    redis_version = Resque.redis.info["redis_version"]
    can_block     = redis_version && redis_version.to_f >= 1.3 && redis_version.split(".").last.to_i != 0

    worker.work(:blocking => can_block, :interval => ENV['INTERVAL'] || 5) # interval, will block
  end

  desc "Start multiple Resque workers. Should only be used in dev mode."
  task :workers do
    threads = []

    ENV['COUNT'].to_i.times do
      threads << Thread.new do
        system "rake resque:work"
      end
    end

    threads.each { |thread| thread.join }
  end
end
