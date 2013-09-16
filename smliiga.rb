# encoding: UTF-8
require 'cinch'
require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'date'

bot = Cinch::Bot.new do
  configure do |c|
    c.nick     = "smliiga" 
    c.server   = "irc.freenode.org"
    c.channels = ["#vulpintestit"]
  end

  on :message, /^sm#otteluohjelma (.+)$/ do |m, query|
    @time = Time.new
    url = "http://www.liiga.fi/joukkueet/#{query}/otteluohjelma.html#tabs"
    @date = Date.parse(@time.strftime("%d.%m.%Y").to_s)
    @doc = Nokogiri::HTML(open(url))    
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
  end
  on :message, /^sm#(.+)#(.+)$/ do |m,joukkue,tilasto|
    url = "http://www.liiga.fi/joukkueet/#{joukkue}.html"
    @doc = Nokogiri::HTML(open(url))     
    @doc.css('table.dataTable').css('tr').each_with_index do |value,index|
    if value.content.match(tilasto)
      val = value.css('td')[1]
      m.reply " #{val.text}"    
    end
    end
  end
  on :message, /^sm#tilastot (.+)$/ do |m, joukkue|
    url = "http://www.liiga.fi/joukkueet/#{joukkue}/tilastot.html#tabs"
    @doc = Nokogiri::HTML(open(url))  
    @val = joukkue << ": "
    @val << @doc.css('div#mitaliSaldo').css('h3').text
    @doc.css('div#mitaliSaldo').css('p').each_with_index do |value,index|
    @val << value.text << ","
    end
    m.reply " #{@val}"
  end
  on :message, /^sm#sijoitus (.+)$/ do |m, sija|
	url = "http://www.liiga.fi/tilastot/sarjataulukko.html?s="
	url << Time.now.strftime("%y").to_s << "-" << (Time.now.strftime("%y").to_i+1).to_s
	@doc = Nokogiri::HTML(open(url))  
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
		elsif sija.length > 0 && sija.match(@val)
			m.reply " #{index}"	
		end
		end	
	end
	if sija.length > 0 && sija.match('kaikki')
		m.reply " #{@kaikki}"	
	end
  end
  on :message, /^sm#sarjataulu (.+)$/ do |m, joukkue|
	url = "http://www.liiga.fi/tilastot/sarjataulukko.html?s="
	url << Time.now.strftime("%y").to_s << "-" << (Time.now.strftime("%y").to_i+1).to_s
	@doc = Nokogiri::HTML(open(url))  
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
		elsif index > 0 && joukkue.match(value.css('td')[1])
			@val = value.css('td')[i]
			@joukkuetaulukko << @val.text << ", "
		end		
	end
	end
	end
	m.reply " #{@sarjataulukko}"
	m.reply " #{@joukkuetaulukko}"
  end
  on :message, /^sm#help$/ do |m|
  m.reply " Commands: sm#otteluohjelma joukkue, sm#joukkue#tilasto, sm#tilastot joukkue, sm#sijoitus 1-14,sm#sijoitus joukkue, sm#sijoitus kaikki, sm#sarjataulu joukkue"    
  end
  on :message, /^sm#help (.+)$/ do |m, help|
  if help.match('otteluohjelma')
     m.reply " Example: sm#otteluohjelma hifk"    
  elsif help.match('tilasto')
     m.reply " Example: sm#hifk#Ottelut, sm#hifk#(Ottelut, Voitot, Tasapelit, Häviöt, Tehdyt maalit, Päästetyt, maalit, Tehdyt maalit / ottelu, Päästetyt maalit / ottelu, Ylivoimamaalit, Alivoimamaalit,  Rangaistukset, Laukaukset, Pisteet, Jatkoaikavoitot, Jatkoaikahäviöt, Voittomaalikilpailujen, voitot, Voittomaalikilpailujen häviöt, Yleisömäärä kotiotteluissa)"    
  elsif help.match('sarjataulu')
    m.reply "Ottelut, Voitot,Tasapelit, Häviöt, Tehdyt maalit, Päästetyt maalit, Lisäpisteet, Pisteet, Pisteitä/ottelut, Perättäiset voitot, Perättäiset tasapelit, Perättäiset häviöt"
  end
  end
end



bot.start



