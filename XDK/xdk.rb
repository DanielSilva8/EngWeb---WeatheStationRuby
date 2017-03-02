require 'socket'

class XDK
  attr_reader :id, :name, :hostname, :port, :nf
  def initialize(id, name, hostname ,port, nf)
    @id=id
    @name=name
    @observers=[[hostname, port]]
    @temperature=0
    @acoustic=0
    @notifyfrequency=nf
    @state = true
    @mysocket = []
  end

  def registerobserver(hostname, port)
    @observers += [[hostname, port]]
    connect
  end

  def removeobserver(hostname, port)
    i=0
    @observers.each { |x|
    if x[0] == hostname and x[1]==port
      break
    end
      i += 1
    }
    @observers -= [[hostname, port]]
    @mysocket -= [@mysocket[i]]
    connect
  end

  def notifyobservers
    array = [@id, @temperature, @acoustic, Time.now.ctime]
    aux = Marshal.dump(array)
    @mysocket.each { |x| send(x, aux)}
  end

  def connect
    @mysocket.each{ |s| s.close}
    @mysocket = []
    puts 'Connecting to Server'
    i=0
    @observers.each { |x|
      begin
        @mysocket[i] = TCPSocket.new(x[0], x[1].to_s)
        i+=1
     # rescue
      #  puts "Connection failed on Host: " + x[0].to_s + " Port: " + x[1].to_s
      end
    }
    return true if i > 0
    return false
  end

  def send(socket,data)
    socket.flush
    socket.puts(data)
  end

  def disconnect
    puts 'closing active connections'
    @mysocket.each{ |s| s.close}
    @mysocket = []
    puts 'done'
  end

  def run
    puts 'Sending data'
    Thread.new{
      while @state do
        update
        notifyobservers
        sleep(@notifyfrequency)
      end
    }
  end

  def update
    if @temperature == 0
        @temperature = rand(7.0...32.9)
    else
        @temperature +=  rand - rand
    end
    @acoustic = rand(20.0...119.9)
  end

  def start
    @state = true
    run if connect
  end

  def stop
    @state = false
    disconnect
  end
end
