use "files"
use "format"
use "net"

class GopherServer is TCPConnectionNotify
  let base: String
  let _out: OutStream
  var _remote_ip: String = ""
  var _port: String = ""

  new iso create(out: OutStream, base': String) =>
    _out = out
    base = base'

  fun ref accepted(conn: TCPConnection ref) =>
    _out.print("connection accepted")

  fun ref received(conn: TCPConnection ref,
                   data: Array[U8] iso,
                   times: USize): Bool =>
    try
      (_remote_ip, _port) = conn.remote_address().name()?
    end
    let footer = [GopherItem.spacer()
      GopherItem.i("gopherXtreme/"+Version() where align=AlignRight)]
    let index = GopherMessage([GopherItem.i("* Listing: "+base)],
        [GopherItem.i("Your IP is: " + _remote_ip)],
        footer)

    var reqstr: String = String.from_array(consume data)

    // Probably needs more escaping than this, but it's a useful start
    let request_log: String = reqstr.clone()
                                    .>replace("\r", "<CR>")
                                    .>replace("\n", "<LF>")
                                    .>replace("\t", "<TAB>")
    _out.print(_remote_ip + " selection='" + request_log + "'")

    // First chars is needed because of the subsequent .strip()
    let first_chars = reqstr.substring(0, 2)

    let message =
    if consume first_chars == "\r\n" then
      index.string()
    else
      // prepare the selector
      var selector = reqstr.clone().>strip()
      if selector.at("/") then
        selector = selector.substring(1)
      end

      // look up the selector
      GopherMessage([GopherItem.spacer()],
                    [GopherItem.i(" * Not Found: "+consume selector)],
                    footer).string()
    end
    conn.write(consume message)
    conn.dispose()
    true

  fun ref closed(conn: TCPConnection ref) =>
    _out.print("connection closed")

  fun ref connect_failed(conn: TCPConnection ref) =>
    _out.print("connect failed")
