class ChatParser
  attr_reader :summoners, :data

  def initialize(chat, region = "na")
    @chat = chat
    @region = region

    @summoners = Set.new

    # tokenize chat by newline characters
    @chatsplit = @chat.split(/\r?\n/)

    # loop through each line of chat to get summoners
    @chatsplit.each do |chatline|
      if chatline =~ / joined the room./
        count = (chatline =~ / joined the room./)
        @summoners.add chatline[0, count]
      end
      if chatline =~ /:/
        count = (chatline =~ /:/)
        @summoners.add chatline[0, count]
      end
    end

    # convert summoners set to array
    @summarray = @summoners.to_a

    # connect to LoL API
    client = Lol::Client.new(ENV['LOL_KEY'], {region: region})

    # get Riot API data for summoners
    @data = []
    @summonerids = []
    @summonerinfo = client.summoner.by_name(@summarray)
    @summonerinfo.each do |summoner|
      @data.push({ :id => summoner.id, :name => summoner.name })
      @summonerids.push summoner.id
    end

    # get ranked stats for each summoner to find most played champs
    @summonerids.each_with_index do |summoner, index|
      @stats = client.stats.ranked(summoner)
      @champs = @stats.champions.sort {|a, b| a.stats[:total_sessions_played] <=> b.stats[:total_sessions_played]}
      @mostPlayedFirst = client.static.champion.get(@champs[@champs.length - 2].id)[:key]
      data[index][:mostPlayedFirst] = @mostPlayedFirst
      @mostPlayedSecond = client.static.champion.get(@champs[@champs.length - 3].id)[:key]
      data[index][:mostPlayedSecond] = @mostPlayedSecond
      @mostPlayedThird = client.static.champion.get(@champs[@champs.length - 4].id)[:key]
      data[index][:mostPlayedThird] = @mostPlayedThird
    end

    # get summoner league and tier
    @leagues = client.league.get(@summonerids)
    @summonerids.each_with_index do |summoner, index|
      tier = @leagues[@summonerids[index].to_s][0].tier.capitalize
      leagueinfo = @leagues[@summonerids[index].to_s][0].entries.select {|item| item.player_or_team_id == @summonerids[index].to_s}
      league = leagueinfo[0].division
      leaguestring = "#{tier} #{league}"
      data[index][:league] = leaguestring
    end
  end
end