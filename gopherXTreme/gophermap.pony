use "files"

primitive GopherMap
  fun apply(dir_path: FilePath): String =>
    var map: Array[String] = []
    try
      with file = OpenFile(
        FilePath(dir_path, "gophermap")?) as File
      do
        for line in file.lines() do
          map.push(parse_line(consume line))
        end
      end
      GopherMessage(map)
    else
      "failed to load gophermap"
    end

  fun include(): U8 => '='
  fun title():   U8 => '!'
  fun comment(): U8 => '#'
  fun menu():    U8 => '*'

  fun format_chars(): Array[U8] => [
    include()
    title()
    comment()
    menu()
  ]

  fun prefix_chars(): Array[U8] =>
    Array[U8](
      format_chars().size() + Gopher.types().size()
    ) .> append(format_chars())
      .> append(Gopher.types())

  fun exists(base: FilePath, dir_path: FilePath): Bool =>
    let gophermap_path = GopherMap.path(dir_path)
    try
      let gophermap = FilePath(base, gophermap_path)?
      gophermap.exists()
    else
      false
    end

  fun _first_char(line: String): U8 =>
    try line.at_offset(0)? else -1 end

  fun parse_line(line: String): String =>
    var first_char = _first_char(line)
    var msg_type = Gopher.info()
    var final_line = line

    if prefix_chars().contains(first_char) and
      line.contains("\t")
    then
      final_line = line.trim(1)
      msg_type = first_char
    elseif format_chars().contains(first_char) then
      final_line = line.trim(1)
    end

    match first_char
    | comment() => ""
    | include() => GopherItem.i("WOULD INCLUDE: " + final_line)
    | title()   => GopherItem.i("Title: " + final_line)
    | menu()    => GopherItem.i("Would list dir here...")
    else
      GopherItem(msg_type, final_line)
    end

  fun path(dir_path: FilePath): String =>
    Path.join(dir_path.path, "gophermap")
