command [:make] do |c|
  c.desc "Show long form"
  c.flag [:l,:long]

  c.desc 'make a new task'
  c.command :task do |task|
    task.desc 'make the task a long task'
    task.flag [:l,:long]

    task.action do |g,o,a|
      puts 'new task'
      puts a.join(',')
      puts o[:long]
    end

    desc 'make a bug'
    task.command :bug do |bug|
      bug.desc 'make this bug in the legacy system'
      bug.flag [:l,:legacy]

      bug.action do |g,o,a|
        puts 'new task bug'
        puts a.join(',')
        puts o[:legacy]
        puts o[:long]
        puts o[:l]
        puts o[GLI::Command::PARENT][:l]
        puts o[GLI::Command::PARENT][:long]
        puts o[GLI::Command::PARENT][:legacy]
        puts o[GLI::Command::PARENT][GLI::Command::PARENT][:l]
        puts o[GLI::Command::PARENT][GLI::Command::PARENT][:long]
        puts o[GLI::Command::PARENT][GLI::Command::PARENT][:legacy]
      end
    end
  end

  c.desc 'make a new context'
  c.command :context do |context|
    context.desc 'make the context a local context'
    context.flag [:l,:local]

    context.action do |g,o,a|
      puts 'new context'
      puts a.join(',')
      puts o[:local]
      puts o[:long]
      puts o[:l]
    end
  end

end
