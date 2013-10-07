{% extends "base.tpl" %}

{# Simple page for TEXT (no media, as simple as possible) #}

{% block content %}
<div {% block content_attributes %}{% include "_language_attrs.tpl" id=id %}{% endblock %}>
	{% include "_title.tpl" %}
	{% block main %}
		{% include "_meta.tpl" %}

		{% block summary %}
		{% if m.rsc[id].summary %}
			<p class="summary"><b>{{ m.rsc[id].summary }}</b></p>
		{% endif %}
		{% endblock %}

		{% include "_address.tpl" %}

		{% block subnav %}
			{% include "_subnav.tpl" %}
		{% endblock %}

		{% block body %}
		<div class="body">
			{{ m.rsc[id].body }}
			{% include "_blocks.tpl" %}
		</div>
		{% endblock %}

		{% block below_body %}{% endblock %}

		{% block related %}
			{% include "_content_list.tpl" list=id.o.hasfeatured %}
			{% include "_content_list.tpl" list=id.o.hasdocument title=_"Documents"%}
			{% include "_content_list.tpl" list=id.o.depiction title=_"Media"%}

			{% include "_content_list.tpl" list=id.o.haspart title=_"More" %}
			{% include "_content_list.tpl" list=id.o.relation %}

			{% include "_content_list.tpl" list=m.rsc.sidebar_collection.o.haspart %}
		{% endblock %}
	{% endblock %}
</div>
{% endblock %}
