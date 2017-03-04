require 'socket'                # Get sockets from stdlib
require 'sqlite3'

class Server
  attr_reader :port
  def initialize(port)
    @id = rand(6**8).to_s(36)
    @port = port
    @state = true
    @clients = []
    @server
    puts 'Server Created with ID: ' + @id
  end

  def connect
    @server = TCPServer.open(@port)
  end

  def disconnect
    @clients.each{ |c| c.close}
  end

  def run
    Thread.new{
      while @state                         # Servers run forever
        Thread.start(@server.accept) do |client|
          @clients << client
          id = client.gets
          puts 'Client ID: ' + id + ' Connected to this server'
          c = 0
          while line = client.gets # Read lines from socket
            aux = Marshal.load(line)
            puts " Temp: " + aux[0].to_s + " Aco: " + aux[1].to_s + " Time: " + aux[2].to_s + " Lat: " + aux[3].to_s + " Lon: " + aux[4].to_s
            c += 1
          end
          puts 'Client ID: ' + id + ' Disconnected from this server'
          puts 'Client ID: ' + id + ' Made ' + c.to_s + ' reads in the last session'
        end
      end
    }
  end

  def start
    @state = true
    puts 'Server started'
    connect
    run
  end

  def stop
    @state = false
    puts 'Server stoped'
    disconnect
  end
end