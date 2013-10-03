# encoding: UTF-8
require 'cinch'
require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'date'
@@version = 1.6
@@prefix = "!liiga#"#default prefix
@@defaultTeam = "hifk"#default team
@@defaultChannel = "#vulpintestit"#default channel
@@defaultNick = "smliiga"#default nick
@oldTopic = ""

class NextMatch

  def match(team)     
    @time = Time.new
    begin	
    	url = "http://www.liiga.fi/joukkueet/#{team}/otteluohjelma.html#tabs"
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
    return "" << @valCopy << " " << @timeCopy.text << " " << @match.text
    rescue Exception => e 
	puts e.message    
    end	
  end
end

class TimedPlugin
  include Cinch::Plugin

  timer 43200, method: :timedTopic # change topic every 12 hours
  def timedTopic
    @p = NextMatch.new
    @newTopic = @p.send( :match, @@defaultTeam)
    if @newTopic != @oldTopic
        Channel(@@defaultChannel).topic=(@p.send( :match, @@defaultTeam))#needs spam fix?
        @oldTopic = @newTopic
    end
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.nick     = @@defaultNick 
    c.server   = "irc.freenode.org"
    c.channels = [@@defaultChannel]
    c.plugins.plugins = [TimedPlugin]
  end
  
  on :message, /^#{@@prefix} changeTopic$/ do     
    begin
    @p = NextMatch.new	
    Channel(@@defaultChannel).topic=(@p.send( :match, @@defaultTeam))
    rescue Exception => e 
	puts e.message    
    end	
  end
  on :message, /^#{@@prefix} nextMatch (.+)$/ do |m, query|
      @p = NextMatch.new
      m.reply @p.send( :match, query)
  end
  on :message, /^#{@@prefix} statistics (.+)#(.+)$/ do |m,joukkue,tilasto|
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
	puts value,index 
    end
    end
    rescue Exception => e
	puts "EXCEPTION: " << e.message
    end
  end
  on :message, /^#{@@prefix} medal balance (.+)$/ do |m, joukkue|
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
  on :message, /^#{@@prefix} ranking (.+)$/ do |m, sija|
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
  on :message, /^#{@@prefix} standings (.+)$/ do |m, joukkue|
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
  on :message, /^#{@@prefix} bot version$/ do |m|
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
  on :message, /^#{@@prefix} team info (.+)#(.+)$/ do |m, joukkue,info|
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
  on :message, /^#{@@prefix} help$/ do |m|
  m.reply " Commands: #{@@prefix} changeTopic , #{@@prefix} nextMatch hifk , #{@@prefix} statistics hifk#voitot , #{@@prefix} medal balance hifk , #{@@prefix} ranking (hifk,kaikki,1-14), #{@@prefix} standings hifk, #{@@prefix} bot version, #{@@prefix} team info hifk#perustettu"
  end
  on :message, /^#{@@prefix} help (.+)$/ do |m,query|
  if query.downcase.match("statistics")
     m.reply "Ottelut, Voitot,Tasapelit, Häviöt, Tehdyt maalit, Päästetyt maalit, Lisäpisteet, Pisteet, Pisteitä/ottelut, Perättäiset voitot, Perättäiset tasapelit, Perättäiset häviöt" 
  elsif query.downcase.match("team info")
     m.reply "Perustettu, Kotikenttä, Kotisivu, Puheenjohtaja, Toimitusjohtaja, Päävalmentaja, Kapteenisto"
  else
     m.reply "todo!"
  end
  end
end


bot.start





