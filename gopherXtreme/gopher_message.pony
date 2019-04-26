use "itertools"
use "format"

primitive Gopher
  // RFC1436 types
  fun file():         U8 => '0'
  fun directory():    U8 => '1'
  fun cso():          U8 => '2'
  fun err():          U8 => '3'
  fun dos_binary():   U8 => '5'
  fun uuencoded():    U8 => '6'
  fun index_search(): U8 => '7'
  fun telnet():       U8 => '8'
  fun binary():       U8 => '9'
  fun mirror():       U8 => '+'
  fun tn320():        U8 => 'T'
  fun gif():          U8 => 'g'
  fun image():        U8 => 'I'
  // the practical types
  fun html():         U8 => 'h'
  fun info():         U8 => 'i'
  fun sound():        U8 => 's'

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
             align: Align = AlignLeft) =>
    _align = align
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
    // 74: description length of 70 + 3 tabs and 1 item_type
    (recover
      String( 74 + selector.size() + host.size() + port.size())
    end)
      .> unshift(item_type)
      .> append(Format(display_string where width=70, align=_align))
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
              GopherItem.i("gopherXtreme/" + Version()
                where align=AlignRight)]

  fun string(): String iso^ =>
    var message = recover String end
    for item in [header; items; footer].values() do
      message.append("\r\n".join(Iter[Stringable](item.values())))
      message.append("\r\n")
    end
    message.append(".\r\n")
    message
