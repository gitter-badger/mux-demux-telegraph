__ = require('highland')
R = require('ramda')

MuxDemuxTelegraph = (envelope, myDuplex, deenvelope)->
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

    openConnection: (portHash)->
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
  envelope = (hash)->
    __.pipeline(
      __.map((data) ->
        header: hash
        body: data
      )
    )

  myDuplex = __()
  muxDemuxTelegraph = MuxDemuxTelegraph(envelope, myDuplex)

  R.forEach((item)->
    streamsMap[item].pipe(muxDemuxTelegraph.openConnection(item))
  )(R.keys(streamsMap))

  muxDemuxTelegraph.resume()

  myDuplex

createTelegraphDemuxingStream = (targetStream, streamNamesList)->
  Deenvelope = (getOutPutStreamFunc)->
    __.pipeline(
      __.map((parsed) ->
        getOutPutStreamFunc(parsed.header).write(parsed.body)
        return
      )
    )

  muxDemuxTelegraph = MuxDemuxTelegraph(null, targetStream, Deenvelope)

  R.forEach((item)->
    muxDemuxTelegraph.openConnection(item)
  )(streamNamesList)

  muxDemuxTelegraph.resume()

  muxDemuxTelegraph

module.exports =
  createBasicMuxDemuxTelegraph:MuxDemuxTelegraph
  createStreamMuxingNamedStreams:createStreamMuxingNamedStreams
  createTelegraphDemuxingStream:createTelegraphDemuxingStream