use "backpressure"
use "files"
use "format"
use "logger"
use "net"
use "time"

primitive GopherServerMessage
  fun not_found(): String =>
    GopherMessage([GopherItem.i(" * Not Found.")])

  fun access_denied(): String =>
    GopherMessage([GopherItem.i(" * Access Denied.")])

  fun wut(): String =>
    GopherMessage([GopherItem.spacer()
                   GopherItem.i(" wut? ")
                   GopherItem.i("\"^_^  ")])

class GopherServer is TCPConnectionNotify
  let _auth: BackpressureAuth
  let _log: Logger[String]
  let _conf: GopherConf val
  let _buffer_length: USize
  var _remote_ip: String = ""
  var _remote_port: String = ""
  var _selector: String = ""
  var _sent_size: USize = 0
  var _streaming: Bool = false

  new iso create(auth': BackpressureAuth,
                 log': Logger[String],
                 conf': GopherConf val,
                 buffer_length': USize = 1024) =>
    _auth = auth'
    _log = log'
    _conf = conf'
    _buffer_length = buffer_length'

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
    // Client requests should really be very short, stop reading them
    conn.mute()

    // enforce a maximum request length
    if data.size() > _buffer_length then
      data.trim_in_place(0, _buffer_length)
    end

    // truncate the request at null if present
    try data.truncate(data.find('\0')?) end

    let reqstr: String = String.from_iso_array(consume data)

    let message =
      if reqstr.at("\r") and reqstr.at("\n", 1) then
        _selector = "index"
        _gophermap(_conf.server_path)
      else
        // prepare the selector
        _selector =
          try
            // We really don't want any CR/LF to remain here
            // as part of the selector
            reqstr.clone() .> cut_in_place(reqstr.find("\n")?)
                           .> cut_in_place(reqstr.find("\r")?)
          else
            reqstr.clone()
          end

        if _selector.at("/") then
          _selector = _selector.trim(1)
        end

        // reject requests for hidden files
        if _selector.at(".") then
          GopherServerMessage.access_denied()
        else
          // look up the selector
          try
            let path = FilePath(_conf.server_path, _selector.clone())?
            let path_info = FileInfo(path)?
            match path_info
            | if path_info.directory => _gophermap(path)
            | if path_info.file      => _stream_file(conn, path)
            else
              GopherServerMessage.wut()
            end
          else
            GopherServerMessage.not_found()
          end
        end
      end
    conn.write(consume message)
    conn.unmute()
    conn.dispose()
    // Don't handle selectors split across multiple fragments.
    false

  fun ref sent(conn: TCPConnection ref,
               data: (String val | Array[U8 val] val)):
               (String val | Array[U8 val] val) =>
    _sent_size = _sent_size + data.size()
    data

  fun ref sentv(conn: TCPConnection ref,
                data: ByteSeqIter val): ByteSeqIter val =>
    for chunk in data.values() do
      _sent_size = _sent_size + chunk.size()
    end
    data

  fun ref _stream_file(conn: TCPConnection ref,
                       path: FilePath): String =>
    try
      with file = OpenFile(path) as File do
        _streaming = true
        var counter: USize = 0
        while counter <= (file.size()/_buffer_length) do
          conn.write(file.read(_buffer_length))
          counter = counter + 1
        end
        _streaming = false
      end
      ""
    else
      GopherServerMessage.not_found()
    end

  fun _gophermap(path: FilePath): String =>
    if GopherMap.exists(_conf.server_path, path) then
      GopherMap(_conf, path)
    else
      let rel_path: String =
        if _selector == "index" then "/" else _selector end
      ListDir(_conf, path, rel_path)
    end

  fun ref closed(conn: TCPConnection ref) =>
    _log(Info) and _log.log(
      let sent_size: String = _sent_size.string()
      (recover String(_remote_ip.size()
        + _selector.size()
        + sent_size.size()
        + 21) // length of static elements
      end)
        .> append(_remote_ip)
        .> append(" selected '")
        .> append(_selector)
        .> append("', ")
        .> append(sent_size)
        .> append(" bytes.")
    )
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

  fun ref throttled(conn: TCPConnection ref) =>
    if not _streaming then
      Backpressure.apply(_auth)
    end
    _log(Fine) and
      _log.log("Throttled.")

  fun ref unthrottled(conn: TCPConnection ref) =>
    Backpressure.release(_auth)
    _log(Fine) and
        _log.log("Unthrottled.")
