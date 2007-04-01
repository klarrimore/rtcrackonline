#!/usr/bin/ruby 

#TODO go through this a reformat it

#require 'hashwrapper'
require 'socket'
require 'thread'

# Do this so we can have rail's models

require File.dirname(__FILE__) + './../config/boot'
ENV["RAILS_ENV"] = 'development'
require RAILS_ROOT + '/config/environment'
@logger = RAILS_DEFAULT_LOGGER

@validArray = ("a".."f").to_a + ("0".."9").to_a

# As the name implies the function inserts the text for a hash when it's found
def insertIntoDB(hash, text)
      
  @logger.info "DEBUG: adding hash: #{hash} and text: #{text} to the database" if DEBUG
  
  #Hopefully there won't be a race condition
  @mutex.synchronize do
  begin
    ActiveRecord::Base.establish_connection
      if PopularMatch.find(:first, :conditions => ["hash = ?", hash]).nil?
        popularmatch = PopularMatch.new
	popularmatch.hash = hash
	popularmatch.text = text
        popularmatch.save
      end
    ActiveRecord::Base.remove_connection
  rescue
    @logger.info "There was an error entering the hash: #{hash} and text: #{text} in the database. #{$!.to_s}"
  end
  end

  #Hopefully there won't be a race condition
  @mutex.synchronize do
  begin
    ActiveRecord::Base.establish_connection
      half1WebrtMatches = Webrt.find(:all, :conditions => ["lmhash_half1 = ? and status != 'finished' and text IS NULL", hash])
      half1WebrtMatches.each do |half1WebrtMatch|
        half1WebrtMatch.update_attributes(:text_half1 => text, :cracked_half1 => true)
        if (half1WebrtMatch.lmhash).length == 16
	  hours, minutes, seconds = DateTime.day_fraction_to_time(DateTime.now - DateTime.parse(half1WebrtMatch.created_on.to_s))
	  elapsedTime = sprintf("%02d:%02d:%02d", hours, minutes, seconds)
	  half1WebrtMatch.update_attributes(:text => text, :cracked_half1 => true, :elapsed_time => elapsedTime, :status => "finished")
          Notifier::deliver_send_out(half1WebrtMatch.email, half1WebrtMatch.lmhash, half1WebrtMatch.text) if !half1WebrtMatch.email.nil?
	elsif (half1WebrtMatch.lmhash).length == 32 && half1WebrtMatch.cracked_half1 == true && half1WebrtMatch.cracked_half2 == true
	  hours, minutes, seconds = DateTime.day_fraction_to_time(DateTime.now - DateTime.parse(half1WebrtMatch.created_on.to_s))
	  elapsedTime = sprintf("%02d:%02d:%02d", hours, minutes, seconds)	    
          if text == "not found"
	    half1WebrtMatch.update_attributes(:text => "not found", :cracked_half1 => true, :cracked_half2 => true, :elapsed_time => elapsedTime, :status => "finished")
	  elsif text.nil? && half1WebrtMatch.text_half2.nil?
	    half1WebrtMatch.update_attributes(:text => "", :cracked_half1 => true, :cracked_half2 => true, :elapsed_time => elapsedTime, :status => "finished")
	  elsif text.nil?
	    half1WebrtMatch.update_attributes(:text => half1WebrtMatch.text_half2, :cracked_half1 => true, :cracked_half2 => true, :elapsed_time => elapsedTime, :status => "finished")
	  elsif half1WebrtMatch.text_half2.nil?
	    half1WebrtMatch.update_attributes(:text => half1WebrtMatch.text_half1, :cracked_half1 => true, :cracked_half2 => true, :elapsed_time => elapsedTime, :status => "finished")
	  else
	    half1WebrtMatch.update_attributes(:text => half1WebrtMatch.text_half1 + half1WebrtMatch.text_half2, :cracked_half1 => true, :cracked_half2 => true, :elapsed_time => elapsedTime, :status => "finished")
	  end
	  Notifier::deliver_send_out(half1WebrtMatch.email, half1WebrtMatch.lmhash, half1WebrtMatch.text) if !half1WebrtMatch.email.nil?
        else
          #Two Halves /w only the first half found
        end
      end
    ActiveRecord::Base.remove_connection
  rescue 
    @logger.info "There was an error entering the hash: #{hash} and text: #{text}  in the database. #{$!.to_s}"
  end

  begin
    ActiveRecord::Base.establish_connection
      half2WebrtMatches = Webrt.find(:all, :conditions => ["lmhash_half2 = ? and status != 'finished' and text IS NULL", hash])
      half2WebrtMatches.each do |half2WebrtMatch|
        half2WebrtMatch.update_attributes(:text_half2 => text, :cracked_half2 => true)
        if (half2WebrtMatch.lmhash).length == 32 && half2WebrtMatch.cracked_half1 == true
	  hours, minutes, seconds = DateTime.day_fraction_to_time(DateTime.now - DateTime.parse(half2WebrtMatch.created_on.to_s))
	  elapsedTime = sprintf("%02d:%02d:%02d", hours, minutes, seconds)
	  if text == "not found"
	    half2WebrtMatch.update_attributes(:text => "not found", :cracked_half1 => true, :cracked_half2 => true, :elapsed_time => elapsedTime, :status => "finished")
	  elsif text == ""
	    half2WebrtMatch.update_attributes(:text => half2WebrtMatch.text_half1, :cracked_half1 => true, :cracked_half2 => true, :elapsed_time => elapsedTime, :status => "finished")
	  else
	    half2WebrtMatch.update_attributes(:text => half2WebrtMatch.text_half1 + half2WebrtMatch.text_half2, :cracked_half1 => true, :cracked_half2 => true, :elapsed_time => elapsedTime, :status => "finished")
	  end
	  Notifier::deliver_send_out(half2WebrtMatch.email, half2WebrtMatch.lmhash, half2WebrtMatch.text) if !half2WebrtMatch.email.nil?
        elsif (half2WebrtMatch.lmhash).length == 32 && half2WebrtMatch.cracked_half1 == false
          #go about your business
	else
        end
      end
    ActiveRecord::Base.remove_connection
  rescue
    @logger.info "There was an error entering the hash: #{hash} and text: #{text}  in the database. #{$!.to_s}"
  end
  end
  
