__ = require('highland')
R = require('ramda')

defaultEnvelopeFct = ()->
  (hash)->
    __.pipeline(
      __.map((data) ->
        header: hash
        body: data
      )
    )

defaultDeenvelopeFct =()->
  (getOutPutStreamFunc)->
    __.pipeline(
      __.map((parsed) ->
        getOutPutStreamFunc(parsed.header).write(parsed.body)
        return
      )
    )

createBasicMuxDemuxTelegraph = (envelope, myDuplex, deenvelope)->
  deenvelopeStream = null
  result =
    streamMap: {}
    outPutStreamsMap: {}

    closeConnection: (portHash)->
      delete result.streamMap[portHash]
      delete result.outPutStreamsMap[portHash]

    pause:()->
      if(!deenvelope)
        return
      deenvelopeStream.pause()

    resume:()->
      if(!deenvelope)
        return
      deenvelopeStream.resume()

    line: (portHash)->
      if(result.streamMap[portHash])
        return result.streamMap[portHash]

      if envelope
        envelopingStream = envelope(portHash)
        envelopingStream.pipe(myDuplex)

      result.outPutStreamsMap[portHash] = outStream = __()

      stream = __.pipeline((inStream) ->
        if envelope
          procFunc = (err, x, push, next) ->
            if x == __.nil
              outStream.write __.nil
            else
              envelopingStream.write(x)
            next()
            return

          inStream.consume(procFunc).resume()
        outStream
      )

      result.streamMap[portHash] = stream
      stream

  if(deenvelope)
    _getOutPutStream = (portHash)->
      result.outPutStreamsMap[portHash]

    deenvelopeStream = deenvelope(_getOutPutStream)

    myDuplex.fork().each((v)->
      deenvelopeStream.write(v)
    )

  return result

createStreamMuxingNamedStreams = (streamsMap)->
  envelope = defaultEnvelopeFct()

  myDuplex = __()
  muxDemuxTelegraph = createBasicMuxDemuxTelegraph(envelope, myDuplex)

  R.forEach((item)->
    streamsMap[item].pipe(muxDemuxTelegraph.line(item))
  )(R.keys(streamsMap))

  muxDemuxTelegraph.resume()

  myDuplex

createTelegraphDemuxingStream = (targetStream, streamNamesList)->
  Deenvelope = defaultDeenvelopeFct()

  muxDemuxTelegraph = createBasicMuxDemuxTelegraph(null, targetStream, Deenvelope)

  R.forEach((item)->
    muxDemuxTelegraph.line(item)
  )(streamNamesList)

  muxDemuxTelegraph.resume()

  muxDemuxTelegraph

createMuxDemuxTelegraph = (duplex)->
  createBasicMuxDemuxTelegraph(defaultEnvelopeFct(), duplex, defaultDeenvelopeFct())

getDuplexLines = R.curry((lineNames, duplex)->
  telegraph = createMuxDemuxTelegraph(duplex)
  getLinesObject = R.compose(R.fromPairs, R.map((lineName)->
    [lineName, telegraph.line(lineNames[lineName])]
  ), R.keys)

  getLinesObject(lineNames)
)

module.exports =
  createMuxDemuxTelegraph:createMuxDemuxTelegraph
  createBasicMuxDemuxTelegraph:createBasicMuxDemuxTelegraph
  createStreamMuxingNamedStreams:createStreamMuxingNamedStreams
  createTelegraphDemuxingStream:createTelegraphDemuxingStream
  getDuplexLines:getDuplexLines