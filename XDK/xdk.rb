require 'socket'

class XDK
  attr_reader :hostname, :port, :nfTemp, :nfAco
  def initialize(hostname ,port, nfTemp, nfAco)
    @id=rand(6**8).to_s(36)
    @observers=[[hostname, port]]
    @nfTemp=nfTemp
    @nfAco=nfAco
    @state = true
    @mysocket = []
    puts 'XDK Created with ID: ' + @id
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

  def registerobserver(hostname, port)
    begin
      @mysocket += [TCPSocket.new(hostname, port)]
      @observers += [[hostname, port]]
    rescue
        puts "Connection failed on Host: " + hostname + " Port: " + port.to_s
    end
    puts "Host: " + hostname + " Port: " + port.to_s + "Registered"
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
    puts "Host: " + hostname + " Port: " + port.to_s + "Removed"
  end

  def notifyobservers(temperature , acoustic, time, latitude, longitude)
    array = [@id, temperature, acoustic, time, latitude, longitude]
    aux = Marshal.dump(array)
    i = 0
    @mysocket.each { |x| send(x, aux, i) ; i += 1}
    if i == 0
      puts 'No active connections'
      puts 'Stoping Sending Data'
      @state = false
    end
  end

  def disconnect
    puts 'Closing active connections'
    @mysocket.each{ |s| s.close}
    @mysocket = []
    @state = false
  end

  def connect
    @mysocket.each{ |s| s.close}
    @mysocket = []
    puts 'Connecting to Server'
    i=0
    @observers.each { |x|
      begin
        @mysocket[i] = TCPSocket.new( x[0].to_s, x[1])
        send(@mysocket[i], @id.to_s, i)
        i+=1
      rescue
        puts "Connection failed on Host: " + x[0].to_s + " Port: " + x[1].to_s
      end
    }
    return true if i > 0
    return false
  end

  def send(socket,data,id)
        begin
          socket.flush
          socket.puts(data)
        rescue
          aux = @observers[id]
          puts "Connection failed on Host: " + aux[0].to_s + " Port: " + aux[1].to_s
          puts "Deleting Connection"
          @mysocket -= [socket]
          @observers -= [aux]
        end
  end

  def run
    puts 'Sending data'
    Thread.new{
      tinitial = Time.now
      a = 0
      t = 0
      while @state do
        if (Time.now - tinitial) >= a and (Time.now - tinitial) >= t
          notifyobservers(getTemperature, getAcoustic, Time.now.to_s, getGPS[0], getGPS[1])
          a += @nfAco
          t += @nfTemp
        elsif (Time.now - tinitial) >= a
          notifyobservers(nil, getAcoustic, Time.now.ctime, getGPS[0], getGPS[1])
          a += @nfAco
        end
      end
    }
  end

  def getTemperature
    return rand(20.0...24.9)
  end

  def getAcoustic
    return rand(80.0...119.9)
  end

  def getGPS

    return [rand(0.0...90.0), rand(0.0...180.0)]
  end
end
