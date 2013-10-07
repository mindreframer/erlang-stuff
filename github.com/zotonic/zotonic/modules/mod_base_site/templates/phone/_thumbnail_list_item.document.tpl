{% if id.is_visible and id.is_published %}
<li class="span4 thumbnail">
	<a href="{{ id.page_url }}" class="thumbnail"><img src="{% image_url id mediaclass="base-thumbnail-document" %}" alt="{{ id.title }}" title="{{id.title}}"/></a>
	<p class="caption"><span class="icon icon-book"></span> <a href="{{ id.page_url }}">{{ id.summary|default:id.title|truncate:60 }}</a></p>
</li>
{% endif %}
