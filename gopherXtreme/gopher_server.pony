use "backpressure"
use "debug"
use "files"
use "format"
use "logger"
use "net"
use "time"

class GopherServer is TCPConnectionNotify
  let _auth: BackpressureAuth
  let _base: FilePath
  let _host: String
  let _port: String
  let _log: Logger[String]
  var _remote_ip: String = ""
  var _remote_port: String = ""

  new iso create(auth': BackpressureAuth,
                 log': Logger[String],
                 host': String,
                 port': String,
                 base': FilePath) =>
    _auth = auth'
    _log = log'
    _base = base'
    _host = host'
    _port = port'

  fun ref accepted(conn: TCPConnection ref) =>
    try
      (_remote_ip, _remote_port) = conn.remote_address().name()?
    end
    _log(Fine) and (
        // if this'll be logged, allocate a string statically for msg
        let msg = (recover String(_remote_ip.size()
          + _remote_port.size()
          + 20) // 19 bytes for "connection opened: " + 1 for ":"
        end)
          .> append("Connection opened: ")
          .> append(_remote_ip)
          .> append(":")
          .> append(_remote_port)

        _log.log(consume msg)
    )

  fun ref received(conn: TCPConnection ref,
                   data: Array[U8] iso,
                   times: USize): Bool =>

    var reqstr: String = String.from_array(consume data)

    var selector = ""
    let message =
      if reqstr.at("\r") and reqstr.at("\n", 1) then
        selector = "index"
        _list_dir(_base, "/")
      else
        // prepare the selector
        selector = reqstr.clone() .> strip()
        if selector.at("/") then
          selector = selector.substring(1)
        end

        // reject requests for hidden files
        if selector.at(".") then
          _access_denied()
        else
          // look up the selector
          try
            let path = FilePath(_base, selector.clone())?
            let path_info = FileInfo(path)?
            match path_info
            | if path_info.directory => _list_dir(path, selector)
            | if path_info.file => _stream_file(conn, path)
            else
              GopherMessage(
                [GopherItem.spacer()
                 GopherItem.i(" wut?")],
                [GopherItem.i(" ^_^Â ")]
              ).string()
            end
          else
            _not_found(selector)
          end
        end
      end
    let message_size: String = message.size().string()
    conn.write(consume message)

    _log(Info) and (
      let msg = (recover String(_remote_ip.size()
        + selector.size()
        + message_size.size()
        + 21) // length of static elements
      end)
        .> append(_remote_ip)
        .> append(" selected '")
        .> append(selector)
        .> append("', ")
        .> append(message_size)
        .> append(" bytes.")
      _log.log(consume msg)
    )

    conn.dispose()
    true

  fun _stream_file(conn: TCPConnection ref, path: FilePath): String =>
    try
      with file = OpenFile(path) as File do
        for line in file.lines() do
          conn.write(consume line + "\n")
        end
      end
      ""
    else
      _not_found(path.path)
    end

  fun _list_dir(path: FilePath, rel_path: String): String =>
    var dir_entries: Array[GopherItem] = []
    let base = try FilePath(_base, rel_path)? else _base end
    let dir_walker = GopherDirLister(dir_entries, base, rel_path, _host, _port)
    path.walk(dir_walker)
    GopherMessage([GopherItem.i(" * Listing: " + rel_path)],
                  dir_entries).string()

  fun _not_found(selector: String): String =>
    GopherMessage([GopherItem.i(" * Not Found: "); GopherItem.spacer()],
                  [GopherItem.i("    " + selector)]).string()

  fun _access_denied(): String =>
    GopherMessage([GopherItem.i(" *** Access Denied *** ")],
                  [GopherItem.i("*   *      *      *   *")]).string()

  fun ref closed(conn: TCPConnection ref) =>
    _log(Fine) and (
      let msg = (recover
        String(_remote_ip.size() + 19)
      end)
        .> append("Connection closed: ")
        .> append(_remote_ip)

      _log.log(consume msg)
    )

  fun ref connect_failed(conn: TCPConnection ref) =>
    _log(Error) and
      _log.log("Connect failed!")

  fun ref throttled(connection: TCPConnection ref) =>
    Backpressure.apply(_auth)
    _log(Warn) and
      _log.log("Throttling.")

  fun ref unthrottled(connection: TCPConnection ref) =>
    Backpressure.release(_auth)
    _log(Warn) and
        _log.log("Unthrottling.")
