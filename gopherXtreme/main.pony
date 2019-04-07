use "cli"
use "net"

actor Main
  new create(env: Env) =>
    // Define the CommandSpec for CommandParser
    let cs =
    try
      CommandSpec.leaf("gopherXtreme", "A gopher daemon, version: "+Version(), [
        OptionSpec.u64("port", "TCP port to listen on."
          where short' = 'P', default' = 70)
        OptionSpec.string("hostname", "Hostname or IP to listen on."
          where short' = 'H', default' = "127.0.0.1")
        OptionSpec.string("directory", "Directory to serve via Gopher://"
          where short' = 'D', default' = "./")
      ])? .> add_help()?
    else
      env.exitcode(-1)
      return
    end

    // Parse the command
    let cmd =
    match CommandParser(cs).parse(env.args, env.vars)
    | let c: Command => c
    | let ch: CommandHelp =>
      ch.print_help(env.out)
      env.exitcode(0)
      return
    | let se: SyntaxError =>
      env.out.print(se.string())
      env.exitcode(1)
      return
    end

    // Define connection variables from options.
    let port = cmd.option("port").u64()
    let hostname: String = cmd.option("hostname").string()
    //TODO: directory isn't wired up to anything yet.
    let directory: String = cmd.option("directory").string()
    // Is there a better way to do the validation here?
    if port > 65535 then
      env.out.print("Port given is "+port.string()+", should be <= 65535.")
      env.exitcode(1)
      return
    end

    // Spin up the GopherListener
    try
      TCPListener(env.root as AmbientAuth,
          recover GopherListener(env.out, directory) end, hostname, port.string())
    else
      env.exitcode(1)
      return
    end
