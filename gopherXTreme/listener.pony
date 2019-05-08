use "backpressure"
use "files"
use "logger"
use "net"

class GopherListener is TCPListenNotify
  let _auth: BackpressureAuth
  let _log: Logger[String]
  let _conf: GopherConf val

  new iso create(auth': BackpressureAuth,
                 log': Logger[String],
                 conf': GopherConf val) =>
    _auth = auth'
    _log = log'
    _conf = conf'

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
    GopherServer(_auth, _log, _conf)
