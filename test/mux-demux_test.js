// Generated by CoffeeScript 1.8.0
(function() {
  var MuxDemuxTelegraph, Q, assert, chai, expect, toCatchPromise, toPromise, __;

  MuxDemuxTelegraph = require('../src/mux-demux-telegraph');

  __ = require("highland");

  chai = require("chai");

  Q = require("q");

  expect = chai.expect;

  assert = chai.assert;

  toCatchPromise = function(stream) {
    var d;
    d = Q.defer();
    stream.observe().each(d.resolve);
    return d.promise;
  };

  toPromise = function(stream) {
    return function(val) {
      var res;
      console.log('toPromise ' + JSON.stringify(val));
      res = toCatchPromise(stream);
      stream.write(val);
      return res;
    };
  };

  describe("Mux Demux test", function() {
    it("Basic Mux Demux test", function(done) {
      var Deenvelope, envelope, myDuplex, myDuplexCore, stream1, stream2, t1, t2, telegraph;
      myDuplexCore = __.pipeline(__.map(function(data) {
        data.body.message = data.body.message + " " + data.header;
        return data;
      }));
      myDuplex = myDuplexCore;
      envelope = function(hash) {
        var res;
        res = __.pipeline(__.map(function(data) {
          res = {
            header: hash,
            body: data
          };
          return res;
        }));
        return res;
      };
      Deenvelope = function(getOutPutStreamFunc) {
        return __.pipeline(__.map(function(parsed) {
          getOutPutStreamFunc(parsed.header).write(parsed.body);
        }));
      };
      telegraph = MuxDemuxTelegraph.createBasicMuxDemuxTelegraph(envelope, myDuplex, Deenvelope);
      stream1 = telegraph.openConnection("some connection 1");
      stream2 = telegraph.openConnection("some connection 2");
      telegraph.resume();
      stream1.observe().each(function(v) {
        return console.log('stream1 ' + JSON.stringify(v));
      });
      stream1.resume();
      stream2.resume();
      t1 = toPromise(stream1);
      t2 = toPromise(stream2);
      return t1({
        message: "message1"
      }).then(function(data) {
        return expect('message1 some connection 1').to.eql(data.message);
      }).then(function() {
        return {
          message: "message2"
        };
      }).then(t2).then(function(data) {
        return expect('message2 some connection 2').to.eql(data.message);
      }).then(function() {
        t2 = toPromise(stream2);
        return t2({
          message: "message3"
        }).then(function(data) {
          expect('message3 some connection 2').to.eql(data.message);
          return done();
        });
      }).done();
    });
    it("createStreamMuxingNamedStreams test", function(done) {
      var muxedStream, stream1, stream2;
      stream1 = __();
      stream2 = __();
      muxedStream = MuxDemuxTelegraph.createStreamMuxingNamedStreams({
        "some connection 1": stream1,
        "some connection 2": stream2
      });
      muxedStream.resume();
      muxedStream.observe().each(function(v) {
        return console.log('muxedStream ' + JSON.stringify(v));
      });
      toCatchPromise(muxedStream).then(function(data) {
        expect({
          header: "some connection 1",
          body: 'ololo1'
        }).to.eql(data);
      }).then(function() {
        toCatchPromise(muxedStream).then(function(data) {
          expect({
            header: "some connection 2",
            body: 'ololo2'
          }).to.eql(data);
          done();
        }).done();
        return stream2.write('ololo2');
      }).done();
      return stream1.write('ololo1');
    });
    return it("createTelegraphDemuxingStream test", function(done) {
      var p1, p3, stream1, stream3, streamNamesList, targetStream, telegraph;
      targetStream = __([
        {
          header: '1',
          body: '11'
        }, {
          header: '2',
          body: '22'
        }, {
          header: '3',
          body: '33'
        }
      ]);
      streamNamesList = ['1', '3'];
      telegraph = MuxDemuxTelegraph.createTelegraphDemuxingStream(targetStream, streamNamesList);
      stream1 = telegraph.openConnection("1");
      stream3 = telegraph.openConnection("3");
      stream1.observe().each(function(v) {
        return console.log('stream1 ' + JSON.stringify(v));
      });
      stream3.observe().each(function(v) {
        return console.log('stream3 ' + JSON.stringify(v));
      });
      p1 = toCatchPromise(stream1).then(function(data) {
        return expect('11').to.eql(data);
      });
      p3 = toCatchPromise(stream3).then(function(data) {
        return expect('33').to.eql(data);
      });
      Q.all([p1, p3]).then(function() {
        return done();
      }).done();
      stream1.resume();
      stream3.resume();
      return telegraph.resume();
    });
  });

}).call(this);

//# sourceMappingURL=mux-demux_test.js.map