end

# This function spawns and maintains 3 crackers as needed
def spawnCrackers()

  @mutex = Mutex.new
  @cv = ConditionVariable.new
  hashArray = Array.new
  @subProcess3, @subProcess2, @subProcess1 = false
  @childPid3, @childPid2, @childPid1 = 0
  
  while true
    oreadReady, = select([$stdin], nil, nil, nil)
    if !oreadReady.nil? 
    begin
    $stdin.gets 
    sockin = $_ unless $_.nil?
      
      @logger.info "DEBUG: Crackers available:  one: #{!@subProcess1}, two: #{!@subProcess2}, three: #{!@subProcess3}\n" if DEBUG 
     
      if sockin.slice(0..8) == "CHKQUEUE:"
      elsif sockin.slice(0..9) == "INPUTHASH:"
        wordArray = sockin.split(' ')
	1.upto(wordArray.length() - 1) do |index|
	    if wordArray[index].index(':') == 16
	      hashArray.push(wordArray[index].slice(0..15))
	    elsif wordArray[index].index(':') == 32
	      hashArray.push(wordArray[index].slice(0..15))
	      hashArray.push(wordArray[index].slice(16..31)) if wordArray[index].slice(0..15) != wordArray[index].slice(16..31)
	    end
	end
      end
        if !@subProcess1 && !hashArray.empty?
	    @mutex.synchronize do
	      @subProcess1 = true
	    end
	    hashString = hashArray.slice!(0..19).join(" ").to_s unless hashArray.empty?
	    @logger.info "DEBUG: Entering cracker 1 with hashString: #{hashString}\n" if DEBUG
	    Thread.new {
	      hashString.split.each do |hash|
		@mutex.synchronize do
	          begin
	            ActiveRecord::Base.establish_connection
		      waiters = Webrt.find(:all, :conditions => ["lmhash_half1 = ? OR lmhash_half2 = ?", hash, hash])
		      if !waiters.nil? && !waiters.empty?
			waiters.each do |waiter|
			  if waiter.status == "waiting" && waiter.cracked_half1 == false && waiter.cracked_half2 == false
		            waiter.update_attribute(:status, "cracking")
			  end
		        end
		      end
	            ActiveRecord::Base.remove_connection
	          rescue
	            @logger.info("There was an error setting the status of a hash.\n#{$!.to_s}")
	          end
		end
	      end
	    }
	    Thread.new {
	    subPipe1 = IO.popen("-", "r+")
	    if subPipe1
	      @childPid1 = subPipe1.pid
	      readWait = []
	      readWait.unshift(subPipe1)
	      while @subProcess1
	        readReady, writeReady, except = select(readWait, nil, nil, nil)
	        next unless readReady
		readReady.each do |io|
	          while io.gets do 
		    rcrackOutput = $_
		      if rcrackOutput.slice(0..5) == "RESET:"
		        @mutex.synchronize do
			  @subProcess1 = false
			end
			break
		      elsif rcrackOutput.slice(0..12) == "plaintext of "
		        wordArray = rcrackOutput.split(' ')
		        if wordArray.length() == 5
		          if wordArray[2].length() == 16 && wordArray[4].length() <= 16
		            hash = wordArray[2]
		            text = wordArray[4]
		            Thread.new { insertIntoDB(hash, text) }
		          end
			end
		      elsif rcrackOutput.include? "hex:"
			
			rcrackOutputArray = rcrackOutput.split
		
			break unless (rcrackOutputArray.size == 3 || rcrackOutputArray[1] == "hex:") || rcrackOutputArray.first.length != 16
			
			hash = rcrackOutputArray.first
			
			hash.scan(/(.)/) do |c|
			  break if !@validArray.include?(c.to_s)
			end
			
			if rcrackOutputArray[1] == "<notfound>"
			  Thread.new { insertIntoDB(hash, "not found") }
			elsif rcrackOutputArray[1] == "hex:"
			  Thread.new { insertIntoDB(hash, "") }
			else
			  Thread.new { insertIntoDB(hash, rcrackOutputarray[1]) } 
			end
		      else
		      end
		  end
	        end
	      end
	    else
	     out = IO.popen("rcrack/rcrack rcrack/*.rt -a " + hashString)
	     while out.gets do
	       puts $_
	     end
	       sleep 1
	       puts "RESET:"
	       out.close
	       Process.exit(0) 
	    end
	    }
	elsif !@subProcess2 && !hashArray.empty?
	    @mutex.synchronize do
	      @subProcess2 = true
	    end
	    hashString = hashArray.slice!(0..19).join(" ").to_s unless hashArray.empty?
            @logger.info "DEBUG: Entering cracker 2 with hashString: #{hashString}\n" if DEBUG
	    Thread.new {
	      hashString.split.each do |hash|
	        @mutex.synchronize do
	 	  begin
	          ActiveRecord::Base.establish_connection
                    waiters = Webrt.find(:all, :conditions => ["lmhash_half1 = ? OR lmhash_half2 = ?", hash, hash])
		    if !waiters.nil? && !waiters.empty?
		      waiters.each do |waiter|
                        if waiter.status == "waiting" && waiter.cracked_half1 == false && waiter.cracked_half2 == false
		          waiter.update_attribute(:status, "cracking")
		        end
                      end		
		    end
	          ActiveRecord::Base.remove_connection
	          rescue
                    @logger.info("There was an error setting the status of a hash.\n#{$!.to_s}")
	          end
                end
	      end
	    }
	    Thread.new {
	    subPipe2 = IO.popen("-", "r+")
	    if subPipe2
              @childPid2 = subPipe2.pid
              readWait = []
              readWait.unshift(subPipe2)
              while @subProcess2
                readReady, writeReady, except = select(readWait, nil, nil, nil)
                next unless readReady
                readReady.each do |io|
		  while io.gets do
		    rcrackOutput = $_
		    if rcrackOutput.slice(0..5) == "RESET:"
		      @mutex.synchronize do
		        @subProcess2 = false
                      end
		      break
		    elsif rcrackOutput.slice(0..12) == "plaintext of "
		      wordArray = rcrackOutput.split(' ')
		      if wordArray.length() == 5
		        if wordArray[2].length() == 16 && wordArray[4].length() <= 16
		          hash = wordArray[2]
		          text = wordArray[4]
	                  Thread.new { insertIntoDB(hash, text) }
	                end
		      end
                    elsif rcrackOutput.include? "hex:"

                      rcrackOutputArray = rcrackOutput.split

		      break unless (rcrackOutputArray.size == 3 || rcrackOutputArray[1] == "hex:") || rcrackOutputArray.first.length != 16

                      hash = rcrackOutputArray.first

                      hash.scan(/(.)/) do |c|
                        break if !@validArray.include?(c.to_s)
                      end
		      
		      if rcrackOutputArray[1] == "<notfound>"
		        Thread.new { insertIntoDB(hash, "not found") }
		      elsif rcrackOutputArray[1] == "hex:"
		        Thread.new { insertIntoDB(hash, "") }
		      else
		        Thread.new { insertIntoDB(hash, rcrackOutputarray[1]) }												         end
		    else			    
	            end
		  end
		end
              end
            else
	     $stdout.print "sending " + hashString + "to rcrack\n"
	     out = IO.popen("rcrack/rcrack rcrack/*.rt -a " + hashString)
             while out.gets do
	       puts $_
             end
	       sleep 1
               puts "RESET:"
	       out.close
               Process.exit(0)
            end
            }
        elsif !@subProcess3 && !hashArray.empty?
            @mutex.synchronize do
	      @subProcess3 = true
	    end
	    hashString = hashArray.slice!(0..19).join(" ").to_s unless hashArray.empty?
	    @logger.info "DEBUG: Entering cracker 3 with hashString: #{hashString}\n" if DEBUG
	    Thread.new {
	      hashString.split.each do |hash|
	        @mutex.synchronize do
		  begin
	            ActiveRecord::Base.establish_connection
	              waiters = Webrt.find(:all, :conditions => ["lmhash_half1 = ? OR lmhash_half2 = ?", hash, hash])
		      if !waiters.nil? && !waiters.empty?
		        waiters.each do |waiter| 
	                  if waiter.status == "waiting" && waiter.cracked_half1 == false && waiter.cracked_half2 == false
			    waiter.update_attribute(:status, "cracking")
			  end
		        end
		      end
	          ActiveRecord::Base.remove_connection
	          rescue
		    @logger.info("There was an error setting the status of a hash.\n#{$!.to_s}")
	          end
		end
	      end
	    }
	    Thread.new {
            subPipe3 = IO.popen("-", "r+")
            if subPipe3
              @childPid3 = subPipe3.pid
              readWait = []
              readWait.unshift(subPipe3)
              while @subProcess3 
                readReady, writeReady, except = select(readWait, nil, nil, nil)
                next unless readReady
                readReady.each do |io|
		  while io.gets do
		    rcrackOutput = $_
                      if rcrackOutput.slice(0..5) == "RESET:"
	                @mutex.synchronize do 
			  @subProcess3 = false
			end
	                break
		      elsif rcrackOutput.slice(0..12) == "plaintext of "
                        wordArray = rcrackOutput.split(' ')
                        if wordArray.length() == 5
                          if wordArray[2].length() == 16 && wordArray[4].length() <= 16
                            hash = wordArray[2]
                            text = wordArray[4]
                            Thread.new { insertIntoDB(hash, text) }
                          end
                        end
                      elsif rcrackOutput.include? "hex:"

                        rcrackOutputArray = rcrackOutput.split

			break unless (rcrackOutputArray.size == 3 || rcrackOutputArray[1] == "hex:") || rcrackOutputArray.first.length != 16

                        hash = rcrackOutputArray.first

                        hash.scan(/(.)/) do |c|
                          break if !@validArray.include?(c.to_s)
                        end

		      	if rcrackOutputArray[1] == "<notfound>"
			  Thread.new { insertIntoDB(hash, "not found") }
			elsif rcrackOutputArray[1] == "hex:"
			  Thread.new { insertIntoDB(hash, "") }
			else
			  Thread.new { insertIntoDB(hash, rcrackOutputArray[1]) }
			end
		      else		      
                      end
		  end
                end
              end
            else
             out = IO.popen("rcrack/rcrack rcrack/*.rt -a " + hashString)
             while out.gets do
               puts $_
             end
	       sleep 1
	       puts "RESET:"
               out.close
               Process.exit(0)
            end
            }          
        end
      end
    end
  end
