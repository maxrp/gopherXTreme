use "net"

class GopherListener is TCPListenNotify
    let _out: OutStream
    var _host: String = ""
    var _port: String = ""

    new iso create(out: OutStream) =>
        _out = out

    fun ref listening(listen: TCPListener ref) =>
        try
            (_host, _port) = listen.local_address().name()?
            _out.print("listening on " + _host + ":" + _port)
        else
            _out.print("couldn't get local address")
            listen.close()
        end

    fun ref not_listening(listen: TCPListener ref) =>
        _out.print("couldn't listen")
        listen.close()

    fun ref connected(listen: TCPListener ref): TCPConnectionNotify iso^ =>
        GopherServer(_out)
