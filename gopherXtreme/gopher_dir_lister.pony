use "files"
use "time"

class GopherDirLister
  let _results: Array[GopherItem]
  let _base: FilePath
  let _path: String
  let _host: String
  let _port: String

  new create(results: Array[GopherItem],
             base': FilePath,
             rel_path: String,
             host': String,
             port': String) =>
    _results = results
    _base = base'
    _path = Path.join("/", rel_path)
    _host = host'
    _port = port'

  fun ref apply(dir_path: FilePath,
                entries: Array[String val]) =>
    let caps =
      recover val
        FileCaps
          .> set(FileRead)
          .> set(FileStat)
      end

    for (i, entry) in entries.pairs() do
      try
        // Don't recurse into subdirs
        if Path.rel(_base.path, dir_path.path)? != "." then
          entries.delete(i)?
          return
        end

        let child_path = FilePath(dir_path, entry, caps)?
        let path_info = FileInfo(child_path)?
        let item_type =
          match path_info
          | if path_info.directory => Gopher.directory()
          | if path_info.file => Gopher.file()
          else
            Gopher.info()
          end

        // Hide hidden files
        if not entry.at(".") then
          _results.push(GopherItem.create(item_type,
              entry + "  " + _mtime(path_info) + "  " + path_info.size.string() + " bytes",
              Path.join("/", Path.join(_path, entry)),
              _host,
              _port
          ))
        end
      end
    end

  fun _mtime(info: FileInfo): String =>
    (let m_secs: I64, let m_nanos: I64) = info.modified_time
    let mtime = PosixDate(m_secs, m_nanos)
    try mtime.format("%x %X")? else "???" end
