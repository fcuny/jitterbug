$(document).ready(function() {
    $('.builds-day').click(function() {
        var day = $(this).text();
        var class = "#commits-day-" + day;
        $(class).toggle();
    });
    $('.builds a').click(function() {
        var url = $(this).attr("href");
        var id = $(this).parents('.commit').attr('id');
        $.getJSON(url, null, function(data) {
            $("#result-" + id).html("<pre>" + data.content + "<pre>").toggle();
        });
        return false;
    })
})
