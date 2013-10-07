{# Parent template for admin edit widgets. #}

{% block widget_wrapper %}
{% block widget_before %}{% endblock %}

<div id="{% block widget_id %}{% endblock %}" class="{% if in_dialog %}dialog-{% endif %}widget {% block widget_class %}{% endblock %} do_adminwidget" data-adminwidget="minifiedOnInit: {% block widget_show_minimized %}false{% endblock %}, minifier: {% if show_opened %}false{% else %}true{% endif %}">
    {% block widget_header %}
        {% if not in_dialog and not noheader %}
        <h3 class="widget-header">
            {% block widget_title %}{% endblock %}
        </h3>
        {% endif %}
    {% endblock %}
    <div class="widget-content">
        {% block widget_content_nolang_before %}{% endblock %}
    	{% block widget_content %}{% endblock %}
        {% block widget_content_nolang %}{% endblock %}
    </div>
</div>


{% block widget_after %}{% endblock %}

{% endblock %}
