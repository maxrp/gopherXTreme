use "itertools"
use "format"

type Alignment is (AlignLeft val | AlignRight val | AlignCenter val)

class GopherItem is Stringable
  let item_type: String
  let display_string: String
  let selector: String
  var _align: Alignment = AlignLeft
  var host: String = "NULL"
  var port: String = "0"

  new create(item_type': String, display_string': String,
    selector': String, host': String, port': String, align: Alignment = AlignLeft) =>
    _align = align
    item_type = item_type'
    display_string = display_string'
    selector = selector'
    host = host'
    port = port'

  new i(display_string': String, align: Alignment = AlignLeft) =>
    _align = align
    item_type = "i"
    selector = ""
    display_string = display_string'

  new link(display_string': String, url: String) =>
    item_type = "h"
    selector = "URL:"+url
    display_string = display_string'

  new spacer() =>
    item_type = "i"
    display_string = ""
    selector = ""

  fun string(): String iso^ =>
    "\t".join(Iter[String]([
      item_type+Format(display_string where width=70, align=_align)
      selector
      host
      port].values()))

class GopherMessage is Stringable
  let header: Array[GopherItem]
  let items: Array[GopherItem]
  let footer: Array[GopherItem]

  new create(header': Array[GopherItem],
    items': Array[GopherItem],
    footer': Array[GopherItem]) =>
    header = header'
    items = items'
    footer = footer'

  fun string(): String iso^ =>
    var message = recover String end
    for item in [header; items; footer].values() do
      message.append("\r\n".join(Iter[Stringable](item.values())))
      message.append("\r\n")
    end
    message.append(".\r\n")
    message
