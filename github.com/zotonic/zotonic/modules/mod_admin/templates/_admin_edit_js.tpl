{% javascript %}
setTimeout(function() {
	$({{ m.session['admin_widgets']|to_json }}).each(function() {
		for (var k in this) {
			$("#"+k).adminwidget("setVisible", this[k] == "true", true);
		}});
	}, 1);
	
	$('.language-tabs > li > a[data-toggle="tab"]').live('shown', function (e) {
		if (e.target != e.relatedTarget) {
			var lang = $(e.target).parent().attr('lang');
			$("li[lang='"+lang+"']:visible > a").tab('show');
		}
});
{% endjavascript %}
