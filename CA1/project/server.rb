#!/usr/bin/env ruby -w
require "sqlite3"
require "webrick"
DATABASE = "skydrive.sqlite3"

# -- MODELS --

def model_index()
	db  = SQLite3::Database.new( DATABASE )
	qry = "select id, name from documents;"
	hash = db.execute( qry )
	db.close
	return hash
end
	
def model_show(id, shift)
	db  = SQLite3::Database.new( DATABASE )
	qry = "select message from documents "                         +
	      "where id = \"#{id}\";"
	val = db.get_first_value( qry )
    
    cipher = Caesar.new shift
    message = cipher.decrypt(val)
	db.close
	return message
end

def model_new(insert=false, message, name, shift)
    if insert
      puts "INSERTING INTO DB"
      cipher = Caesar.new shift.to_i
      message_enc = cipher.encrypt(message)
    
      db  = SQLite3::Database.new( DATABASE )
      qry = "SELECT id FROM documents ORDER BY id DESC LIMIT 1;"
      id = db.execute( qry ).join.to_i + 1
      qry = "INSERT INTO documents VALUES"                           +
          "(#{id}, \"#{name}\", \"#{message_enc}\");"
      db.execute( qry )
      db.close
      return true
    end
    puts "NO MSG SUPPLIED"
    return false
end

# -- VIEWS --

def view_show(val)
    "<html>"                                                       +
    "  <body>"                                                     +
    "    <p>" + val.to_s + "</p>"                                  +
    "  </body>"                                                    +
    "</html>"
end

def view_index(vals)
	output = "<html>"                                              +
	"  <body>"                                                     +
	"    <form action=\"http://localhost:3000/show\""              +
    "    method=\"GET\">"                                          +
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

def view_new(success=false)
    output = "<html>"                                              +
    "  <body>"
    
    if success
        output << "<p>Message encrypted and added</p>"
    end
        
    output << "    <form action=\"http://localhost:3000/new\""     +
    "    method=\"GET\">"                                          +
    "      <input name=\"shift\" value=\"Enter Shift\"/>"          +
    "      <input name=\"name\" value=\"Enter Name\"/>"            +
    "      <input name=\"message\" value=\"Enter Message\"/>"      +
    "      <input type=\"Submit\"/>"                               +
    "    </form>"                                                  +
    "  </body>"                                                    +
    "</html>"
    
    return output
end

# -- CONTROLLER --

class Controller < WEBrick::HTTPServlet::AbstractServlet
    def do_GET ( req, rsp )
      case req.path
        when "/index"
          rsp.status = 200
          rsp.content_type = "text/html"
          rsp.body = view_index( model_index() )
        when "/new"
        
          message = req.query[ "message" ] || ""
          name = req.query[ "name" ] || ""
          shift = req.query[ "shift" ] || ""
          
          if message.length == 0 || name.length == 0 || shift.length == 0
            insert = false
            else
            insert = true
          end
          
          rsp.status = 200
          rsp.content_type = "text/html"
          rsp.body = view_new( model_new(insert, message, name, shift) )
          
        when "/show"
          id = req.query[ "id" ] || ""
          shift = req.query[ "shift" ] || ""
          puts id
          rsp.status = 200
          rsp.content_type= "text/html"
          rsp.body = view_show( model_show(id, shift.to_i) )
      end
    end
end

# -- SUPPORT CLASSES --
    
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

# -- RUNTIME --

server = WEBrick::HTTPServer.new( :Port => 3000 )
   server.mount( "/", Controller )
   server.start
