use "debug"
use "net"
use "files"

class GopherListener is TCPListenNotify
  let base: FilePath
  let host: String
  let port: String
  let _out: OutStream

  new iso create(out: OutStream, base': FilePath, host': String, port': String) =>
    _out = out
    base = base'
    host = host'
    port = port'

  fun ref listening(listen: TCPListener ref) =>
    try
      (let bound_host, let bound_port) = listen.local_address().name()?
      _out.print("Listening on " + bound_host + ":" + bound_port)
    else
      listen.close()
    end

  fun ref not_listening(listen: TCPListener ref) =>
    _out.print("Couldn't bind to the requested host:port tuple")
    listen.close()

  fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
    GopherServer(_out, host, port, base)
