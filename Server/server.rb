require 'socket'                # Get sockets from stdlib

class Server
  def initialize
    server = TCPServer.open(2000) # Socket to listen on port 2000
    @clients = []
    loop {                          # Servers run forever
      Thread.start(server.accept) do |client|
        @clients << client
        client.i
        while line = client.gets # Read lines from socket
          aux = Marshal.load(line)        # and print them
          puts "Client: " + aux[0].to_s + " Temp: " + aux[1].to_s + " Aco: " + aux[2].to_s
        end
       #client.puts(Time.now.ctime) # Send the time to the client
       #client.puts "Closing the connection. Bye!"
       #client.close                # Disconnect from the client
      end
    }
  end

end
