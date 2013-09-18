# encoding: UTF-8
require 'cinch'
require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'date'
@@version = 1.1

bot = Cinch::Bot.new do
  configure do |c|
    c.nick     = "smliiga" 
    c.server   = "irc.freenode.org"
    c.channels = ["#vulpintestit"]
  end

  on :message, /^sm#otteluohjelma (.+)$/ do |m, query|
    @time = Time.new
    begin	
    	url = "http://www.liiga.fi/joukkueet/#{query}/otteluohjelma.html#tabs"
	@date = Date.parse(@time.strftime("%d.%m.%Y").to_s)
	@doc = Nokogiri::HTML(open(url))
    rescue Exception => e 
	puts "EXCEPTION: " << e.message
    end	    
    begin
    @valCopy = ""#pvm
    @timeCopy = ""#clock
    @match = ""#match
    @doc.css('table.dataTableDark').css('tr').each_with_index do |value,index|
    val = value.css('td')[1]

    if val.to_s =~ /\d{1,2}[.\/]\d{1,2}./
	if (Date.parse(val.text[3..-1] << @time.year.to_s).mjd - @date.mjd) >= 0 && (Date.parse(val.text[3..-1] << @time.year.to_s).mjd - @date.mjd) <= 7

		if @valCopy.length < 1
			@valCopy = val.text[3..-1] << @time.year.to_s#remove  and first day
			@timeCopy = value.css('td')[2]
			@match = value.css('td')[3]
		else
			if (Date.parse(val.text[3..-1] << @time.year.to_s).mjd - @date.mjd < Date.parse(@valCopy).mjd - @date.mjd)
				@valCopy = val.text[3..-1] << @time.year.to_s#remove  and first day
				@timeCopy = value.css('td')[2]
				@match = value.css('td')[3]
			end
		end
	end
    end

    end
    m.reply " #{@valCopy} #{@timeCopy.text} #{@match.text}"
    rescue Exception => e 
	puts e.message    
    end
  end
  on :message, /^sm#(.+)#(.+)$/ do |m,joukkue,tilasto|
    begin
	url = "http://www.liiga.fi/joukkueet/#{joukkue}.html"
	@doc = Nokogiri::HTML(open(url))     
    rescue Exception => e
   	puts "EXCEPTION: " << e.message 
    end
    begin
    @doc.css('table.dataTable').css('tr').each_with_index do |value,index|
    if value.content.match(tilasto)
      val = value.css('td')[1]
      m.reply " #{val.text}"    
    end
    end
    rescue Exception => e
	puts "EXCEPTION: " << e.message
    end
  end
  on :message, /^sm#tilastot (.+)$/ do |m, joukkue|
    begin
	url = "http://www.liiga.fi/joukkueet/#{joukkue}/tilastot.html#tabs"
	@doc = Nokogiri::HTML(open(url))  
    rescue Exception => e
	puts "EXCEPTION:" << e.message
    end
    begin
	@val = joukkue << ": "
	@val << @doc.css('div#mitaliSaldo').css('h3').text
	@doc.css('div#mitaliSaldo').css('p').each_with_index do |value,index|
	@val << value.text << ","
	end
    	m.reply " #{@val}"
    rescue Exception => e
	puts "EXCEPTION: " << e.message
    end
  end
  on :message, /^sm#sijoitus (.+)$/ do |m, sija|
        begin
  	    url = "http://www.liiga.fi/tilastot/sarjataulukko.html?s="
	    url << Time.now.strftime("%y").to_s << "-" << (Time.now.strftime("%y").to_i+1).to_s
	    @doc = Nokogiri::HTML(open(url))  
        rescue Exception => e
	    puts "EXCEPTION: " << e.message
        end
        begin
	@kaikki = ""
	@doc.css('table.teamTable')[0].css('tr').each_with_index do |value,index|
		if index > 0
		@val = value.css('td')[1]
		if sija.length > 0 && sija.to_i > 0 && sija.to_i < 15 && sija.to_i == index 		
			@val = value.css('td')[1]
			m.reply " #{@val.text}" 
		elsif sija.length > 0 && sija.match('kaikki')
			@val = value.css('td')[1]
			@kaikki << @val.text << ", "
		elsif sija.length > 0 && sija.downcase.match(@val.text.downcase)
			m.reply " #{index}"	
		end
		end	
	end
	if sija.length > 0 && sija.match('kaikki')
		m.reply " #{@kaikki}"	
	end
        rescue Exception => e
	    puts "EXCEPTION: " << e.message
        end
  end
  on :message, /^sm#sarjataulu (.+)$/ do |m, joukkue|
        begin
	    url = "http://www.liiga.fi/tilastot/sarjataulukko.html?s="
	    url << Time.now.strftime("%y").to_s << "-" << (Time.now.strftime("%y").to_i+1).to_s
    	    @doc = Nokogiri::HTML(open(url))  
        rescue Exception => e
  	    puts "EXCEPTION: " << e.message
        end 
	begin
	@sarjataulukko = ""
	@joukkuetaulukko = ""
	if joukkue.length > 0
	@doc.css('table.teamTable')[0].css('tr').each_with_index do |value,index|
	for i in 0..13
		if index == 0	
			@val = value.css('th')[i]
			if i == 1
			@val << "N"
			end
			@sarjataulukko << @val.text << ", "	
		elsif index > 0 && joukkue.downcase.match((value.css('td')[1]).text.downcase)
			@val = value.css('td')[i]
			@joukkuetaulukko << @val.text << ", "
		end		
	end
	end
	end
	m.reply " #{@sarjataulukko}"
	m.reply " #{@joukkuetaulukko}"
        rescue Exception => e
	    puts "EXCEPTION: " << e.message
        end
  end
  on :message, /^sm#version$/ do |m|
	begin
	url = "https://github.com/vulp/smliiga-ruby-ircbot/blob/master/README"
	@doc = Nokogiri::HTML(open(url))
        @repov = @doc.css('table.file-code').css('div').last.text[8..-1]
	m.reply "version: #{@@version}|||version in repo: #{@repov}"
        rescue Exception => e
	    puts "EXCEPTION IN VERSION: " << e.message
   	    m.reply "version: #{@@version}"
        end	 	
  end
  on :message, /^sm#info (.+)#(.+)$/ do |m, joukkue,info|
	begin
	url = "http://www.liiga.fi/joukkueet/#{joukkue}.html"
	@doc = Nokogiri::HTML(open(url))
        @val = ""
	@doc.css('div.colLeft').css('div.blackBox').css('p').each_with_index do |value,index|
	if value.text.downcase.match(info.downcase)
		@val = value.text
	end
	end
	m.reply " #{@val}"
        rescue Exception => e
	    puts "EXCEPTION: " << e.message
        end
  end
  on :message, /^sm#help$/ do |m|
  m.reply " Commands: sm#otteluohjelma joukkue, sm#joukkue#tilasto, sm#tilastot joukkue, sm#sijoitus 1-14,sm#sijoitus joukkue, sm#sijoitus kaikki, sm#sarjataulu joukkue,sm#version, sm#info joukkue#tieto"    
  end
  on :message, /^sm#help (.+)$/ do |m, help|
  if help.match('otteluohjelma')
     m.reply " Example: sm#otteluohjelma hifk"    
  elsif help.match('tilasto')
     m.reply " Example: sm#hifk#Ottelut, sm#hifk#(Ottelut, Voitot, Tasapelit, Häviöt, Tehdyt maalit, Päästetyt, maalit, Tehdyt maalit / ottelu, Päästetyt maalit / ottelu, Ylivoimamaalit, Alivoimamaalit,  Rangaistukset, Laukaukset, Pisteet, Jatkoaikavoitot, Jatkoaikahäviöt, Voittomaalikilpailujen, voitot, Voittomaalikilpailujen häviöt, Yleisömäärä kotiotteluissa)"    
  elsif help.match('sarjataulu')
    m.reply "Ottelut, Voitot,Tasapelit, Häviöt, Tehdyt maalit, Päästetyt maalit, Lisäpisteet, Pisteet, Pisteitä/ottelut, Perättäiset voitot, Perättäiset tasapelit, Perättäiset häviöt"
  elseif help.match('version')
    m.reply " bot version"
  elseif help.match('info')	
    m.replse "sm#info joukkue#Perustettu"
  end
  end
end



bot.start



