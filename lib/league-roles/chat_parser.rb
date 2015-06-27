class ChatParser
  attr_reader :summoners, :data, :chat_by_player, :preferences_by_player

  def initialize(chat, region = "na")
    @chat = chat
    @region = region

    @summoners = Set.new
    @chat_by_player = {}

    # tokenize chat by newline characters
    @chatsplit = @chat.split(/\r?\n/)

    # loop through each line of chat to get summoners
    @chatsplit.each do |chatline|
      if chatline =~ / joined the room./
        count = (chatline =~ / joined the room./)
        summoner_name = chatline[0, count]
        @summoners.add summoner_name
        @chat_by_player[summoner_name] = []
      end
      if chatline =~ /:/
        count = (chatline =~ /:/)
        summoner_name = chatline[0, count]
        summoner_chat = chatline[count + 2, chatline.length - (count + 2)]
        @summoners.add summoner_name

        # add chat to chat list
        if @chat_by_player[summoner_name].nil?
          @chat_by_player[summoner_name] = []
        end
        @chat_by_player[summoner_name].push summoner_chat
      end
    end

    @preferences_by_player = {}

    get_player_preferences()

    # convert summoners set to array
    @summarray = @summoners.to_a

    # connect to LoL API
    @client = Lol::Client.new(ENV['LOL_KEY'], {region: region})

    # get Riot API data for summoners
    @data = []
    @summonerids = []
    @summonerinfo = @client.summoner.by_name(@summarray)
    @summonerinfo.each do |summoner|
      @data.push({ :id => summoner.id, :name => summoner.name })
      @summonerids.push summoner.id
    end

    get_optimal_role()
    get_ranked_stats()
    get_summoner_league()
  end

  private

  # get player preferences from chat
  def get_player_preferences()
    @chat_by_player.keys.each do |name|
      prefWants = Set.new
      prefCan = Set.new
      # prefCannot = Set.new
      if @chat_by_player[name].empty?
        @chat_by_player[name].push "fill"
      end
      @chat_by_player[name].each do |message|
        ROLES.each do |role|
          if eval(role.upcase).any? { |word| message.downcase.include?(word) }
            prefWants.add role
          else
            prefCan.add role
          end
        end

        if FILL.any? { |word| message.downcase.include?(word) }
          ROLES.each do |role|
            prefWants.add role
          end
        end
      end
      @preferences_by_player[name] = { :wants => prefWants.to_a, :can => prefCan.to_a }
    end
  end

  def get_optimal_role()
    graph_edges = {}

    @preferences_by_player.keys.each do |name|
      graph_edges[name] = {}
      @preferences_by_player[name][:wants].each do |want|
        graph_edges[name][want] = 1
      end
      @preferences_by_player[name][:can].each do |can|
        if graph_edges[name][can].nil?
          graph_edges[name][can] = 5
        end
      end
    end

    match_result = Graphmatch.match(@summoners, ROLES, graph_edges)

    match_result.keys.each do |name|
      data_element = @data.select { |player| player[:name] == name }
      data_element[0][:role] = match_result[name]
    end
  end

  # get ranked stats for each summoner to find most played champs
  def get_ranked_stats()
    @summonerids.each_with_index do |summoner, index|
      stats = @client.stats.ranked(summoner)
      champs = stats.champions.sort {|a, b| a.stats[:total_sessions_played] <=> b.stats[:total_sessions_played]}
      mostPlayedFirst = @client.static.champion.get(champs[champs.length - 2].id)[:key]
      data[index][:mostPlayedFirst] = mostPlayedFirst
      mostPlayedSecond = @client.static.champion.get(champs[champs.length - 3].id)[:key]
      data[index][:mostPlayedSecond] = mostPlayedSecond
      mostPlayedThird = @client.static.champion.get(champs[champs.length - 4].id)[:key]
      data[index][:mostPlayedThird] = mostPlayedThird
    end
  end

  # get summoner league and tier
  def get_summoner_league()
    leagues = @client.league.get(@summonerids)

    @summonerids.each_with_index do |summoner, index|
      tier = leagues[@summonerids[index].to_s][0].tier.capitalize
      leagueinfo = leagues[@summonerids[index].to_s][0].entries.select {|item| item.player_or_team_id == @summonerids[index].to_s}
      league = leagueinfo[0].division
      leaguestring = "#{tier} #{league}"
      data[index][:league] = leaguestring
    end
  end
end