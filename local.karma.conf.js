module.exports = function(config) {
    var configuration = {
        // other things

        customLaunchers: {
            Chrome_travis_ci: {
                base: 'Chrome',
                flags: ['--no-sandbox']
            }
        }
    };

    if (process.env.TRAVIS) {
        configuration.browsers = ['Chrome_travis_ci'];
    }

    config.set({
        logLevel: 'LOG_DEBUG',

        reporters: ['spec'],

        singleRun : true,
        autoWatch : false,

        frameworks: [
            'mocha',
            'browserify'
        ],

        files: [
            'test/*.js'
        ],

        preprocessors: {
            'test/*.js': ['browserify']
        },

        browserify: {
            debug: true
        },

        browsers: ['PhantomJS', 'Chrome']
    });
    config.set(configuration);
};