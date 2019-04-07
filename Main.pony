use "net"

actor Main
    new create(env: Env) =>
        try
            TCPListener(env.root as AmbientAuth,
                    recover GopherListener(env.out) end, "", "7001")
        else
            env.out.print("unable to use the network")
        end
