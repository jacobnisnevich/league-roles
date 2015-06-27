$(document).ready(function() {
    $('#chatSubmit').click(function() {
        $("#form-view").hide();
        $("#spinner-view").show();
        $.post('/chat', { chat: $('#inputChat').val(), region: $('#inputRegion').val() }, function(data) {
            console.log(data);
            JSON.parse(data).forEach(function(summoner, index) {
                $("#summoner-" + index).text(summoner.name);
                $("#role-" + index).text(summoner.role);
                $("#league-" + index).text(summoner.league);
                $("#image-first-" + index).attr("src", "http://ddragon.leagueoflegends.com/cdn/5.12.1/img/champion/" + summoner.mostPlayedFirst + ".png")
                $("#image-second-" + index).attr("src", "http://ddragon.leagueoflegends.com/cdn/5.12.1/img/champion/" + summoner.mostPlayedSecond + ".png")
                $("#image-third-" + index).attr("src", "http://ddragon.leagueoflegends.com/cdn/5.12.1/img/champion/" + summoner.mostPlayedThird + ".png")
            });
            $("#spinner-view").hide();
            $("#results-view").show();
        });
    });

    $('select').material_select();

    $('#results-back').click(function() {
        $("#results-view").hide();
        $("#form-view").show();
    });

    $('.card, .custom-card').hover(
       function(){ $(this).addClass('z-depth-3') },
       function(){ $(this).removeClass('z-depth-3') }
    );

    $('.brand-logo').hover(
       function(){ $(this).addClass('shadow') },
       function(){ $(this).removeClass('shadow') }
    );
});