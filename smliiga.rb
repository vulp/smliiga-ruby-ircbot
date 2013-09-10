require 'cinch'
require 'open-uri'
require 'nokogiri'
require 'cgi'
require 'date'

defaultPage = 'http://www.liiga.fi/'
hifkKalenteri = 'http://www.hifk.fi/matsit/kalenteri'

    url = "http://www.liiga.fi/joukkueet/#{query}/otteluohjelma.html#tabs"
    @doc = Nokogiri::HTML(open(url))     
    puts @doc.css('table.dataTable').css('td:contains("Ottelut"):next_element').text


bot = Cinch::Bot.new do
  configure do |c|
    c.nick     = "smliiga" 
    c.server   = "irc.freenode.org"
    c.channels = ["#vulpintestit"]
  end

  on :message, /^sm#seuraava$/ do |m|
    @doc = Nokogiri::HTML(open(defaultPage))
    @text = @doc.css('div.matches').css('span').text.insert(-1," ") << @doc.css('div.matches').css('ul').css('li').text 
    m.reply " #{@text}"
  end
  on :message, /^sm#otteluohjelma (.+)$/ do |m, query|
    @time = Time.new
    url = "http://www.liiga.fi/joukkueet/#{query}/otteluohjelma.html#tabs"
    @date = Date.parse(@time.strftime("%d.%m.%Y").to_s)
    @doc = Nokogiri::HTML(open(url))    
    @valCopy = ""
    @doc.css('table.dataTableDark').css('td').each_with_index do |value,index|
    if value.text =~ /\d{1,2}[.\/]\d{1,2}/
	if (Date.parse(value.text[3..-1] << @time.year.to_s).mjd - @date.mjd) >= 0 && (Date.parse(value.text[3..-1] << @time.year.to_s).mjd - @date.mjd) <= 7

		if @valCopy.length < 1
			@valCopy = value.text[3..-1] << @time.year.to_s#remove  and first day
		else
			if (Date.parse(value.text[3..-1] << @time.year.to_s).mjd - @date.mjd < Date.parse(@valCopy).mjd - @date.mjd)
				@valCopy = value.text[3..-1] << @time.year.to_s#remove  and first day
			end
		end
	end
    end
    end
    m.reply " #{@valCopy}"
  end
  on :message, /^sm#ottelut (.+)$/ do |m, query|
    url = "http://www.liiga.fi/joukkueet/#{query}/otteluohjelma.html#tabs"
    @doc = Nokogiri::HTML(open(url))     
    m.reply " #{@doc.css('table.dataTable').css('td:contains("Ottelut"):next_element').text}"    
  end

=begin
  on :message, /^ifk#tanaan$/ do |m|
    @time = Time.new
    @doc = Nokogiri::HTML(open(hifkKalenteri))
    @doc.css('table.kalenteritable').css("td.uppercase").each_with_index do |value,index|
	#example 01.09.2013,  01.9.2013, 1.09.2013
	if value.content.match(@time.strftime("%d.%m.%Y").to_s) ||
        value.content.match(@time.strftime("%d.%-m.%Y").to_s) ||
        value.content.match(@time.strftime("%-d.%-m.%Y").to_s) 	
	    m.reply " #{value.text}"
	end
    end
  end
  on :message, /^ifk#seuraava$/ do |m|
    @time = Time.new
    @doc = Nokogiri::HTML(open(hifkKalenteri))
    @valCopy = ""
    @date = Date.parse(@time.strftime("%d.%m.%Y").to_s)
    @doc.css('table.kalenteritable').css("td.uppercase").each_with_index do |value,index|
	#puts index,value
	if index == 1 && value.content =~ /\d/
	   @valCopy = value.content	
	end
	if value.content =~ /\d/ && (Date.parse(value.content).mjd - @date.mjd) >= 0 && (Date.parse(value.content).mjd - @date.mjd) <= (Date.parse(@valCopy).mjd - @date.mjd)
	   @valCopy = value.content			
	end	        
    end
    m.reply " #{@valCopy}"	
  end	
=end
end

bot.start


