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
                              video() ]

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

  fun i(display_string: String): String iso^ =>
    GopherItem(Gopher.info(), display_string)

  fun html(display_string: String, url: String): String iso^ =>
    GopherItem(Gopher.html(),
               display_string,
               "URL:" + url)

  fun spacer(): String iso^ =>
    GopherItem(Gopher.info())

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
