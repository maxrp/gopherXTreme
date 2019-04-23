use "backpressure"
use "cli"
use "files"
use "logger"
use "net"

actor Main
  let _env: Env

  new create(env: Env) =>
    _env = env

    // Define the CommandSpec for CommandParser
    let cs =
    try
      CommandSpec.leaf("gopherXtreme",
                       "A gopher daemon, version: "+Version(),
      [
        OptionSpec.u64("port", "TCP port to listen on."
          where short' = 'P', default' = 70)
        OptionSpec.string("hostname", "Hostname or IP to listen on."
          where short' = 'H', default' = "127.0.0.1")
        OptionSpec.string("directory", "Server base directory."
          where short' = 'D', default' = Path.cwd())
      ])? .> add_help()?
    else
      _err("Failed to construct CommandSpec, weird.", 1)
      return
    end

    // Parse the command
    let cmd =
    match CommandParser(cs).parse(env.args, env.vars)
    | let c: Command => c
    | let ch: CommandHelp =>
      _err(ch.help_string(), 0)
      return
    | let se: SyntaxError =>
      _err(se.string(), 1)
      return
    end

    // Define connection variables from options.
    let port = cmd.option("port").u64()
    let hostname = cmd.option("hostname").string()
    let directory = cmd.option("directory").string()

    // Is there a better way to do the validation here?
    if port > 65535 then
      _err("Port is " + port.string() + ", but should be <= 65535.", 1)
      return
    end
    let port_str = port.string()

    // Provision the FilePath scope for the children
    let server_path =
    try
      FilePath(env.root as AmbientAuth, directory)?
    else
      _err("Failed to provision capabilities for: " + directory, 1)
      return
    end

    // Set up the logging facility
    let log_formatter = TimestampLogFormatter("[%v %H:%M:%S] ")
    let logger = StringLogger(
      Fine,
      env.out,
      log_formatter)

    // Spin up the GopherListener
    try
      TCPListener(env.root as AmbientAuth,
                  recover GopherListener(env.root as BackpressureAuth,
                                         logger,
                                         server_path,
                                         hostname,
                                         port_str.clone())
                  end,
                  hostname,
                  port_str.clone())
    else
      _err("Failed to start TCPListener.", 1)
      return
    end

  fun _err(message: String, err_code: I32) =>
    _env.out.print(message)
    _env.exitcode(err_code)
