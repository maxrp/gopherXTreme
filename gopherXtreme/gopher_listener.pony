use "net"

class GopherListener is TCPListenNotify
  let base: String
  let _out: OutStream
  var _host: String = ""
  var _port: String = ""

  new iso create(out: OutStream, base': String) =>
    _out = out
    base = base'

  fun ref listening(listen: TCPListener ref) =>
    try
      (_host, _port) = listen.local_address().name()?
      _out.print("Listening on " + _host + ":" + _port)
    else
      listen.close()
    end

  fun ref not_listening(listen: TCPListener ref) =>
    _out.print("Couldn't bind to the requested host:port tuple")
    listen.close()

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    GopherServer(_out, base)
