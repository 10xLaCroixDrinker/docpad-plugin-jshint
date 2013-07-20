# Export Plugin
module.exports = (BasePlugin) ->
  # Requires
  {TaskGroup} = require('taskgroup')
  jshint = require('jshint').JSHINT
  colors = require('colors')

  # Define Plugin
  class JSHintPlugin extends BasePlugin
    # Plugin name
    name: 'jshint'

    # Plugin config
    config:
      ignorePaths: [ ]
      globals: { }       # additional predefined global variables
      hintOptions: { }

    # Render After
    # Called just just after we've rendered all the files.
    renderAfter: ({collection}) ->
      config = @config
      ignoredPaths = [ ]
      if config.hintOptions.maxerr
        maxErrors = config.hintOptions.maxerr
      else
        maxErrors = 50
 
      # Normalize ignored paths
      config.ignorePaths.map (path, i) =>
        path = path.toString()
        if path.charAt(0) is '/'
          path.slice(1)
        if path.charAt(path.length - 1) isnt '/'
          path = path + '/'
        ignoredPaths.push(path)

      collection.each (item) ->
        file = item.attributes
        tooManyErrors = false
        
        # Find JS files
        if file.extension is 'js'
          
          # Skip files in ignored paths
          for path in ignoredPaths
            if file.relativePath.indexOf(path) is 0
              return

          # Skip valid files
          if jshint(file.source, config.options, config.globals) is true
            return

          else
            # Print filename
            console.log 'JSHint - '.white + file.relativePath.red
            
            # Trim errors down to max to prevent failure
            if jshint.errors.length > maxErrors
              tooManyErrors = true
              while jshint.errors.length > maxErrors
                jshint.errors.pop()
            
            # Print errors
            for err in jshint.errors
              ref = 'line ' + err.line + ', char ' + err.character
              message = err.reason
              console.log ref.blue + ' - '.white + message
            
            # Print warning if jshint,errors was > maxerr
            if tooManyErrors 
              console.log('Too many errors.'.underline.yellow)
            
            # Line break between each file
            console.log '\n'