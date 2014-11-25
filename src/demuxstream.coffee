module.exports = (stream, stdout, stderr) =>
  stream.on 'readable', ->
    header = header or stream.read 8
    while header?
      type = header.readUInt8 0
      payload = stream.read header.readUInt32BE 4
      break if !payload?
      if type is 2
        stderr.write payload
      else
        stdout.write payload
      header = stream.read 8