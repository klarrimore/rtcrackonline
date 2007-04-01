class WebrtController < ApplicationController
  include AjaxScaffold::Controller

  require 'socket'

  after_filter :clear_flashes
  
  #def index
  #  redirect_to :action => 'list'
  #end


  def return_to_main
    # If you have multiple scaffolds on the same view then you will want to change this to
    # to whatever controller/action shows all the views 
    # (ex: redirect_to :controller => 'AdminConsole', :action => 'index')
    redirect_to :action => 'list'
  end

  def list
  end
  
  # All posts to change scaffold level variables like sort values or page changes go through this action
  def component_update  
    if request.xhr?
      # If this is an AJAX request then we just want to delegate to the component to rerender itself
      component
    else
      # If this is from a client without javascript we want to update the session parameters and then delegate
      # back to whatever page is displaying the scaffold, which will then rerender all scaffolds with these update parameters
      update_params :default_scaffold_id => "webrt", :default_sort => nil, :default_sort_direction => "desc"
      return_to_main
    end
  end

  def component
    update_params :default_scaffold_id => "webrt", :default_sort => nil, :default_sort_direction => "desc"
     
    @sort_sql = Webrt.scaffold_columns_hash[current_sort(params)].sort_sql rescue nil
    @sort_by = @sort_sql.nil? ? "#{Webrt.table_name}.#{Webrt.primary_key} desc" : @sort_sql  + " " + current_sort_direction(params)
    @paginator, @webrts = paginate(:webrts, :order => @sort_by, :per_page => default_per_page)
    
    render :action => "component", :layout => false
  end

  def new
    @webrt = Webrt.new
    @successful = true

    return render :action => 'new.rjs' if request.xhr?

    # Javascript disabled fallback
    if @successful
      @options = { :action => "create" }
      render :partial => "new_edit", :layout => true
    else 
      return_to_main
    end
  end
  
  def create
    #unique = false
    #gstring = ""
    @webrtHash = Hash.new()
    @webrtArray = Array.new

    # Thought I would need this for multiple hashes 
    #while unique == false  #possible infinite loop
    #  gstring = determineGString()
    #  temp = Webrt.find_by_gstring('gstring')
    #  unique = true if temp.nil?
    #end
     
    #***Captcha***# 
    #captcha_id = params[:webrt][:captcha_id]
    #captcha_validation = params[:webrt][:captcha_validation]

    email = params[:webrt][:email] unless params[:webrt][:email].empty?
    
    begin
      if !params[:webrt][:"0"][:lmhash].empty?
	@webrt = Webrt.new

	@webrt.lmhash = (params[:webrt][:"0"][:lmhash]).downcase
        @webrt.lmhash_half1 = (params[:webrt][:"0"][:lmhash]).slice(0..15)
	@webrt.lmhash_half2 = (params[:webrt][:"0"][:lmhash]).slice(16..31) if (params[:webrt][:"0"][:lmhash]).length == 32
	#***Captcha***#
	#@webrt.captcha_id = captcha_id
	#@webrt.captcha_validation = captcha_validation
	@webrt.email = email unless email.nil?
	@webrt.ip_address = request.env['REMOTE_HOST'] unless request.env['REMOTE_HOST'].nil?
	@webrt.status = "waiting"
	
	if !@webrt.lmhash_half1.nil?
	  plainText = checkPopularMatches(@webrt.lmhash_half1)
	  if !plainText.nil?
	    @webrt.text_half1 = plainText.slice(1, (plainText.length - 2))
	    @webrt.cracked_half1 = true
	    if @webrt.lmhash_half2.nil?
	      @webrt.text = @webrt.text_half1
	      @webrt.status = "cracked"
	    end
	  end
	end

	if !@webrt.lmhash_half2.nil?
	  plainText = checkPopularMatches(@webrt.lmhash_half2)
	  if !plainText.nil?
	    @webrt.text_half2 = plainText.slice(1, (plainText.length - 2))
	    @webrt.cracked_half2 = true
	  end
	  if @webrt.cracked_half1 == true && @webrt.cracked_half2 == true && !@webrt.cracked_half1.nil? && !@webrt.cracked_half2.nil?
	    @webrt.text = @webrt.text_half1 << @webrt.text_half2 
	    @webrt.status = "cracked"
	  end
	end
	
	@successful = @webrt.save
	#logger.info("DEBUG: successful=#{@successful}")
	if @successful 
	  @webrtArray << @webrt
	  if @webrt.status == "cracked" && !(@webrt.cracked_half1 == true && @webrt.cracked_half2 == true)
	    if @webrt.cracked_half1 == false
	      @webrtHash[@webrt.id.to_s] = @webrt.lmhash_half1
	    end
	    if @webrt.cracked_half2 == false
	      @webrtHash[@webrt.id.to_s] = @webrt.lmhash_half2
	    end
	  else
 	    @webrtHash[@webrt.id.to_s] = @webrt.lmhash
	  end
	end
	#logger.info("DEBUG: id: #{@webrtArray.first.id}")
      end
    rescue
      flash[:error], @successful  = $!.to_s, false
    end
    
    #begin
    #  if !params[:webrt][:"1"][:lmhash].empty?
    #    @webrt = Webrt.new
    #	
    #	@webrt.setValidCaptcha(true)
    #	@webrt.lmhash = params[:webrt][:"1"][:lmhash]
    #    @webrt.email = email unless email.nil?
    #	@webrt.status = "waiting"
    #
    # 	if checkPopularMatches(params[:webrt][:"1"][:lmhash]) != nil
    #	  @webrt.text = $_
    #	  @webrt.status = "cracked"
    #	else
    #	  @hashArray.push(params[:webrt][:"1"][:lmhash])
    #	end
    #	  @successful = @webrt.save
    #	  @webrtArray << @webrt if @successful
    #  end
    #rescue
    #  flash[:error], @successful  = $!.to_s, false
    #end
		  
    #begin
    #  if !params[:webrt][:"2"][:lmhash].empty?
    #    @webrt = Webrt.new
    #
    #	@webrt.setValidCaptcha(true)
    #    @webrt.lmhash = params[:webrt][:"2"][:lmhash]
    #    @webrt.email = email unless email.nil?
    #	@webrt.status = "waiting"
    #
    #    if checkPopularMatches(params[:webrt][:"2"][:lmhash]) != nil
    #      @webrt.text = $_
    #      @webrt.status = "cracked"
    #    else
    #      @hashArray.push(params[:webrt][:"2"][:lmhash])
    #    end
    #      @successful = @webrt.save
    #	  @webrtArray << @webrt if @successful
    #  end
    #rescue
    #  flash[:error], @successful  = $!.to_s, false
    #end
		  
    #begin	
    #  if !params[:webrt][:"3"][:lmhash].empty?
    #    @webrt = Webrt.new
    #
    #	@webrt.setValidCaptcha(true)
    #    @webrt.lmhash = params[:webrt][:"3"][:lmhash]
    #    @webrt.email = email unless email.nil?
    #	@webrt.status = "waiting"
    #
    #    if checkPopularMatches(params[:webrt][:"3"][:lmhash]) != nil
    #      @webrt.text = $_
    #      @webrt.status = "cracked"
    #    else
    #      @hashArray.push(params[:webrt][:"3"][:lmhash])
    #    end
    #      @successful = @webrt.save
    #	  @webrtArray << @webrt if @successful
    #  end
    #
    #rescue
    #  flash[:error], @successful  = $!.to_s, false
    #end
   
    sendToRTCrack(@webrtHash) unless (@webrtHash.nil? || !@successful)
    
    return render :action => 'create.rjs' if request.xhr?
    
    if @successful
      return_to_main
    else
      @options = { :scaffold_id => params[:scaffold_id], :action => "create" }
      render :partial => 'new_edit', :layout => true
    end
    
  end

    def search
    @successful = true
    return render :action => 'search.rjs' if request.xhr?

    # Javascript disabled fallback
    if @successful
      @options = { :action => "find" }
      render :partial => "new_search", :layout => true
    else
      return_to_main
    end
  end

  def find
    successfulHash = false
    successfulEmail = false
    @webrtArray = Array.new
    validArray = ("a".."f").to_a + ("0".."9").to_a

    if !(params[:webrt][:lmhash]).empty?
      hash = (params[:webrt][:lmhash]).downcase
      return render :action => 'find.rjs' unless hash.length == 16 || hash.length == 32
      hash.scan(/(.)/) { |c|
        if !validArray.include?(c.to_s)
          flash[:info] = "Not found"
          return render :action => 'find.rjs' if request.xhr?
        end
      }

      begin
        @webrt = Webrt.find(:first, :conditions => ["lmhash = ?", hash])
        successfulHash = !@webrt.nil?
        @webrtArray << @webrt if successfulHash
      rescue
        flash[:error], successfulHash = $!.to_s, false
        logger.info "Error in Search: " + $!.to_s
      end
    end

    if !(params[:webrt][:email]).empty?
      if params[:webrt][:email] =~ /^([^@\s]+)@((?:[-a-z0-9]+.)+[a-z]{2,})$/
        email = params[:webrt][:email]
        email = nil if email.length > 100
      end

      if !email.nil?
        begin
          @webrts = Webrt.find(:all, :conditions => ["email = ?", email])
          successfulEmail = (!@webrts.nil? && !@webrts.empty?)
          if successfulEmail
            for webrt in @webrts
              @webrtArray << webrt
            end
          end
        rescue
          flash[:error], successfulEmail = $!.to_s, false
          logger.info "Error in Search: " + $!.to_s
        end
      end
    end

    flash[:info] = "Not found" if !(successfulEmail || successfulHash)
    @successful = true if (successfulEmail || successfulHash)

    return render :action => 'find.rjs' if request.xhr?

  end
 
 
  # We don't need this for now...
 
  #def edit
  #  begin
  #    @webrt = Webrt.find(params[:id])
  #    @successful = !@webrt.nil?
  #  rescue
  #    flash[:error], @successful  = $!.to_s, false
  #  end
  #  
  #  return render :action => 'edit.rjs' if request.xhr?
  #
  #  if @successful
  #    @options = { :scaffold_id => params[:scaffold_id], :action => "update", :id => params[:id] }
  #    render :partial => 'new_edit', :layout => true
  #  else
  #    return_to_main
  #  end    
  #end
  #
  #def update
  #  begin
  #    @webrt = Webrt.find(params[:id])
  #    @successful = @webrt.update_attributes(params[:webrt])
  #  rescue
  #    flash[:error], @successful  = $!.to_s, false
  #  end
  #  
  #  return render :action => 'update.rjs' if request.xhr?
  #
  #  if @successful
  #    return_to_main
  #  else
  #    @options = { :action => "update" }
  #    render :partial => 'new_edit', :layout => true
  #  end
  #end
  #
  #def destroy
  #  begin
  #    @successful = Webrt.find(params[:id]).destroy
  #  rescue
  #    flash[:error], @successful  = $!.to_s, false
  #  end
  #  
  #  return render :action => 'destroy.rjs' if request.xhr?
  #  
  #  # Javascript disabled fallback
  #  return_to_main
  #end
  
  def cancel
    @successful = true
    
    return render :action => 'cancel.rjs' if request.xhr?
    
    return_to_main
  end

  # Checks the hash against the previously found table
  private
  def checkPopularMatches(hash)
    begin
      plainText = PopularMatch.find(:first, :conditions => ["hash = ?", hash])
      if !plainText.nil?
        return "<" + plainText.text.to_s + ">"
      else
        return nil
      end
    rescue
      flash[:error] = "Some error: " + $!.to_s
    end
  end
  
  private
  def sendToRTCrack(webrtArray)
  
    hashArray = Array.new
    webrtArray.each do |key, value|
      hashArray << value + ":" + key unless (value.nil? || key.nil?)
    end			      
  
    begin
      if File.stat(RCRACK_DRIVER_SOCKET).nil?
        flash[:error] = "Unable to communicate with the cracker."
	logger.info("Error: " + $!.to_s + "\nThe cracker has probably died and needs to be restarted.")
	return
      end      
      client = UNIXSocket.open(RCRACK_DRIVER_SOCKET)
      client.send("INPUTHASH: " + hashArray.join(" ").to_s, 0)
      client.close
    rescue
      flash[:error] = "Unable to communicate with the cracker."    
      logger.info("Error: " + $!.to_s + "\nThe cracker has probably died and needs to be restarted.")
      webrtArray.each do |webrt|
	Webrt.delete(webrt.id) unless !webrt.text.nil?
      end
    end
  end    

  # Thought I would need this for multiple hashes
  # Creates a unique string to identify groups of hashes
  #private
  #def createGString
  #  chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
  #  gstring = ""
  #  0.upto(7) { |i| gstring << chars[rand(chars.size-1)] }
  #  return gstring
  #end  
end
