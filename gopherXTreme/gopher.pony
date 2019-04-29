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

class GopherItem is Stringable
  let item_type: U8
  var display_string: String = ""
  var selector: String = ""
  var _align: Align = AlignLeft
  var host: String = "NULL"
  var port: String = "0"

  new create(item_type': U8,
             display_string': String,
             selector': String,
             host': String,
             port': String,
             align': Align = AlignLeft) =>
    _align = align'
    item_type = item_type'
    display_string = display_string'
    selector = selector'
    host = host'
    port = port'

  new i(display_string': String, align: Align = AlignLeft) =>
    _align = align
    item_type = Gopher.info()
    display_string = display_string'

  new link(display_string': String, url: String) =>
    item_type = Gopher.html()
    selector = "URL:" + url
    display_string = display_string'

  new spacer() =>
    item_type = Gopher.info()

  fun string(): String iso^ =>
    let final_display_string =
      if display_string.size() < 70 then
        Format(display_string where width=70, align=_align)
      elseif display_string.size() > 70 then
        display_string.trim(0, 70)
      else
        display_string
      end
    // 74: description length of 70 + 3 tabs and 1 item_type
    (recover
      String(74 + selector.size() + host.size() + port.size())
    end)
      .> unshift(item_type)
      .> append(final_display_string)
      .> append("\t")
      .> append(selector)
      .> append("\t")
      .> append(host)
      .> append("\t")
      .> append(port)

class GopherMessage is Stringable
  let header: Array[GopherItem]
  let items: Array[GopherItem]
  let footer: Array[GopherItem]

  new create(header': Array[GopherItem],
             items': Array[GopherItem]) =>
    header = header'
    items = items'
    footer = [GopherItem.spacer()
              GopherItem.i(ProductNameAndVersion()
                where align=AlignRight)]

  fun string(): String iso^ =>
    var message = recover String end
    for item in [header; items; footer].values() do
      message.append(Gopher.eol().join(Iter[Stringable](item.values())))
      message.append(Gopher.eol())
    end
    message.append(Gopher.eom())
    message
