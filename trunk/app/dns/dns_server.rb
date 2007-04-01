#!/usr/bin/ruby

require 'socket'
require 'resolv'

require File.dirname(__FILE__) + './../config/boot'
ENV["RAILS_ENV"] = 'development'
require RAILS_ROOT + '/config/environment'

class DNSServer 
    attr_reader (:child_count)
    
    def initialize(prefork, max_clients_per_child, client_handler, socket)
        @prefork = prefork
        @max_clients_per_child = max_clients_per_child
        @child_count = 0
        @server = socket
	
        @reaper = proc {
            trap('CHLD', @reaper)
            pid = Process.wait
            @child_count -= 1
        }
        
        @huntsman = proc {
            trap('CHLD', 'IGNORE')
            trap('INT', 'IGNORE')
            Process.kill('INT', 0)
            exit
        }
        
        @client_handler=client_handler
    end
    
    def child_handler
        trap('INT', 'EXIT')
        @client_handler.setUp
        # wish: sigprocmask UNblock SIGINT
        @max_clients_per_child.times {
            client_request, addr = @server.recvfrom(65535) 
	    break if client_request.length == 0 
	    @client_handler.handle_request(client_request, addr, @server)
        }
        @client_handler.tearDown
    end
    
    def make_new_child
        # wish: sigprocmask block SIGINT
        @child_count += 1
        pid = fork do
            child_handler
        end
        # wish: sigprocmask UNblock SIGINT
    end
    
    def run
	trap('CHLD', @reaper)
        trap('INT', @huntsman)
        loop {
            (@prefork - @child_count).times { |i|
                make_new_child
            }
            sleep 0.1
        }
    end
end

class ClientHandler
    
    def initialize 
      @foundPlainText = "" 
    end
    
    def setUp
    end
    
    def tearDown
    end
   
    def handle_request(client_request, addr, server)
      
      dns_request = Resolv::DNS::Message.decode(client_request)
      dns_request.each_question { |domainname, typeclass|
        dns_request.qr = 1
        dns_request.ra = 1			
	
	if parse_request(domainname.to_s) == true
	  if @foundPlainText != "" && !@foundPlainText.nil?
	    name = Resolv::DNS::Name.create("<" + @foundPlainText + ">." + DOMAIN_NAME)
	    answer = Resolv::DNS::Resource::IN::CNAME.new(name)
	    dns_request.add_answer(domainname, 10, answer)
            answer = Resolv::DNS::Resource::IN::A.new(DNS_IP_REPLY)
            dns_request.add_answer(domainname, 10, answer)
	    @foundPlainText = ""
	  else
	    answer = Resolv::DNS::Resource::IN::A.new(DNS_IP_REPLY)
	    dns_request.add_answer(domainname, 10, answer)
	  end
	else 
	  #dns_request.rcode = 3
	  break
	end
	
	dns_request.add_answer(domainname, 10, answer)
      }
    
      server.send(dns_request.encode, 0, addr[3], addr[1])
      
    end
   
    private
    def parse_request(domainname)
	
	hash = ""
	
	return false if domainname.nil?
	
	if domainname.length != (DOMAIN_NAME.length + 1 + 16) && domainname.length != (DOMAIN_NAME.length + 1 + 32)
	  return false
	end
	
	if domainname.slice((0 - DOMAIN_NAME.length)..-1)!= DOMAIN_NAME
	  return false
	end
	
        domainArray = domainname.split('.')
	
	return false if domainArray.nil?
	
	return false if domainArray[1] != "rainbowtables"
	
	if domainArray[0].length != 16 && domainArray[0].length != 32
	  return false
	end

	hash = domainArray[0]
	
	hash.downcase!
	
	return insert_into_db(hash)
	
    end

    private
    def insert_into_db(hash)
      
      begin
        
	@webrt = Webrt.new
       
        previousHashRecord = Webrt.find(:first, :conditions => ["lmhash = ?", hash])
       
	
	if !previousHashRecord.nil?
	  if previousHashRecord.status == "finished"
	    @foundPlainText = previousHashRecord.text
	  end
	  
	  return true
	end
       
	if hash.length == 16
	  @webrt.lmhash = hash
	  @webrt.lmhash_half1 = hash
	  @webrt.status = "waiting"
	  @webrt.save
	elsif hash.length == 32
	  @webrt.lmhash = hash
	  @webrt.lmhash_half1 = hash.slice(0..15)
	  @webrt.lmhash_half2 = hash.slice(16..31)
	  @webrt.status = "waiting"
	  @webrt.save
	else
	  return false
	end

	print "STRING: #{hash}\n"
	return send_to_cracker(hash + ":" + @webrt.id.to_s)

      rescue
        print "Database Problem " + $!.to_s + "\n" 
        return false
      end
      
    end
    
    private
    def send_to_cracker(hash)
      
      begin
        
	if File.stat(RCRACK_DRIVER_SOCKET).nil?
	  return false
	end
	
	client = UNIXSocket.open(RCRACK_DRIVER_SOCKET)
	client.send("INPUTHASH: " + hash, 0)
	client.close
      
      rescue
        #Webrt.delete(webrt.id) unless !webrt.text.nil?
        return false
      end

      return true
												    
    end
end

  def create_socket(host_name, port)
    
    if Process.uid != 0
      print "You must start the daemon as root\n"
      exit
    end		
    
    socket = UDPSocket.open
    socket.bind(host_name, port)
    socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1)
   
    Process.egid = Process.egid = Etc.getpwnam(DNS_GROUP).gid
    Process.euid = Process.uid = Etc.getpwnam(DNS_GROUP).uid 
   
    return socket
  end

  dnsserver = DNSServer.new(1, 100, ClientHandler.new, create_socket("", 53))
  dnsserver.run
