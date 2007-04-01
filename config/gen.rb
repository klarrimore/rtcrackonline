#!/usr/bin/ruby

0.upto(5000) do
chars = ("a".."z").to_a + ("1".."9").to_a
gstring = ""
0.upto( 4 + rand(10-4)) { |i| gstring << chars[rand(chars.size-1)] }
print "      - " + gstring + "\n"
end	    
