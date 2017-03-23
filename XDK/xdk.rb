require 'socket'

class XDK
  attr_reader :hostname, :port, :nfTemp, :nfAco
  def initialize(hostname ,port, nfTemp, nfAco)
    @id= rand(6**8).to_s(36)
    @observers=[[hostname, port]]
    @nfTemp=nfTemp
    @nfAco=nfAco
    @timerA = 0
    @timerT = 0
    @state = true
    @notify = []
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
      socket = TCPSocket.new(hostname, port)
      send(socket, @id.to_s, -1)
      @mysocket += [socket]
      @observers += [[hostname, port]]
    rescue
      puts "Connection failed on Host: " + hostname + " Port: " + port.to_s
    end
    puts "Host: " + hostname + " Port: " + port.to_s + " Registered"
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
    puts "Host: " + hostname + " Port: " + port.to_s + " Removed"
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
    @mysocket.each{ |s|
      s.close }
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
      @tinitial = Time.now
      @timerA = 0
      @timerT = 0
      while @state do
        sleep(0.5)
        (temp,@timerT) = notify?(@tinitial,@timerT, 1) if !@notify[0]
        (aco,@timerA) = notify?(@tinitial,@timerA, 2) if !@notify[1]
        if @notify.include?(true)
          notifyobservers(temp ,aco ,Time.now.ctime, getGPS[0], getGPS[1])
          @notify = [false, false]
        end
      end
    }
  end

  def notify?(tinitial, a, type)
    if (Time.now - tinitial) >= a
      case type
        when 1
          a += @nfTemp
          @notify[0] = true
          return [getTemperature,a ]
        when 2
          @notify[1] = true
          a += @nfAco
          return [getAcoustic, a ]
      end
    else
      return ['null', a]
    end
  end

  def getTemperature
    return rand(20.0...24.9)
  end

  def getAcoustic
    return rand(80.0...99.9)
  end

  def getGPS
    return [rand(10.0...90.0), rand(10.0...180.0)]
  end
  def changenotifyfrequency(param1, param2)
    if param2.is_a? Integer
      @nfTemp = param1
      @nfAco = param2

    elsif param2 == 'temperatura'
      @nfTemp = param1
    elsif param2 == 'acustico'
      @nfAco = param1
    end
    @tinitial = Time.now
    @timerA = 0
    @timerT = 0
    notifyobservers(getTemperature ,getAcoustic ,Time.now.ctime, getGPS[0], getGPS[1])
  end
end

