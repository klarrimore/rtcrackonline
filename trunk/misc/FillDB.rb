class FillDB

  require "mysql"
  require "progressbar"

  def initialize(rtName)
    @be = 0
    @bytesWritten = 0
    @tableNum = rtName[rtName.rindex(/_._/) + 1].chr.to_i
    @fileSize = 0
    @pbar = ""

    begin
      @fileSize = File.stat(rtName).size
      table = File.open(rtName, "r")
    rescue
      $stderr.print "Couldn't open " + rtName + "\n"
      exit
    end
    
    print "Attempting to insert " + rtName + " into the Database.\n"
    @pbar = ProgressBar.new("Progress", 10)
	
    breakUpRTable(table)

    (@tableNum + 1).upto(4) do
      @be = 0
      @bytesWritten = 0
      @tableNum += 1
      
      rtName[/_._/] = "_" + ((rtName[13].chr.to_i + 1).to_s) + "_"
      
      begin
        @fileSize = File.stat(rtName).size
        table = File.open(rtName, "r")
      rescue
        exit
      end
      
      print "Attempting to insert " + rtName + " into the Database.\n"
      @pbar = ProgressBar.new("Progress", 10)
	  
      breakUpRTable(table)
    
    end
  end

  def putInDB(byteArray)
    db = Mysql.real_connect("localhost", "rainbow", "rainb0w", "rainbow");
    i = 7
    
    while i < byteArray.length
      temp1 = []
      temp2 = []
      temp3 = "" 
      temp4 = ""

      0.upto(7) {|x| temp1[x] = sprintf("%02x", byteArray[i-x])}
      i += 8
      temp3 = temp1.to_s
      temp3.slice!(/^[0]+/)

      0.upto(7) {|x| temp2[x] = sprintf("%02x", byteArray[i-x])}
      i += 8
      temp4 = temp2.to_s
      temp4.slice!(/^[0]+/)

      mysqlTable = "testing" + @tableNum.to_s 
      
      db.query("INSERT INTO `#{mysqlTable}` (`index`, `begin`, `end`)
                VALUES ('#{@be}', '#{temp3}', '#{temp4}')
              ")

      @be+=1
      
    end
  end

  def breakUpRTable(table)
    index = 0
    progressPoint = 0
    progressString = ""
    byteArray = []
    
    table.each_byte do |byte|
      if index < 49999 
        byteArray[index] = byte
        index += 1
      elsif index == 49999
        putInDB(byteArray)	  
        index = 0
        byteArray = []
        @bytesWritten += 50000
	#print @bytesWritten, "\n"
	#print "\n"
	#print ((@bytesWritten.to_f / @fileSize.to_f) * 100).floor, "\n"
	case ((@bytesWritten.to_f / @fileSize.to_f) * 100).floor
	  when 10...19 then
	    if progressPoint < 10
	      @pbar.inc
	      progressPoint = 10
	    end
	  when 20...29 then
	    if progressPoint < 20
	      @pbar.inc
	      progressPoint = 20
	    end 
	  when 30...39 then
	    if progressPoint < 30
	      @pbar.inc
	      progressPoint = 30
	    end
	  when 40...49 then
	    if progressPoint < 40
	      @pbar.inc
	      progressPoint = 40
	    end
	  when 50...59 then
	    if progressPoint < 50
	      @pbar.inc
	      progressPoint = 50
	    end
	  when 60...69 then
	    if progressPoint < 60
	      @pbar.inc
	      progressPoint = 60
	    end
	  when 70...79 then
	    if progressPoint < 70
	      @pbar.inc
	      progressPoint = 70
	    end
	  when 80...89  then
	    if progressPoint < 80
	      @pbar.inc
	      progressPoint = 80
	    end
	  when 90...99 then
	    if progressPoint < 90
	      @pbar.inc
	      progressPoint = 90
	    end
	  else
	end
        #print "wrote " + @bytesWritten.to_s + "\n"
      else
        print "the index is jacked\n"
      end
    end
    
    putInDB(byteArray)
    @pbar.inc
    progressPoint = 0 
    
    print "\nSuccessfully inserted " + (@bytesWritten + byteArray.size).to_s + " bytes\n\n"
    
    table.close_read unless table.nil?
  
  end
end
