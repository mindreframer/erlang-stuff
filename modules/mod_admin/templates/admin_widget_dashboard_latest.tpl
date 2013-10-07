{% extends "admin_widget_dashboard.tpl" %}

{# 
 Display latest modified rscs

 Required arguments:
  cat= rsc category
  headline= block caption

 Optional:
  last= true|false default false
  pagelen= page length, default 5

#}

{% block widget_headline %}
    {{ headline }}
    {% if media %}
        {% button class="btn btn-mini pull-right" action={redirect dispatch="admin_media"} text=_"show all"%}
    {% else %}
        {% button class="btn btn-mini pull-right" action={redirect dispatch="admin_overview_rsc" qcat=cat} text=_"show all"%}
    {% endif %}
{% endblock %}

{% block widget_class %}{% if last %}last{% endif %}{% endblock %}

{% block widget_content %}
<table class="table do_adminLinkedTable">
    <thead>
        <tr>
            <th width="55%">{_ Title _}</th>
            <th width="45%">{_ Category _}</th>
        </tr>
    </thead>

    <tbody>
        {% for id in m.search[{latest cat=cat pagelen=pagelen|default:5}] %}
        {% if m.rsc[id].is_visible %}
        <tr class="{% if not m.rsc[id].is_published %}unpublished{% endif %}" data-href="{% url admin_edit_rsc id=id %}">
            <td>
                {% if media %}{% image id mediaclass="admin-list-dashboard" class="thumb" %}&nbsp;{% endif %}
                {{ m.rsc[id].title|striptags|default:"<em>untitled</em>" }}
            </td>
            <td>
                {{ id.category_id.short_title|default:id.category_id.title }}
                <span class="pull-right">
                    {% if id.page_url %}<a href="{{ id.page_url }}" class="btn btn-mini">{_ view _}</a>{% endif %}
                    <a href="{% url admin_edit_rsc id=id %}" class="btn btn-mini">{_ edit _}</a>
                </span>
            </td>
        </tr>
        {% endif %}

        {% empty %}
        <tr>
            <td colspan="2">
	        {_ No items. _}
            </td>
        </tr>
        {% endfor %}
    </tbody>
</table>
{% endblock %}
