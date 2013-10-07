{% extends "admin_edit_widget_std.tpl" %}

{# Admin controls for the survey #}

{% block widget_title %}{_ Survey _}{% endblock %}
{% block widget_show_minimized %}false{% endblock %}
{% block widget_id %}content-survey{% endblock %}

{% block widget_before %}
{% lib "css/admin_survey.css" %}
{% endblock %}

{% block widget_content %}
<div class="row-fluid">
	<div class="span6">
		<div class="control-group">
			<label class="checkbox">
				{% if id.is_a.poll %}
					<input type="hidden" name="survey_show_results" id="survey_show_results" value="1" />
					<input type="checkbox" disabled="disabled" checked="checked" />
				{% else %}
					<input type="checkbox" name="survey_show_results" id="survey_show_results" value="1" {% if id.survey_show_results %}checked="checked"{% endif %} />
				{% endif %}
				{_ Show results to user after completion of survey _}
			</label>
			<label class="checkbox">
				<input type="checkbox" name="survey_multiple" id="survey_multiple" value="1" {% if id.survey_multiple %}checked="checked"{% endif %} />
			{_ Allow multiple entries per user/browser _}
			</label>
		</div>
	</div>

	<div class="span6">
		<div class="pull-right">
			<a href="javascript:void(0)" class="btn btn-mini btn-primary do_dialog" data-dialog="title: '{{ _"Help about surveys"|escapejs }}', text: '{{ _"You can create your survey by adding blocks with questions below the body."|escapejs }}'" title="{_ Need more help? _}"><i class="icon-question-sign icon-white"></i></a>
		</div>

		<div class="control-group">
			<label class="radio">
				<input type="radio" name="survey_progress" id="survey_progress_none" value="" {% if not id.survey_progress %}checked="checked"{% endif %} />
				{_ Hide progress information _}
			</label>
			<label class="radio">
				<input type="radio" name="survey_progress" id="survey_progres_nr" value="nr" {% if id.survey_progress == 'nr' %}checked="checked"{% endif %} />
				{_ Show progress information as “<em>Question 3/10</em>” _}
			</label>
			<label class="radio">
				<input type="radio" name="survey_progress" id="survey_progress_bar" value="bar" {% if id.survey_progress == 'bar' %}checked="checked"{% endif %} />
				{_ Show progress bar _}
			</label>
		</div>
	</div>
</div>

<div class="control-group">
	<label class="control-label">{_ Mail filled in surveys to _}</label>
	<div class="controls">
		<input type="text" class="input-large" name="survey_email" id="survey_email" value="{{ id.survey_email }}" />
	</div>
</div>

{% if m.survey.handlers|length %}
<div class="control-group">
	<label>{_ Handle this survey with _}</label>
	<div class="controls">
		<select name="survey_handler" id="survey_handler">
			<option value=""></option>
			{% for val,desc in m.survey.handlers %}
				<option value="{{ val }}" {% if id.survey_handler == val %}selected{% endif %}>{{ desc }}</option>
			{% endfor %}
		</select>
	</div>
</div>
{% endif %}

<div class="control-group">
	{% if m.survey.is_allowed_results_download[id] %}
		<a id="{{ #download }}" class="btn btn-mini" href="{% url survey_results_download id=id %}">{_ Download CSV results _}</a>
		{% wire id=#download propagate 
				action={alert text=_"Download will start in the background. Please check your download window."}
		%}
	{% endif %}
	<a class="btn btn-mini" href="{% url survey_results id=id %}">{_ Show survey results _}</a>
	<a class="btn btn-mini" href="#" id="{{ #email_addresses }}">{_ Show email addresses _}</a>
	{% wire id=#email_addresses postback={admin_show_emails id=id} delegate="mod_survey" %}
	<a class="btn btn-mini" href="{% url survey_results_printable id=id %}">{_ Printable list _}</a>
	<a class="btn btn-mini" href="{% url admin_survey_editor id=id %}">{_ Survey results editor _}</a>
</div>
{% endblock %}
