#!/usr/bin/env ruby -w
require "sqlite3"
require "webrick"
DATABASE = "skydrive.sqlite3"

# -- MODELS --

def model_index()
	db  = SQLite3::Database.new( DATABASE )
	qry = "SELECT id, name FROM documents;"
	hash = db.execute( qry )
	db.close
	return hash
end
	
def model_show(id, shift)
	db  = SQLite3::Database.new( DATABASE )
	qry = "SELECT message FROM documents "                         +
	      "WHERE id = \"#{id}\";"
	val = db.get_first_value( qry )
    
    cipher = Caesar.new shift
    message = cipher.decrypt(val)
	db.close
	return message
end

def model_update(show=false, update=false, id, message, shift)
    db  = SQLite3::Database.new( DATABASE )
    qry = "SELECT id, name FROM documents;"
    hash = db.execute( qry )

    cipher = Caesar.new shift.to_i
    
    if show
      qry = "SELECT message FROM documents "                        +
      "WHERE id = \"#{id}\";"
      val = db.get_first_value( qry )
      message_dec = cipher.decrypt(val)
      db.close
      return false, hash, message_dec, id
      
    elsif update
      message_enc = cipher.encrypt(message)
      puts message_enc
      puts shift
      puts id
      qry= "UPDATE documents SET message=\"#{message_enc}\""            +
           "WHERE id=\"#{id}\";"
      db.execute( qry )
      return true, hash
      
    else
      return false, hash
    end
end

def model_new(process=false, message, name, shift)
    if process
      cipher = Caesar.new shift.to_i
      message_enc = cipher.encrypt(message)
    
      db  = SQLite3::Database.new( DATABASE )
      qry = "SELECT id FROM documents ORDER BY id DESC LIMIT 1;"
      id = db.execute( qry ).join.to_i + 1
      qry = "INSERT INTO documents VALUES"                         +
          "(#{id}, \"#{name}\", \"#{message_enc}\");"
      db.execute( qry )
      db.close
      return true
    end
    return false
end

def model_destroy(process=false, id)
    db  = SQLite3::Database.new( DATABASE )
    
    if process
      qry = "DELETE FROM documents WHERE id=#{id};"
      db.execute (qry)
      qry = "SELECT id, name FROM documents;"
      hash = db.execute( qry )
      return true, hash
    end
    
    qry = "SELECT id, name FROM documents;"
    hash = db.execute( qry )
    
    db.close
    return false, hash
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

def view_destroy(deleted=false, vals)
    output = "<html>"                                              +
    "  <body>"
    
    if deleted
        output << "<p>Message deleted</p>"
    end
    
    output << "    <form action=\"http://localhost:3000/destroy\"" +
    "    method=\"GET\">"                                          +
    "      <select name=\"id\">"
    
    vals.each do |key, value|
      output << "<option value=\"#{key}\">#{value}</option><br \>"
    end
    
    output << "</select>"                                          +
    "      <input type=\"Submit\"/>"                               +
    "    </form>"                                                  +
    "  </body>"                                                    +
    "</html>"
    
    return output
end

def view_update(updated, vals, msg, id, shift)
    output = "<html>"                                              +
    "  <body>"
    
    if updated
        output << "<p>Message updated</p>"
    end
    
    if defined? msg
      output << "    <form action=\"http://localhost:3000/update\""+
      "    method=\"GET\">"                                        +
      "      <input type=\"hidden\" name=\"id\" value=\"#{id}\"/>" +
      "      <input type=\"hidden\" name=\"shift\" value=\"#{shift}\"/>" +
      "      <input name=\"message\" value=\"#{msg}\"/>"           +
      "      <input type=\"Submit\"/>"                             +
      "    </form>"
    end
    
    output << "    <form action=\"http://localhost:3000/update\"" +
    "    method=\"GET\">"                                          +
    "      <select name=\"id\">"
    
    vals.each do |key, value|
      output << "<option value=\"#{key}\">#{value}</option><br \>"
    end
    
    output << "</select>"                                          +
    "      <input name=\"shift\" value=\"Enter shift\"/>"          +
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
            process = false
            else
            process = true
          end
          
          rsp.status = 200
          rsp.content_type = "text/html"
          rsp.body = view_new( model_new(process, message, name, shift) )
          
        when "/show"
          id = req.query[ "id" ] || ""
          shift = req.query[ "shift" ] || ""
          rsp.status = 200
          rsp.content_type= "text/html"
          rsp.body = view_show( model_show(id, shift.to_i) )
          
        when "/destroy"
          id = req.query[ "id" ] || ""
        
          if id.length == 0
            process = false
          else
            process = true
          end
          
          rsp.status = 200
          rsp.content_type = "text/html"
          success, vals = model_destroy(process, id)
          rsp.body = view_destroy(success, vals )
          
        when "/update"
          message = req.query[ "message" ] || ""
          id = req.query[ "id" ] || ""
          shift = req.query[ "shift" ] || ""
        
          if message.length > 0
            update = true
            show = false
          elsif id.length > 0 && shift.length > 0
            update = false
            show = true
          end
        
          rsp.status = 200
          rsp.content_type = "text/html"
        
          updated, vals, msg, id = model_update(show, update, id, message, shift)
        
          rsp.body = view_update(updated, vals, msg, id, shift)
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
