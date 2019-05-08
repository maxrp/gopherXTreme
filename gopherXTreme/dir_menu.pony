use "files"
use "format"
use "time"

primitive BytesPer
  fun kb(): USize => 1_024
  fun mb(): USize => 1_048_576
  fun gb(): USize => 1_073_741_824
  fun tb(): USize => 1_099_511_627_776

primitive ListDir
  fun apply(conf: GopherConf val,
            path: FilePath,
            rel_path: String,
            raw: Bool = false): String =>
    var dir_entries: Array[String] =
      if not raw then
        [GopherItem.i(" * Listing: " + rel_path)]
      else
        []
      end
    let base =
      try
        FilePath(conf.server_path, rel_path)?
      else
        conf.server_path
      end
    let dir_menu = GopherDirMenu(dir_entries, base, rel_path, conf.hostname, conf.port)
    path.walk(dir_menu)
    if not raw then
      GopherMessage(dir_entries)
    else
      Flatten(dir_entries)
    end

class GopherDirMenu
  let _results: Array[String]
  let _base: FilePath
  let _path: String
  let _host: String
  let _port: String

  new create(results': Array[String],
             base': FilePath,
             rel_path: String,
             host': String,
             port': String) =>
    _results = results'
    _base = base'
    _path = Path.join("/", rel_path)
    _host = host'
    _port = port'

  fun ref apply(dir_path: FilePath,
                entries: Array[String val]) =>
    // Don't recurse into subdirs
    try
      if Path.rel(_base.path, dir_path.path)? != "." then return end
    end

    let caps =
      recover val
        FileCaps
          .> set(FileRead)
          .> set(FileStat)
      end

    for (i, entry) in entries.pairs() do
      try
        // Hide hidden files
        if entry.at(".") then
          continue
        end

        let child_path = FilePath(dir_path, entry, caps)?
        let path_info = FileInfo(child_path)?
        let item_type =
          match path_info
          | if path_info.directory => Gopher.directory()
          | if path_info.file => GopherFileType(path_info.filepath)
          else
            Gopher.err()
          end

        let item =
          if entry.size() > 23 then
            // that'd be pretty long for a file name
            entry.trim(0, 23) + ". . ."
          else
            entry
          end
        let path_size = _readable_units(path_info.size)
        let listing = Format(item where width=43, align=AlignLeft)
          + Format(_mtime(path_info) where width=10, align=AlignLeft)
          + Format(path_size where width=10, align=AlignRight)

        _results.push(GopherItem(item_type,
                                 listing,
                                 Path.join("/",
                                           Path.join(_path, entry)),
                                 _host,
                                 _port
        ))
      end
    end

  fun _readable_units(size: USize): String =>
    match size
    | if size < BytesPer.kb() => size.string() + "B"
    | if size < BytesPer.mb() => (size / BytesPer.kb()).string() + "K"
    | if size < BytesPer.gb() => (size / BytesPer.mb()).string() + "M"
    | if size < BytesPer.tb() => (size / BytesPer.gb()).string() + "G"
    else
      "Really?!"
    end

  fun _mtime(info: FileInfo): String =>
    (let m_secs: I64, let m_nanos: I64) = info.modified_time
    let mtime = PosixDate(m_secs, m_nanos)
    try mtime.format("%x %X")? else "???" end
