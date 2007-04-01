#!/usr/bin/ruby -w

require 'socket'

require File.dirname(__FILE__) + './../config/boot'
ENV["RAILS_ENV"] = 'development'
require RAILS_ROOT + '/config/environment'


@hashArray = ["a1c93089e0df8e12", "ff6dfeb143e87df8", "ed0b775175b4fd59b75e0c8d76954a50", "2874fc699c3b86ac", "00fb262c57b0c823", "86d163a068063edb", "b348657e8979711b92b17c2df844a395", "caa8f69dc114a8b3174822d4875bbff2", "54abcd47732902d4", "85bae10811361211", "1c1c459381c5a08614a040a76d836be9", "54f4def54ff0c2ab", "4a014c1450b4de8732cc1380fa7e9c1f", "19dc758382bfe0c7", "315e5c241d0607198f7efbcada42ff7d", "73e7657eb0127d6faad3b435b51404ee", "9dbde5f1b95b919438d158c470a473aa", "e184320349f18224aad3b435b51404ee", "00845424787a28e6ab47a1b697fbf322", "d3f60134f5d97c1caad3b435b51404ee", "1c310eede09d84ea81dd4a1960147c1c", "04a26f63fac56d6b349ca661f80d893e", "02fb5e12c22749e074af99608da0cd6a"]


  0.upto(@hashArray.size - 1) do |index|
    begin
      ActiveRecord::Base.establish_connection
      hash = @hashArray[index]
      webrt = Webrt.new
      webrt.lmhash = hash
      webrt.lmhash_half1 = hash.slice(0..15)
      webrt.lmhash_half2 = hash.slice(16..31)
      webrt.status = "waiting"
      webrt.save
    
      if File.stat(RCRACK_DRIVER_SOCKET).nil?
        return
      end
   
      client = UNIXSocket.open(RCRACK_DRIVER_SOCKET)
      
      Thread.new {
        $stderr.print "SENDING1: #{hash}\n"
	client.send("INPUTHASH: " + hash + ":" + webrt.id.to_s, 0)
      }
      
      Thread.new {
        $stderr.print "SENDING2: #{hash}\n"
        client.send("INPUTHASH: " + hash + ":" + webrt.id.to_s, 0)
      }		  
      
      client.close
      ActiveRecord::Base.remove_connection
    rescue
      print "WTF!!!!!!!! " + $!.to_s + "\n"
      exit
    end
  end
