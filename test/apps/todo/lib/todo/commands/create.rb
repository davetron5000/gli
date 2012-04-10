desc "Create a new task or context"
command [:create,:new] do |c|
  c.desc "Make a new task"
  c.command :tasks do |tasks|
    tasks.action do |global,options,args|
      puts "#{args}"
    end
  end

  c.desc "Make a new context"
  c.command :contexts do |contexts|
    contexts.action do |global,options,args|
      puts "#{args}"
    end
  end
end

