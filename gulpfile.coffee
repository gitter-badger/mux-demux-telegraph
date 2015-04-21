gulp = require("gulp")
mocha = require("gulp-mocha")

testsGlob = 'test/**/*.js'

gulp.task 'mocha', ->
  gulp.src(testsGlob,
    read: false
  )
  .pipe(mocha(
      reporter: 'spec'
    ))