// Generated by CoffeeScript 1.8.0
(function() {
  var R, createBasicMuxDemuxTelegraph, createMuxDemuxTelegraph, createStreamMuxingNamedStreams, createTelegraphDemuxingStream, defaultDeenvelopeFct, defaultEnvelopeFct, __;

  __ = require('highland');

  R = require('ramda');

  defaultEnvelopeFct = function() {
    return function(hash) {
      return __.pipeline(__.map(function(data) {
        return {
          header: hash,
          body: data
        };
      }));
    };
  };

  defaultDeenvelopeFct = function() {
    return function(getOutPutStreamFunc) {
      return __.pipeline(__.map(function(parsed) {
        getOutPutStreamFunc(parsed.header).write(parsed.body);
      }));
    };
  };

  createBasicMuxDemuxTelegraph = function(envelope, myDuplex, deenvelope) {
    var deenvelopeStream, result, _getOutPutStream;
    deenvelopeStream = null;
    result = {
      streamMap: {},
      outPutStreamsMap: {},
      closeConnection: function(portHash) {
        delete result.streamMap[portHash];
        return delete result.outPutStreamsMap[portHash];
      },
      pause: function() {
        if (!deenvelope) {
          return;
        }
        return deenvelopeStream.pause();
      },
      resume: function() {
        if (!deenvelope) {
          return;
        }
        return deenvelopeStream.resume();
      },
      openConnection: function(portHash) {
        var envelopingStream, outStream, stream;
        if (result.streamMap[portHash]) {
          return result.streamMap[portHash];
        }
        if (envelope) {
          envelopingStream = envelope(portHash);
          envelopingStream.pipe(myDuplex);
        }
        result.outPutStreamsMap[portHash] = outStream = __();
        stream = __.pipeline(function(inStream) {
          var procFunc;
          if (envelope) {
            procFunc = function(err, x, push, next) {
              if (x === __.nil) {
                outStream.write(__.nil);
              } else {
                envelopingStream.write(x);
              }
              next();
            };
            inStream.consume(procFunc).resume();
          }
          return outStream;
        });
        result.streamMap[portHash] = stream;
        return stream;
      }
    };
    if (deenvelope) {
      _getOutPutStream = function(portHash) {
        return result.outPutStreamsMap[portHash];
      };
      deenvelopeStream = deenvelope(_getOutPutStream);
      myDuplex.fork().each(function(v) {
        return deenvelopeStream.write(v);
      });
    }
    return result;
  };

  createStreamMuxingNamedStreams = function(streamsMap) {
    var envelope, muxDemuxTelegraph, myDuplex;
    envelope = defaultEnvelopeFct();
    myDuplex = __();
    muxDemuxTelegraph = createBasicMuxDemuxTelegraph(envelope, myDuplex);
    R.forEach(function(item) {
      return streamsMap[item].pipe(muxDemuxTelegraph.openConnection(item));
    })(R.keys(streamsMap));
    muxDemuxTelegraph.resume();
    return myDuplex;
  };

  createTelegraphDemuxingStream = function(targetStream, streamNamesList) {
    var Deenvelope, muxDemuxTelegraph;
    Deenvelope = defaultDeenvelopeFct();
    muxDemuxTelegraph = createBasicMuxDemuxTelegraph(null, targetStream, Deenvelope);
    R.forEach(function(item) {
      return muxDemuxTelegraph.openConnection(item);
    })(streamNamesList);
    muxDemuxTelegraph.resume();
    return muxDemuxTelegraph;
  };

  createMuxDemuxTelegraph = function(duplex) {
    return createBasicMuxDemuxTelegraph(defaultEnvelopeFct(), duplex, defaultDeenvelopeFct());
  };

  module.exports = {
    createMuxDemuxTelegraph: createMuxDemuxTelegraph,
    createBasicMuxDemuxTelegraph: createBasicMuxDemuxTelegraph,
    createStreamMuxingNamedStreams: createStreamMuxingNamedStreams,
    createTelegraphDemuxingStream: createTelegraphDemuxingStream
  };

}).call(this);

//# sourceMappingURL=mux-demux-telegraph.js.map
