use "backpressure"
use "debug"
use "logger"
use "net"
use "files"

class GopherListener is TCPListenNotify
  let base: FilePath
  let host: String
  let port: String
  let _auth: BackpressureAuth
  let _log: Logger[String]

  new iso create(auth': BackpressureAuth,
                 log': Logger[String],
                 base': FilePath,
                 host': String,
                 port': String) =>
    _auth = auth'
    _log = log'
    base = base'
    host = host'
    port = port'

  fun ref listening(listen: TCPListener ref) =>
    try
      (let bound_host, let bound_port) = listen.local_address().name()?
      _log(Info) and
          _log.log("Listening on " + bound_host + ":" + bound_port)
    else
      listen.close()
    end

  fun ref not_listening(listen: TCPListener ref) =>
    _log(Warn) and
      _log.log("Couldn't bind to the requested host:port tuple")
    listen.close()

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    GopherServer(_auth, _log, host, port, base)
