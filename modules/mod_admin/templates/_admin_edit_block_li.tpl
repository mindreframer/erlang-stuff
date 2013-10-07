{% with is_editable|default:id.is_editable as is_editable %}
<li id="{{ #block }}" class="block do_adminwidget">
    <h3 class="widget-header">
        <i title="{_ Drag to change position _}" class="icon-move"></i>
        <span title="{_ Disconnect _}" class="icon-remove"></span>
        {{ blk.type|make_list|capfirst|replace:"_":" " }} {_ block _}
        <input type="text" class="block-name" name="block-{{#s}}-name" id="block-{{#s}}-name" value="{{ blk.name|escape }}" title="{_ Block name _}" placeholder="{_ name _}" />
    </h3>
    <div class="widget-content">
        <input type="hidden" class="block-type" name="block-{{#s}}-type" value="{{ blk.type }}" />
        {% include ["blocks/_admin_edit_block_li_",blk.type,".tpl"]|join name=#s blk=blk id=id is_editable=is_editable is_new=is_new %}
    </div>
    {% if is_new %}
        {% javascript %}
            z_tinymce_init();
        {% endjavascript %}
    {% endif %}
    
    {% include "_admin_edit_block_addblock.tpl" %}
</li>
{% endwith %}

{% if is_new %}
{% javascript %}
    $("#{{ #block }} .widget").effect("highlight");
    z_admin_ensure_block_names();
{% endjavascript %}
{% endif %}
