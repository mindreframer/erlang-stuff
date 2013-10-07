{% extends "admin_edit_widget_i18n.tpl" %}

{% block widget_title %}{_ Block _}{% endblock %}
{% block widget_show_minimized %}false{% endblock %}
{% block widget_id %}edit-block-{{ #block }}{% endblock %}
{% block widget_header %}{% endblock %}

{% block widget_content %}
{% with m.rsc[id] as r %}
<fieldset class="admin-form">
	<div class="form-item clearfix">
		{% if is_editable %}
			<textarea rows="10" 
			    id="block-{{name}}-body{{ lang_code_for_id }}" 
			    name="block-{{name}}-body{{ lang_code_with_dollar }}" 
			    class="input-block-level body tinymce-init" 
			    {% include "_language_attrs.tpl" language=lang_code %}>{{ blk.body[lang_code] |escape }}</textarea>
		{% else %}
			{{ blk.body[lang_code]  }}
		{% endif %}
	</div>
</fieldset>
{% endwith %}
{% endblock %}

{% block widget_content_nolang %}
{% include "_admin_edit_block_show_as.tpl" %}
{% endblock %}
