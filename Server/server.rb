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

  def connect
    i=0
    begin
      @server = TCPServer.open(@port)
      i = 1
      @db = SQLite3::Database.open "engweb.db"
      createdb
    rescue
      puts "Can't connect on Port: " + @port.to_s if i ==0
      puts "Can't connect to the Database: " if i ==1
    end
  end

  def disconnect
    i=0
    begin
      @clients.each{ |c| c.close}
      i = 1
      @db.close
    rescue
      puts "Can't disconnect clients from server" + @port.to_s if i ==0
      puts "Can't disconnect from the Database: " if i ==1
    end
  end

  def run
    Thread.new{
      while @state
        Thread.start(@server.accept) do |client|
          id = client.gets.chomp
          puts 'Client ID: ' + id + ' Connected to this server'

          if !@clients.include?(id.to_s)
            @clients << id
            registerclient(id)
          end
          c = 0
          while line = client.gets # Read lines from socket
            aux = Marshal.load(line)
            puts " Temp: " + aux[0].to_s + " Aco: " + aux[1].to_s + " Time: " + aux[2].to_s + " Lat: " + aux[3].to_s + " Lon: " + aux[4].to_s
            c += 1
            save(aux[0],aux[1],aux[2],aux[3],aux[4],aux[5])
          end
          puts 'Client ID: ' + id + ' Disconnected from this server'
          puts 'Client ID: ' + id + ' Made ' + c.to_s + ' reads in the last session'
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
    puts '-----------------------------------'
    array.each{ |x|
      gps = @db.execute "SELECT LATITUDE, LONGITUDE FROM XDK_DATA WHERE ID =(SELECT MAX(ID) FROM XDK_DATA WHERE XDK_ID LIKE '%#{x[0]}%')"

      if !gps.empty?
        aux = gps[0]
        puts x[0].to_s + "         " + aux[0].round(6).to_s + "   " +aux[1].round(6).to_s
      else
        ''
      end
    }
  end

  def showreads(client)
    array = @db.execute "SELECT * FROM XDK_DATA WHERE XDK_ID LIKE '%#{client}%' "
    if array.empty?
      puts "There is no registers of the client #{client} in the database"
    else
      puts "Client: #{client}"
      puts "Timestamp:                  Temperature:    Acoustic:     Latitude:    Longitude: "
      puts '-----------------------------------------------------------------------------------'
      array.each{|aux|
        puts aux[2].to_s + "   " + aux[3].round(2).to_s + "ºC         " + aux[4].round(2).to_s +  "         " + aux[5].round(6).to_s + "º   " + aux[6].round(6).to_s + "º"
      }
    end
    puts '-----------------------------------------------------------------------------------'
  end
end