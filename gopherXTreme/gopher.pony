use "itertools"
use "files"
use "format"

primitive Gopher
  //common signifiers
  fun eol():      String => "\r\n"
  fun eom():      String => ".\r\n"

  // RFC1436 types
  fun file():         U8 => '0'
  fun directory():    U8 => '1'
  fun cso():          U8 => '2'
  fun err():          U8 => '3'
  fun binhex():       U8 => '4'
  fun dos_binary():   U8 => '5' // per RFC1436
  fun archive():      U8 => '5' // per gophernicus.h
  fun uuencoded():    U8 => '6'
  fun index_search(): U8 => '7'
  fun telnet():       U8 => '8'
  fun binary():       U8 => '9'
  fun mirror():       U8 => '+'
  fun tn320():        U8 => 'T'
  fun gif():          U8 => 'g'
  fun image():        U8 => 'I'

  // (un(der?)?) documented practical types, from and Gophernicus source
  fun document():     U8 => 'd'
  fun html():         U8 => 'h'
  fun info():         U8 => 'i'
  fun mime():         U8 => 'M'
  fun sound():        U8 => 's'
  fun video():        U8 => ';'
  fun calendar():     U8 => 'c'

  fun types(): Array[U8] => [ file()
                              directory()
                              cso()
                              err()
                              binhex()
                              dos_binary()
                              archive()
                              uuencoded()
                              index_search()
                              telnet()
                              binary()
                              mirror()
                              tn320()
                              gif()
                              image()
                              document()
                              html()
                              info()
                              mime()
                              sound()
                              video()
                              calendar() ]

primitive GopherFileType
  fun apply(file: FilePath): U8 =>
    match Path.ext(file.path).lower()
    | "7z"   => Gopher.archive()
    | "avi"  => Gopher.video()
    | "com"  => Gopher.dos_binary()
    | "doc"  => Gopher.document()
    | "docx" => Gopher.document()
    | "exe"  => Gopher.dos_binary()
    | "flac" => Gopher.sound()
    | "gif"  => Gopher.gif()
    | "gz"   => Gopher.archive()
    | "hcx"  => Gopher.binhex()
    | "htm"  => Gopher.html()
    | "html" => Gopher.html()
    | "hqx"  => Gopher.binhex()
    | "img"  => Gopher.binary()
    | "iso"  => Gopher.binary()
    | "jpe"  => Gopher.image()
    | "jpg"  => Gopher.image()
    | "jpeg" => Gopher.image()
    | "mp3"  => Gopher.sound()
    | "mp4"  => Gopher.video()
    | "odt"  => Gopher.document()
    | "ps"   => Gopher.document()
    | "pdf"  => Gopher.document()
    | "pe"   => Gopher.dos_binary()
    | "png"  => Gopher.image()
    | "tar"  => Gopher.archive()
    | "txt"  => Gopher.file()
    | "wav"  => Gopher.sound()
    | "xls"  => Gopher.document()
    | "xlsx" => Gopher.document()
    | "zip"  => Gopher.archive()
    else
      Gopher.file()
    end

primitive GopherItem
  fun apply(item_type: U8,
            display_string: String = "",
            selector: String = "",
            host: String = "NULL",
            port: String = "0"): String iso^ =>
    let final_display_string =
      if display_string.size() < 70 then
        Format(display_string where width=70, align=AlignLeft)
      elseif display_string.size() > 70 then
        display_string.trim(0, 70)
      else
        display_string
      end
    // 76: description length of 70 + 3 tabs, CRLF and 1 item_type
    (recover
      String(76 + selector.size() + host.size() + port.size())
    end)
      .> unshift(item_type)
      .> append(final_display_string)
      .> append("\t")
      .> append(selector)
      .> append("\t")
      .> append(host)
      .> append("\t")
      .> append(port)
      .> append(Gopher.eol())

  fun err(display_string: String): String iso^ =>
    GopherItem(Gopher.err(), display_string)

  fun html(display_string: String, url: String): String iso^ =>
    GopherItem(Gopher.html(),
               display_string,
               "URL:" + url)

  fun i(display_string: String): String iso^ =>
    GopherItem(Gopher.info(), display_string)

  fun spacer(): String iso^ =>
    GopherItem(Gopher.info())

  fun title(text: String): String iso^ =>
    (recover
      String(spacer().size() + 72)
    end) .> append(GopherItem(Gopher.info(),
            Format(text where width=70, align=AlignCenter)))
         .> append("\r\n")
         .> append(spacer())

primitive GopherMessage
  fun apply(items: Array[String]): String iso^ =>
    var message = recover String end
    for item in items.values() do
      message.append(consume item)
    end
    message.append(GopherItem.spacer())
    message.append(GopherItem.i(Format(ProductNameAndVersion() where
                                width=70,
                                align=AlignRight)))
    message.append(Gopher.eom())
    message

primitive GopherMap
  fun apply(conf: GopherConf val,
            dir_path: FilePath,
            include_file: String = "gophermap",
            raw: Bool = false): String =>
    var map: Array[String] = []
    try
      with file = OpenFile(
        FilePath(dir_path, include_file)?) as File
      do
        for line in file.lines() do
          map.push(parse_line(consume line, dir_path, conf))
        end
      end

      if not raw then
        GopherMessage(map)
      else
        Flatten(map)
      end
    else
      let msg = "Failed to load: " + include_file
      if not raw then GopherItem.err(msg) else msg end
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

  fun exists(base: FilePath,
             dir_path: FilePath,
             file': String = "gophermap"): Bool =>
    let gophermap_path = Path.join(dir_path.path, file')
    try
      let gophermap = FilePath(base, gophermap_path)?
      gophermap.exists()
    else
      false
    end

  fun _first_char(line: String): U8 =>
    try line.at_offset(0)? else -1 end

  fun _access(array: Array[String], index: USize): String =>
    try array(index)? else "" end

  fun parse_line(line: String,
                 path: FilePath,
                 conf: GopherConf val): String =>
    var fields = Array[String](4)
    var first_char = _first_char(line)
    var msg_type = Gopher.info()
    var final_line = line

    if prefix_chars().contains(first_char) and
      line.contains("\t")
    then
      final_line = line.trim(1)
      msg_type = first_char
      fields = final_line.split_by("\t")
    elseif format_chars().contains(first_char) then
      final_line = line.trim(1)
    end

    match first_char
    | comment() => ""
    | include() => GopherMap(conf,
                             path,
                             consume final_line where raw=true)
    | title()   => GopherItem.title(consume final_line)
    | menu()    => ListDir(conf,
                           path,
                           consume final_line where raw=true)
    else
      let item_fun = GopherItem~apply(msg_type,
                                      _access(fields, 0),
                                      _access(fields, 1))
      match fields.size()
      // base case
      | 0 => GopherItem(msg_type, consume final_line)
      // 2 fields: display string and selector specified, local link
      // (or HTTP link which needs redirection)
      | 2 => item_fun(conf.hostname,
                      conf.port)
      // 4 fields: display string, selector, host and port specified
      | 4 => item_fun(_access(fields, 2),
                      _access(fields, 3))
      else
        let fields_len = fields.size().string()
        GopherItem.err("Invalid field count ("
                        + consume fields_len
                        + ") for: <<"
                        + consume final_line
                        + ">>, should be 0, 2 or 4 fields.")
      end
    end
