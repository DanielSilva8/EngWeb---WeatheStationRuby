require 'socket'

class XDK

  attr_reader :id, :name, :hostname, :port, :nf
  def initialize(id, name, hostname ,port, nf)
    @id=id
    @name=name
    @observers=[[hostname, port]]
    @temperature=0
    @acoustic=0
    @NotifyFrequency=nf
    @state = true

  end

  def registerObserver(hostname, port)
    @observers += [[hostname, port]]
  end

  def removeObserver(hostname, port)
    @observers -= [[hostname, port]]
  end

  def notifyObservers()
    @observers.each { |x| send(x[1], x[0]) }
      #puts "Host: " + x[1].to_s + " Port: " + x[0].to_s + " Temp: " + @temperature.to_s + " Aco: " + @acoustic.to_s }

  end

  def send(hostname,port)
    s = TCPSocket.open(hostname, port)

    while line = s.gets   # Read lines from the socket
      puts line.chop      # And print with platform line terminator
    end
    s.close               # Close the socket when done
  end

  def run
    #Thread.new{
      while @state do
        sleep(@NotifyFrequency)
        update
        notifyObservers
      end
    #}
  end

  def update
    if @temperature == 0
        @temperature = rand(7.0...32.9)
    else
        @temperature +=  rand() - rand()
    end
    @acoustic = rand(20.0...119.9)
  end

  def start
    @state = true
    run
  end

  def stop
     @state = false
  end
end

#myXDK = XDK.new(1, 'XDK1','localhost', 2000, 5)
#myXDK.registerObserver('191.1.1.2', 3000)
#myXDK.start()