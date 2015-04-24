MuxDemuxTelegraph = require('../src/mux-demux-telegraph')

__ = require("highland")
highlandDuplex = require("highland-duplex")
chai = require("chai")
Q = require("q")
expect = chai.expect;
assert = chai.assert;

toCatchPromise = (stream)->
  d = Q.defer()
  stream.observe().each(d.resolve)
  d.promise

toPromise = (stream)->
  (val)->
    console.log('toPromise ' + JSON.stringify(val))
    res = toCatchPromise(stream)
    stream.write(val)
    res

describe "check lines test", ->
  it.only "check lines", (done)->
    src1 = __()
    src2 = __()
    dest1 = __()
    dest2 = __()

    dest1.pipe(src2)
    dest2.pipe(src1)

    duplex1 = highlandDuplex.makeDuplexStream(()->
      src1
    , ()->
      dest1
    )

    duplex2 = highlandDuplex.makeDuplexStream(()->
      src2
    , ()->
      dest2
    )

    createMyPostStation = MuxDemuxTelegraph.getDuplexLines({worker:'W', backgroundPage:'BGP'})
    postStation1 = createMyPostStation(duplex1)
    postStation2 = createMyPostStation(duplex2)

    p1 = toCatchPromise(postStation2.worker).then((v)->
      expect('ololo 1').to.eql(v);
    )

    p2 = toCatchPromise(postStation2.backgroundPage).then((v)->
      expect('ololo 2').to.eql(v);
    )

    postStation1.worker.write('ololo 1')
    postStation1.backgroundPage.write('ololo 2')

    postStation2.worker.resume()
    postStation2.backgroundPage.resume()

    Q.all([p1, p2]).then(()-> done())

describe "Mux Demux test", ->
  it "Basic Mux Demux test", (done) ->
    myDuplex = __.pipeline(__.map((data) ->
      data.body.message = data.body.message + " " + data.header
      return data
    ))

    telegraph = MuxDemuxTelegraph.createMuxDemuxTelegraph(myDuplex)

    stream1 = telegraph.line("some connection 1")
    stream2 = telegraph.line("some connection 2")

    telegraph.resume()

    stream1.observe().each((v)->
      console.log('stream1 ' + JSON.stringify(v))
    )

    stream1.resume()
    stream2.resume()

    t1 = toPromise(stream1)
    t2 = toPromise(stream2)

    t1({message: "message1"})
    .then((data)->
      expect('message1 some connection 1').to.eql(data.message);
    )
    .then(()-> {message: "message2"})
    .then(t2)
    .then((data)->
      expect('message2 some connection 2').to.eql(data.message);
    )
    .then(()->
      t2 = toPromise(stream2)
      t2({message: "message3"}).then((data)->
        expect('message3 some connection 2').to.eql(data.message);
        done()
      )
    ).done()

  it "createStreamMuxingNamedStreams test", (done) ->
    stream1 = __()
    stream2 = __()

    muxedStream = MuxDemuxTelegraph.createStreamMuxingNamedStreams("some connection 1": stream1, "some connection 2": stream2)
    muxedStream.resume()

    muxedStream.observe().each((v)->
      console.log('muxedStream ' + JSON.stringify(v))
    )

    toCatchPromise(muxedStream)
    .then((data)->
      expect(header: "some connection 1", body: 'ololo1').to.eql(data);
      return
    )
    .then(()->
      toCatchPromise(muxedStream)
      .then((data)->
        expect(header: "some connection 2", body: 'ololo2').to.eql(data);
        done()
        return
      ).done()
      stream2.write('ololo2')
    ).done()

    stream1.write('ololo1')

  it "createTelegraphDemuxingStream test", (done) ->
    targetStream = __([{header: '1', body: '11'}, {header: '2', body: '22'}, {header: '3', body: '33'}])

    streamNamesList = ['1', '3']

    telegraph = MuxDemuxTelegraph.createTelegraphDemuxingStream(targetStream, streamNamesList)

    stream1 = telegraph.line("1")
    stream3 = telegraph.line("3")

    stream1.observe().each((v)->
      console.log('stream1 ' + JSON.stringify(v))
    )

    stream3.observe().each((v)->
      console.log('stream3 ' + JSON.stringify(v))
    )

    p1 = toCatchPromise(stream1)
    .then((data)->
      expect('11').to.eql(data);
    )

    p3 = toCatchPromise(stream3)
    .then((data)->
      expect('33').to.eql(data);
    )

    Q.all([p1, p3]).then(()->done()).done()

    stream1.resume()
    stream3.resume()
    telegraph.resume()

