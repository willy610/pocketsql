require "http/server"
require "json"
require "./backend"
# https://forum.crystal-lang.org/t/post-request-parsing-error-could-not-find-boundary-in-content-type/5511
module HTTPSQLServer
  STDERR.puts "Crystal http server listening on 8084"
  STDERR.puts "usage: http://localhost:8084/src/httpsqlserver/index.html"
  bck = BackEnd.new
  server = HTTP::Server.new([HTTP::StaticFileHandler.new(".")]) do |ctx|
    if ctx.request.method == "GET"
      STDERR.puts "Will not process 'GET'. Use 'POST'"
    elsif ctx.request.method == "POST"
      if postbody = ctx.request.body
        modpostbody = JSON.parse(postbody.gets_to_end)
        puts modpostbody["request"]
        to_responde = bck.process_rqst(modpostbody)
        ctx.response.content_type="application/json"
        ctx.response.print to_responde
      end
    else
      STDERR.puts "HTTPSQLServer err #{ctx.request.method}'"
    end
  end
  server.bind_tcp 8084
  server.listen
end
