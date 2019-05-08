use "files"

class GopherConf
  let server_path: FilePath
  let hostname: String
  let port: String

  new val create(server_path': FilePath,
                 hostname': String,
                 port': String) =>
    server_path = server_path'
    hostname = hostname'
    port = port'