end

@sock = UNIXServer.open(RCRACK_DRIVER_SOCKET)

@pipe = IO.popen("-", "w+")

if @pipe

  readWait = []
  readWait.unshift(@sock)
  begin
    while true
      readReady, writeReady, except = select(readWait, nil, nil, nil)
        next unless readReady
	readReady.each do |sock|
	  Thread.start(sock.accept) do |s|
	    while s.gets
	      @pipe.puts $_
	      s.close
	    end
	end
      end
    end
  rescue Exception => ioe
    @logger.info("Can't read from socket, closing: #{ioe}")
  ensure 
    @sock.close unless @sock.nil?
    File.delete(RCRACK_DRIVER_SOCKET)				    #make sure to remove socket from filesystem
  end
else
  $stderr.print "Starting RTcrack Scheduler\n"
  @logger.info "STARTING UP!"
  
  trap("CLD") {
  pid = Process.wait
  
  if pid == @childPid1
    Thread.new {
      @mutex.synchronize do 
        @childPid = 0
        @subProcess1 = false
        s = UNIXSocket.open(RCRACK_DRIVER_SOCKET)
        s.send("CHKQUEUE:", 0)
        s.close
	@logger.info "DEBUG: Child one has exited" if DEBUG
      end
    }
  elsif pid == @childPid2
    Thread.new {
      @mutex.synchronize do
        @childPid2 = 0
        @subProcess2 = false
        s = UNIXSocket.open(RCRACK_DRIVER_SOCKET)
        s.send("CHKQUEUE:", 0)
        s.close
	@logger.info "DEBUG: Child two has exited" if DEBUG
      end
    }
  elsif pid == @childPid3
    Thread.new {
      @mutex.synchronize do
        @childPid3 = 0
        @subProcess3 = false
        s = UNIXSocket.open(RCRACK_DRIVER_SOCKET)
        s.send("CHKQUEUE:", 0)
        s.close
	@logger.info "DEBUG: Child three has exited" if DEBUG
      end
    }
  else
  end
  }

  spawnCrackers()
end
