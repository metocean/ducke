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
    ducke.ps (err, statuses) ->
      if err?
        console.error err
        process.exit 1
      
      if statuses.length is 0
        console.error()
        console.error '  There are no docker containers on this system'.magenta
        console.error()
        return
      
      console.log()
      for status in statuses
        output = if status.inspect.State.Running
          status.inspect.NetworkSettings.IPAddress.toString().blue
        else
          'stopped'.red
        output += ' ' while output.length < 26
        
        name = status.container.Names[0][1..]
        image = status.inspect.Config.Image
        
        console.log "  #{output} #{name} (#{image})"
      console.log()
  
  purge: (ducke) ->
    ducke.ps (err, statuses) ->
      if err?
        console.error err
        process.exit 1
      
      if statuses.length is 0
        console.error()
        console.error '  There are no docker containers on this system'.magenta
        console.error()
        return
      
      console.log()
      statuses = statuses.filter (status) ->
        return no if status.inspect.State.Running
        finishedAt = new Date status.inspect.State.FinishedAt
        now = new Date()
        oneweek = 7 * 24 * 60 * 60 * 1000
        return no if now - finishedAt < oneweek
        yes
      
      if statuses.length is 0
        console.log '  No containers older than one week'.magenta
        console.log()
        return
      
      tasks = []
      for status in statuses
        do (status) ->
          tasks.push (cb) ->
            name = status.container.Names[0][1..]
            image = status.inspect.Config.Image
            output = "  #{name} (#{image})"
            output += ' ' while output.length < 26
            
            console.log "  #{output} #{'deleted'.red}"
            cb()
        
      series tasks, ->
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
  
  exec: (ducke, container, cmd) ->
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
        
        cmd = ['bash'] if !cmd? or cmd.length is 0
        ducke
          .container container
          .exec cmd, process.stdin, process.stdout, process.stderr, (err, code) ->
            if err?
              console.error err
              process.exit 1
            process.exit code
  
  build: (ducke, id) ->
    ducke
      .image id
      .build process.cwd(), console.log, (err) ->
        if err?
          console.error err
          process.exit 1
  
  rebuild: (ducke, id) ->
    ducke
      .image id
      .rebuild process.cwd(), console.log, (err) ->
        if err?
          console.error err
          process.exit 1
  
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
  
  ls: (ducke) ->
    nest = (nodes, indent) ->
      for node in nodes
        # should we skip?
        if node.image.RepoTags[0] is '<none>:<none>' and node.children? and node.children.length > 0
          nest node.children, indent
          continue
        
        space = ''
        space += '  ' while space.length < 2 *indent
        
        output = "  #{space}#{node.image.Id.substr 0, 12}"
        if node.image.RepoTags.length is 1 and node.image.RepoTags[0] is '<none>:<none>'
          if node.children.length is 0
            output += ' orphan'.magenta
          
        else
          for tag in node.image.RepoTags
            output += " #{tag}".cyan
        
        console.log output
        if node.children?
          nest node.children, indent + 1
    
    ducke.ls (err, result) ->
      if err?
        console.error err
        console.error JSON.stringify err
        process.exit 1
      
      console.log()
      nest result.graph, 0
      console.log()
  
  orphans: (ducke) ->
    ducke.ls (err, result) ->
      if err?
        console.error err
        console.error JSON.stringify err
        process.exit 1
      
      orphans = []
      
      console.log()
      for node in result.images
        if node.image.RepoTags.length is 1 and node.image.RepoTags[0] is '<none>:<none>' and node.children.length is 0
            orphans.push node
      
      if orphans.length is 0
        console.log '  There are no orphaned images on this system.'.magenta
      else
        for node in orphans
          console.log "#{node.image.Id.substr 0, 12}"
      console.log()
  
  rmi: (ducke, images) ->
    tasks = []
    
    console.log()
    for id in images
      do (id) ->
        tasks.push (cb) ->
          ducke
            .image id
            .rm (err) ->
              if err?
                if err.statusCode is 404
                  console.error "  #{id.red} is an unknown image"
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