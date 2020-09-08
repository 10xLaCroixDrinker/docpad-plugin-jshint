# Export Plugin
module.exports = (BasePlugin) ->

	# Requires
	jshint = require('jshint').JSHINT
	merge = require('merge')
	fs = require('fs')
	pathUtil = require('path')

	# Define Plugin
	class JSHintPlugin extends BasePlugin
		# Plugin name
		name: 'jshint'

		# Plugin config
		config:
			ignorePaths: [ ]
			ignoreFiles: [ ]
			ignoreMinified: true
			globals: { }
			hintOptions: { }

		docpadReady: ->
			# Read .jshintrc
			docpad = @docpad
			fs.readFile process.cwd() + '/.jshintrc', (err, data) ->
				if err
					return
				else
					config = docpad.loadedPlugins.jshint.config
					jshintrc = JSON.parse(data)
					config.hintOptions = merge(config.hintOptions, jshintrc)
					docpad.loadedPlugins.jshint.config = config

					if config.hintOptions.globals
						config.globals = merge(config.globals, config.hintOptions.globals)
						delete config.hintOptions.globals


		# Render After
		# Called just just after we've rendered all the files.
		renderAfter: ({collection}) ->
			docpad = @docpad
			if docpad.getEnvironment() is 'development'
				config = @config
				ignoredPaths = [ ]

				# Set max errors
				if config.hintOptions.maxerr
					maxErrors = config.hintOptions.maxerr
				else
					maxErrors = 50

				# Normalize ignored paths
				config.ignorePaths.map (path, i) ->
					path = path.toString()
					if path.charAt(0) is '/'
						path.slice(1)
					if path.charAt(path.length - 1) isnt '/'
						path = path + '/'
					ignoredPaths.push(path)

				# this is necessary to work on windows
				ignoredPaths = ignoredPaths.map(pathUtil.normalize)
				config.ignoreFiles = config.ignoreFiles.map(pathUtil.normalize)

				collection.each (item) ->
					file = item.attributes
					tooManyErrors = false

					# Find JS files
					if file.extension is 'js'

						# Skip files in ignored paths
						for path in ignoredPaths
							if file.relativePath.indexOf(path) is 0
								return

						# Skip ignored files
						for fileName in config.ignoreFiles
							if file.relativePath is fileName
								return

						# Skip minified files (based on .min.js convention)
						if config.ignoreMinified
							if file.relativePath.includes('.min.js')
								return

						# Skip valid files
						if jshint(file.source, config.hintOptions, config.globals) is true
							return

						else
							# Print filename
							message = "JSHint: #{file.fullPath}"

							# Trim errors down to max to prevent failure
							if jshint.errors.length > maxErrors
								tooManyErrors = true
								while jshint.errors.length > maxErrors
									jshint.errors.pop()

							# Print errors
							for err in jshint.errors
								message += "\nline #{err.line}:#{err.character} - #{err.reason}"

							# Print warning if jshint,errors was > maxerr
							if tooManyErrors
								messasge += '\nToo many errors...'

							# Line break between each file
							docpad.log('warn', message)
