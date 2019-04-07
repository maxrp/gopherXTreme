use "net"

class GopherServer is TCPConnectionNotify
	let _out: OutStream
	var _remote_ip: String = ""
	var _port: String = ""

	new iso create(out: OutStream) =>
		_out = out

	fun ref accepted(conn: TCPConnection ref) =>
		_out.print("connection accepted")

	fun ref received(conn: TCPConnection ref, data: Array[U8] iso,
		times: USize): Bool
	=>
		try
			(_remote_ip, _port) = conn.remote_address().name()?
		end
		var reqstr: String = String.from_array(consume data)
		if reqstr == "\r\n" then
			_out.print(_remote_ip + " requested index.")
			conn.write("iThis is an experimental gopher server.\tfake\t(NULL)\t0\r\n")
			conn.write("hAbout me\tURL:https://maxp.info/\t(NULL)\t0\r\n")
			conn.write("iYour IP is: " + _remote_ip + "\tfake\t(NULL)\t0\r\n")
			conn.write(".\r\n")
		else
			var request: String = reqstr.clone().>rstrip()
			_out.print(_remote_ip + " requested '"+request+"'")
		end
		conn.dispose()
		true

	fun ref closed(conn: TCPConnection ref) =>
		_out.print("connection closed")

	fun ref connect_failed(conn: TCPConnection ref) =>
		_out.print("connect failed")
