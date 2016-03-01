{ normalize } = require 'path'

module.exports = (grunt) ->
  require('load-grunt-tasks') grunt

  grunt.initConfig
    config:
      dist: normalize "#{__dirname}/dist"

    clean:
      dist: src: [ '<%= config.dist %>/**' ]

    cson:
      api:
        expand: true
        flatten: false
        cwd: 'src'
        src: [ '**/*.cson', '*.cson' ]
        dest: '<%= config.dist %>/'
        ext: '.json'

    coffee:
      main:
        options:
          bare: true
          join: true
        expand: true
        cwd: 'src'
        src: [ '**/*.coffee' ]
        dest: '<%= config.dist %>/'
        ext: '.js'

    watch:
      coffee: files: ['src/*.coffee', 'src/**/**.coffee'], tasks: ['coffee']
      cson: files: ['src/*.cson', 'src/**/**.cson'], tasks: ['cson']

  grunt.registerTask 'default', [ 'clean', 'coffee', 'cson' ]
  grunt.registerTask 'dev', [ 'default', 'watch' ]