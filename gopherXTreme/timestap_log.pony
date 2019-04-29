use "logger"
use "time"

class TimestampLogFormatter is LogFormatter
  let _time_fmt: String

  new val create(time_fmt': String) =>
    _time_fmt = time_fmt'

  fun apply(msg: String, loc: SourceLoc): String =>
    let timestamp =
      try
        PosixDate(Time.seconds()).format(_time_fmt)?
      else
        "TIME ERR"
      end

    (recover
      String(timestamp.size() + msg.size() + 1)
    end)
     .> append(timestamp)
     .> append(" ")
     .> append(msg)

