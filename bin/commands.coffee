require 'colors'

series = (tasks, callback) ->
  tasks = tasks.slice 0
  next = (cb) ->
    return cb() if tasks.length is 0
    task = tasks.shift()
    task -> next cb
  result = (cb) -> next cb
  result(callback) if callback?
  result

module.exports =
  status: (ducke) ->
    ducke.ping (err, isUp) ->
      if err? or !isUp
        console.error()
        console.error '  docker is down'.red
        console.error()
        process.exit 1
      else
        ducke.ps (err, results) ->
          if err? or results.length is 0
            console.error()
            console.error '  There are no docker containers on this system'.magenta
            console.error()
          else
            ess = (num, s, p) -> if num is 1 then s else p
            running = results
              .filter (d) -> d.inspect.State.Running
              .length
            stopped = results.length - running
            console.error()
            console.error "  There #{ess running, 'is', 'are'} #{running.toString().green} running container#{ess running, '', 's'} and #{stopped.toString().red} stopped container#{ess stopped, '', 's'}"
            console.error()
          process.exit 1
  
  ps: (ducke) ->
    ducke.ps (err, results) ->
      if err?
        console.error err
        process.exit 1
      
      if results.length is 0
        console.error()
        console.error '  There are no docker containers on this system'.magenta
        console.error()
        return
      
      console.log()
      for result in results
        status = if result.inspect.State.Running
          result.inspect.NetworkSettings.IPAddress.toString().blue
        else
          'stopped'.red
        status += ' ' while status.length < 26
        
        name = result.container.Names[0][1..]
        image = result.inspect.Config.Image
        
        console.log "  #{status} #{name} (#{image})"
      console.log()
  
  inspect: (ducke, containers) ->
    tasks = []
    results = []
    
    for id in containers
      do (id) ->
        tasks.push (cb) ->
          ducke
            .container id
            .inspect (err, inspect) ->
              if err?
                console.error err
                process.exit 1
              results.push inspect
              cb()
    
    series tasks, -> console.log JSON.stringify results, null, 2
  
  logs: (ducke, containers) ->
    for id in containers
      ducke
        .container id
        .logs (err, stream) ->
          if err?
            console.error err
            process.exit 1
          stream.pipe process.stdout
  
  run: (ducke, image, cmd) ->
    run = (err, id) ->
      if err?
        console.error err
        process.exit 1
      
      ducke
        .container id
        .inspect (err, inspect) ->
          if err?
            console.error err
            process.exit 1
          
          name = inspect.Name[1..]
          image = inspect.Config.Image
          
          console.log()
          console.log "  #{'running'.green} #{name} (#{image})"
          console.log()
      
    fin = (err, code) ->
      if err?
        console.error err
        process.exit 1
      process.exit code
    
    cmd = ['bash'] if !cmd? or cmd.length is 0
    ducke
      .image image
      .run cmd, process.stdin, process.stdout, process.stderr, run, fin

  up: (ducke, image, cmd) ->
    ducke
      .image image
      .up null, cmd, (err, id) ->
        if err?
          console.error err
          process.exit 1
        ducke
          .container id
          .inspect (err, inspect) ->
            if err?
              console.error err
              process.exit 1
            
            name = inspect.Name[1..]
            image = inspect.Config.Image
            
            console.log()
            console.log "  #{'running'.green} #{name} (#{image})"
            console.log()
  
  exec: (ducke, container) ->
    ducke
      .container container
      .inspect (err, inspect) ->
        if err?
          console.error err
          process.exit 1
        
        name = inspect.Name[1..]
        image = inspect.Config.Image
        
        console.log()
        console.log "  #{'exec'.green} #{name} (#{image})"
        console.log()
        
        ducke
          .container container
          .exec process.stdin, process.stdout, process.stderr, (err, code) ->
            if err?
              console.error err
              process.exit 1
            process.exit code
  
  stop: (ducke, containers) ->
    tasks = []
    
    console.log()
    for id in containers
      do (id) ->
        tasks.push (cb) ->
          ducke
            .container id
            .stop (err) ->
              if err?
                if err.statusCode is 404
                  console.error "  #{id.red} is an unknown container"
                  return cb()
                
                if err.statusCode is 304
                  console.error "  #{id.red} has already been stopped"
                  return cb()
                
                if err.statusCode is 500
                  console.error "  could not stop #{id.red}"
                  return cb()
                
                console.error err
                console.error JSON.stringify err
                process.exit 1
              
              console.log "  #{'stopped'.green} #{id}"
              cb()
    
    series tasks, -> console.log()
  
  rm: (ducke, containers) ->
    tasks = []
    
    console.log()
    for id in containers
      do (id) ->
        tasks.push (cb) ->
          ducke
            .container id
            .rm (err) ->
              if err?
                if err.statusCode is 404
                  console.error "  #{id.red} is an unknown container"
                  return cb()
                
                if err.statusCode is 500
                  console.error "  could not delete #{id.red}"
                  return cb()
                
                console.error err
                console.error JSON.stringify err
                process.exit 1
              
              console.log "  #{'deleted'.green} #{id}"
              cb()
    
    series tasks, -> console.log()
  
  kill: (ducke, containers) ->
    tasks = []
    
    console.log()
    for id in containers
      do (id) ->
        tasks.push (cb) ->
          ducke
            .container id
            .kill (err) ->
              if err?
                if err.statusCode is 404
                  console.error "  #{id.red} is an unknown container"
                  return cb()
                
                if err.statusCode is 500
                  console.error "  could not send SIGTERM to #{id.red}"
                  return cb()
                
                console.error err
                console.error JSON.stringify err
                process.exit 1
              
              console.log "  #{'killed'.green} #{id}"
              cb()
    
    series tasks, -> console.log()