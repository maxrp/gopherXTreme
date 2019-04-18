use "debug"
use "files"
use "format"
use "net"
use "time"

class GopherServer is TCPConnectionNotify
  let _base: FilePath
  let _host: String
  let _port: String
  let _out: OutStream
  var _remote_ip: String = ""
  var _remote_port: String = ""

  new iso create(out: OutStream, host': String, port': String, base': FilePath) =>
    _out = out
    _base = base'
    _host = host'
    _port = port'

  fun ref accepted(conn: TCPConnection ref) =>
    try
      (_remote_ip, _remote_port) = conn.remote_address().name()?
    end
    Debug.out("Connection accepted from: " + _remote_ip + ":" + _remote_port)

  fun ref received(conn: TCPConnection ref,
                   data: Array[U8] iso,
                   times: USize): Bool =>

    var reqstr: String = String.from_array(consume data)
    // First chars is needed because of the subsequent .strip()
    let first_chars = reqstr.substring(0, 2)

    var selector = ""
    if consume first_chars == "\r\n" then
      conn.write(_list_dir(_base, "/"))
      selector = "index"
    else
      // prepare the selector
      selector = reqstr.clone().>strip()
      if selector.at("/") then
        selector = selector.substring(1)
      end

      // look up the selector
      try
        let path = FilePath(_base, selector.clone())?
        let path_info = FileInfo(path)?
        match path_info
        | if path_info.directory => conn.write(_list_dir(path, selector))
        | if path_info.file => conn.write(_stream_file(path))
        end
      else
        conn.write(_not_found(selector))
      end
    end
    _out.print(_remote_ip + " selected '" + consume selector + "'.")
    conn.dispose()
    true

  fun _stream_file(path: FilePath): String =>
    try
      var file_contents = recover String end
      with file = OpenFile(path) as File do
        for line in file.lines() do
          file_contents.append(consume line + "\n")
        end
      end
      file_contents
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

  fun ref closed(conn: TCPConnection ref) =>
    Debug.out("Connection closed: " + _remote_ip)

  fun ref connect_failed(conn: TCPConnection ref) =>
    Debug.out("Connect failed!")
