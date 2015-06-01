namespace :queue do

  desc "Queue stale works"
  task :stale => :environment do |_, args|
    if args.extras.empty?
      agents = Agent.active
    else
      agents = Agent.active.where("name in (?)", args.extras)
    end

    if agents.empty?
      puts "No active agent found."
      exit
    end

    begin
      start_date = Date.parse(ENV['START_DATE']) if ENV['START_DATE']
      end_date = Date.parse(ENV['END_DATE']) if ENV['END_DATE']
    rescue => e
      # raises error if invalid date supplied
      puts "Error: #{e.message}"
      exit
    end
    puts "Queueing stale works published from #{start_date} to #{end_date}." if start_date && end_date

    agents.each do |agent|
      count = agent.queue_all_works(start_date: start_date, end_date: end_date)
      puts "#{count} stale works for agent #{agent.title} have been queued."
    end
  end

  desc "Queue all works"
  task :all => :environment do |_, args|
    if args.extras.empty?
      agents = Agent.active
    else
      agents = Agent.active.where("name in (?)", args.extras)
    end

    if agents.empty?
      puts "No active agent found."
      exit
    end

    begin
      start_date = Date.parse(ENV['START_DATE']) if ENV['START_DATE']
      end_date = Date.parse(ENV['END_DATE']) if ENV['END_DATE']
    rescue => e
      # raises error if invalid date supplied
      puts "Error: #{e.message}"
      exit
    end
    puts "Queueing all works published from #{start_date} to #{end_date}." if start_date && end_date

    agents.each do |agent|
      count = agent.queue_all_works(all: true, start_date: start_date, end_date: end_date)
      puts "#{count} works for agent #{agent.title} have been queued."
    end
  end

  desc "Queue work with given pid"
  task :one, [:pid] => :environment do |_, args|
    if args.pid.nil?
      puts "pid is required"
      exit
    end

    work = Work.where(pid: args.pid).first
    if work.nil?
      puts "Work with pid #{args.pid} does not exist"
      exit
    end

    if args.extras.empty?
      agents = Agent.active
    else
      agents = Agent.active.where("name in (?)", args.extras)
    end

    if agents.empty?
      puts "No active agent found."
      exit
    end

    agents.each do |agent|
      task = Task.where(work_id: work.id, agent_id: agent.id).first

      if task.nil?
        puts "Task for work with pid #{args.pid} and agent with name #{args.agent} does not exist"
        exit
      end

      agent.queue_work_jobs([task.id], priority: 2)
      puts "Job for pid #{work.pid} and agent #{agent.title} has been queued."
    end
  end

  task :default => :stale

end
