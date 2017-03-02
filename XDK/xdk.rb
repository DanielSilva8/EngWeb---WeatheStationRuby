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
    begin
      @mysocket += [TCPSocket.new(hostname, port)]
    rescue
        puts "Connection failed on Host: " + x[0].to_s + " Port: " + x[1].to_s
    end
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
    @mysocket[i].close
    @mysocket -= [@mysocket[i]]

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
        @mysocket[i] = TCPSocket.new( x[0].to_s, x[1])
        i+=1
      rescue
        puts "Connection failed on Host: " + x[0].to_s + " Port: " + x[1].to_s
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
    puts 'Closing active connections'
    @mysocket.each{ |s| s.close}
    @mysocket = []
    puts 'Done'
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
    if connect
      run
    else
      puts 'No active connections'
    end
  end

  def stop
    @state = false
    disconnect
  end
end

myX = XDK.new(1,'k','localhost',2000, 5)
myX.registerobserver('localhost', 3000)
myX.start
sleep(15)

sleep(15)
myX.stop