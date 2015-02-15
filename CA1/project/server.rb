#!/usr/bin/env ruby -w
require "sqlite3"
require "webrick"
DATABASE = "skydrive.sqlite3"

def model_list()
	db  = SQLite3::Database.new( DATABASE )
	qry = "select id, name from documents;"
	hash = db.execute( qry )
	db.close
	return hash
end
	
def model_show(id)
	db  = SQLite3::Database.new( DATABASE )
	qry = "select message from documents " + 
	      "where id = \"#{id}\""
	val = db.get_first_value( qry )
	db.close
	return val
end

def view_show(message, shift)
    puts message
    puts shift
    cipher = Caesar.new shift
    message_plain = cipher.decrypt(message)
    "<html>"                                            +
    "  <body>"                                          +
    "    <p>" + message_plain.to_s + "</p>"             +
    "  </body>"                                         +
    "</html>"
end

def view_list(vals)
	output = "<html>"                                              +
	"  <body>"                                                     +
	"    <form action=\"http://localhost:3000/show\""              +
    "    method=\"GET\">"                                         +
    "      <select name=\"id\">"
    
    
	vals.each do |key, value|
	  output <<	"<option value=\"#{key}\">#{value}</option><br \>"
	end
	
	output << "</select>"                                          +
	"      <input name=\"shift\" value=\"Enter shift\"/>"          +
	"      <input type=\"Submit\"/>"                               +
	"    </form>"                                                  +
	"  </body>"                                                    +
	"</html>"
end


class Controller < WEBrick::HTTPServlet::AbstractServlet
    def do_GET ( req, rsp )
      case req.path
        when "/list"
          rsp.status = 200
          rsp.content_type = "text/html"
          rsp.body = view_list( model_list() )
        when "/show"
          id = req.query[ "id" ] || ""
          shift = req.query[ "shift" ] || ""
          puts id
          rsp.status = 200
          rsp.content_type= "text/html"
          rsp.body = view_show( model_show(id), shift.to_i)
      end
    end
end
    
class Caesar
  def initialize(shift, alphabet = (('a'..'z').to_a + ('A'..'Z')
                                    .to_a + ('0'..'9').to_a + [' ']).join)
    chars = alphabet.chars.to_a
    @encrypter = Hash[chars.zip(chars.rotate(shift))]
    @decrypter = Hash[chars.zip(chars.rotate(-shift))]
  end

  def encrypt(string)
    @encrypter.values_at(*string.chars).join
  end

  def decrypt(string)
    @decrypter.values_at(*string.chars).join
  end
end


server = WEBrick::HTTPServer.new( :Port => 3000 )
   server.mount( "/", Controller )
   server.start
