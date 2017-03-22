require 'socket'                # Get sockets from stdlib
require 'sqlite3'

class Server
  attr_reader :port, :id
  def initialize(port, id = rand(6**8).to_s(36))
    @id = id
    @port = port
    @state = true
    @clients = []
    @server
    puts 'Server Created'
  end

  def start
    @state = true
    puts 'Server started'
    connect
    run
  end

  def stop
    @state = false
    disconnect
  end

  def connect
    i=0
    begin
      @server = TCPServer.open(@port)
      i = 1
      @db = SQLite3::Database.open "#{@id}.db"
      createdb
      @db.execute "UPDATE XDK SET STATE = 0"

    rescue
      puts "Can't connect on Port: " + @port.to_s if i ==0
      puts "Can't connect to the Database: " if i ==1
    end
  end

  def disconnect
    i=0
      @clients.each{ |c| c.close}
      @server.close
      i = 1
      @db.execute "UPDATE XDK SET STATE = 0"
      @db.close

    puts 'Server stopped'
  end

  def run
    Thread.new{
      while @state
        Thread.start(@server.accept) do |client|
          id = client.gets.chomp
          puts 'Client ID: ' + id + ' Connected to this server'


          inc = @db.execute "SELECT * FROM XDK WHERE ID = '#{id}' "

          @clients << client
          if inc.empty?
            registerclient(id)
          end
          @db.execute "UPDATE XDK SET STATE = 1 WHERE ID = '#{id}' "
          c = 0
          while line = client.gets # Read lines from socket
            aux = Marshal.load(line)
            c += 1
            save(aux[0],aux[1],aux[2],aux[3],aux[4],aux[5])
          end
          puts 'Client ID: ' + id + ' Disconnected from this server'
          puts 'Client ID: ' + id + ' Made ' + c.to_s + ' reads in the last session'
          @db.execute "UPDATE XDK SET STATE = 0 WHERE ID = '#{id}'"
          @clients.delete(id)
        end
      end
    }
  end

  def createdb
    @db.execute "CREATE TABLE IF NOT EXISTS XDK(
    ID    VARCHAR(10) PRIMARY KEY,
    STATE INT NOT NULL
    );"

    @db.execute "CREATE TABLE IF NOT EXISTS XDK_DATA(
   ID INTEGER PRIMARY KEY   ,
   XDK_ID        VARCHAR(10) NOT NULL,
   TIMESTAMP     VARCHAR(40) NOT NULL,
   TEMPERATURE   FLOAT,
   ACOUSTIC      FLOAT,
   LATITUDE      FLOAT NOT NULL,
   LONGITUDE     FLOAT NOT NULL,
   FOREIGN KEY (XDK_ID) REFERENCES XDK(ID)
   );"
  end

  def registerclient(id)
    @db.execute "INSERT INTO XDK VALUES('#{id}', 1)"
  end

  def save(id, temperature, acoustic, time, latitude, longitude)
    begin
      @db.execute "BEGIN"
      @db.execute "INSERT INTO XDK_DATA(ID , XDK_ID, TIMESTAMP, TEMPERATURE,ACOUSTIC, LATITUDE, LONGITUDE) VALUES( null,'#{id}','#{time}',#{temperature},#{acoustic},#{latitude},#{longitude})"
      @db.execute "END"
    rescue
    end
  end

  def showclients
    array = @db.execute "SELECT ID FROM XDK WHERE STATE == 1 "
    puts 'Connected Clients :'
    puts '                   LOCATION:'
    puts 'CLIENT       LATITUDE    LONGITUDE'
    puts '------------------------------------'
    if array.empty?
      puts "There is no clients connected to"
      puts "this server"
    else
      array.each{ |x|
        gps = @db.execute "SELECT LATITUDE, LONGITUDE FROM XDK_DATA WHERE ID =(SELECT MAX(ID) FROM XDK_DATA WHERE XDK_ID LIKE '%#{x[0]}%')"

        if !gps.empty?
          aux = gps[0]
          puts x[0].to_s + "         " + aux[0].round(6).to_s + "   " +aux[1].round(6).to_s
        else
          puts x[0].to_s + "         " +  "There is no last "
          puts "             location of this client "
        end
      }

    end
    puts '------------------------------------'
  end

  def showreads(client, sensor = nil)

    if @db.execute( "SELECT * FROM XDK  WHERE ID LIKE '%#{client}%'").any?
      if sensor == 'temperatura'
        array = @db.execute "SELECT TIMESTAMP, TEMPERATURE FROM XDK_DATA WHERE XDK_ID LIKE '%#{client}%' AND TEMPERATURE IS NOT NULL "
        issensor = true
      elsif sensor == 'acustico'
        array = @db.execute "SELECT TIMESTAMP, ACOUSTIC FROM XDK_DATA WHERE XDK_ID LIKE '%#{client}%' AND ACOUSTIC IS NOT NULL"
        issensor = true
      elsif sensor == 'gps'
        array = @db.execute "SELECT TIMESTAMP, LATITUDE, LONGITUDE FROM XDK_DATA WHERE XDK_ID LIKE '%#{client}%' "
        issensor = true
      else
        array = @db.execute "SELECT * FROM XDK_DATA WHERE XDK_ID LIKE '%#{client}%' "
        issensor = false
      end
      puts "Client: #{client}"

      if array.empty?
        puts "There are no registers of the client #{client} in the database"
      else
        if !issensor
          printall(array)
        else
          printsensor(array, sensor)
        end
      end
    else
      puts "There are no client #{client} registered in this server"
    end


  end

  def printsensor(array, sensor)
    if sensor == 'gps'
      puts 'Timestamp:                  Latitude:    Longitude:'
      puts '----------------------------------------------------'
      array.each{|aux|
        aux[1] = '%.6f' % aux[1]
        aux[2] = '%.6f' % aux[2]
        puts aux[0].to_s + '    ' + aux[1].to_s + '    ' + aux[2].to_s
      }
      puts '----------------------------------------------------'
    else
      puts "Timestamp:                  #{sensor.capitalize}:"
      puts '----------------------------------------'
      array.each{|aux|
        aux[1] = '%.2f' % aux[1]
        puts aux[0].to_s + '    ' + aux[1].to_s
      }
      puts '----------------------------------------'
    end
  end

  def printall(array)
    puts "Timestamp:                  Temperature:    Acoustic:     Latitude:    Longitude: "
    puts '-----------------------------------------------------------------------------------'
    array.each{|aux|
      if aux[3] == nil
        aux[3] = '-----'
      else
        aux[3] = '%.2f' % aux[3]
      end
      if aux[4] == nil
        aux[4] = '-----'
      else
        aux[4] = '%.2f' % aux[4]
      end
      aux[5] = '%.6f' % aux[5]
      aux[6] = '%.6f' % aux[6]

      puts aux[2].to_s + "    " + aux[3].to_s  + "ºC         " + aux[4].to_s +  "         " + aux[5].to_s + "º   " + aux[6].to_s + "º"
    }
    puts '-----------------------------------------------------------------------------------'
  end
end
