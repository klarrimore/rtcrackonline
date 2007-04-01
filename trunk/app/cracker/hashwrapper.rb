class HashWrapper

  def initialize(hash, id)
    @plainText1 = nil
    @plainText2 = nil
    @length = hash.length
    @hash = hash
    @id = id
  end

  def getLength
    return @length
  end

  def getHash1
    return @hash.slice(0..15)
  end

  def getHash2
    if @length == 32 
      return @hash.slice(16..31) 
    else
      return nil
    end
  end
 
  def getFullHash
    return @hash
  end
 
  def getID
    return @id
  end
  
  def setPlainText1(plainText)
    @plainText1 = plainText
  end
  
  def setPlainText2(plainText)
    @plainText2 = plainText
  end	  
  
  def getPlainText1
    return @plainText1
  end

  def getPlainText2
    return @plainText2
  end

  def getFullText
    
    if !@plainText1.nil? && !@plainText2.nil?
      return @plainText1 + @plainText2
    else
      return @plainText1
    end   

  end

end

