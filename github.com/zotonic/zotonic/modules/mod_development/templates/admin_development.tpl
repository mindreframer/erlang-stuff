{% extends "admin_base.tpl" %}

{% block title %} Development {% endblock %}

{% block content %}
    <div class="edit-header">
        <h2>{_ Site Development _}</h2>
        
        <p>{_ Tools and settings that are useful for site development. _}</p>

        <div class="well">

            <div>
                {% wire id="tpldbg" 
                    action={config_toggle module="mod_development" key="debug_includes"}
                    action={admin_tasks task='flush'} 
                %}
                <label class="checkbox inline">
                    <input type="checkbox" id="tpldbg" value="1" {% if m.config.mod_development.debug_includes.value %}checked="checked"{% endif %} />
                    {_ Show paths to included template files in generated templates _}
                </label>
            </div>

            <div>
                {% wire id="blkdbg" 
                    action={config_toggle module="mod_development" key="debug_blocks"}
                    action={admin_tasks task='flush'} 
                %}
                <label class="checkbox inline">
                    <input type="checkbox" id="blkdbg" value="1" {% if m.config.mod_development.debug_blocks.value %}checked="checked"{% endif %} />
                    {_ Show defined blocks in generated templates _}
                </label>
            </div>
            
            <div>
                {% wire id="libsep" 
                    action={config_toggle module="mod_development" key="libsep"}
                    action={admin_tasks task='flush'} 
                %}
                <label class="checkbox inline">
                    <input type="checkbox" id="libsep" value="1" {% if m.config.mod_development.libsep.value %}checked="checked"{% endif %} />
                    {_ Download css and javascript files as separate files (ie. don’t combine them in one url). _}
                </label>
            </div>
        </div>
        
        <p><a class="btn btn-mini" href="{% url admin_development_templates %}">Show which files are included in a template compilation</a></p>
        <p class="help-block">At times it can be confusing which templates are actually used during a template compilation.  Here you can see which files are included whilst compiling a template.</p>
        
    </div>
</div>
{% endblock %}
