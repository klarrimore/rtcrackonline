require 'ajax_scaffold'
#require 'content_column_patch'

class Webrt < ActiveRecord::Base

  #def self.content_columns
  #  get_desired_columns %w(version name)#, @@desired_columns_cache ||= nil
  #end

  #@captchaValid = false			#Before the captcha is validated
  
  #def setValidCaptcha(val)
  #  @captchaValid = val
  #  logger.info "Hit setValidCaptcha\n"
  #end

  #def printCaptcha
  #  logger.info "Print Captcha: #{@captchaValid.to_s}\n"
  #end

  #def checkCaptcha
  #  if @captchaValid			#If the captcha is already known to be falid... don't check 
  #    return false;
  #  else
  #    return true;
  #  end
  #end
  
  #validates_captcha :on => :create, :if => :checkCaptcha, :message => "The code you entered was invalid"
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+.)+[a-z]{2,})$/, :allow_nil => true, :on => :create
  validates_presence_of :lmhash

  def validate
    validArray = ("a".."f").to_a + ("0".."9").to_a
   
    if lmhash.length != 16 && lmhash.length != 32
      errors.add_to_base("lmhash must be 16 or 32 characters") 
      return
    end
    
    lmhash.scan(/(.)/) { |c|
      if !validArray.include?(c.to_s)
        errors.add_to_base("Not a valid lmhash")
        return 
      end
    
    if id.nil?
      lastHashFromIP = Webrt.find(:first, :conditions => ["ip_address = ?", ip_address], :order => "id DESC")

      if !lastHashFromIP.nil?
        if (Time.now - lastHashFromIP.created_on) < 5
          errors.add_to_base("Wait a few moments before adding another hash")
	  return
        end
      end
    end

    }

    begin
      if File.stat(RCRACK_DRIVER_SOCKET).nil?
        errors.add_to_base("Unable to communicate with the cracker.")
        logger.info("Error: " + $!.to_s + "\nThe cracker has probably died and needs to be restarted.")
        return
      end
    rescue
      errors.add_to_base("Unable to communicate with the cracker.")
      logger.info("Error: " + $!.to_s + "\nThe cracker has probably died and needs to be restarted.")
      return
    end
				  
  end
  
  @scaffold_columns = [
    AjaxScaffold::ScaffoldColumn.new(self, { :name => "lmhash" }),
    
    AjaxScaffold::ScaffoldColumn.new(self, { :name => "text" }),
    AjaxScaffold::ScaffoldColumn.new(self, { :name => "status"}),
    AjaxScaffold::ScaffoldColumn.new(self, { :name => "elapsed_time" }),
    AjaxScaffold::ScaffoldColumn.new(self, { :name => "created_on"})
    ]

end
