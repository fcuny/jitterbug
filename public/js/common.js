$(document).ready(function() {
    $('.builds-day').click(function() {
        var commit_id = $(this).attr('id').replace("builds","commits");
        console.log(commit_id);
        $("#" + commit_id).toggle();
    });
    /* This times out on large test outputs
    $('.builds a').click(function() {
        var url = $(this).attr("href");
        var id = $(this).parents('.commit').attr('id');
        $.getJSON(url, null, function(data) {
            $("#result-" + id).html("<pre>" + data.content + "<pre>").toggle();
        });
        return false;
    })
    */
})
