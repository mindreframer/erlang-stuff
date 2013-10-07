{% include "_survey_block_name_check.tpl" %}
<div class="control-group survey-truefalse question-{{ nr }}">
    <label class="control-label">{{ blk.prompt }}</label>
    <div class="controls">
{% if blk.is_image %}
		<img id="{{ #preview }}" class="picture-preview" width="256" src="/lib/images/noun/photo-camera.png" />
		<input type="file" class="picture-file do_filepreview" name="{{ blk.name }}" id="{{ #upload }}" 
			   class="do_filepreview" data-filepreview="preview: '{{ #preview }}'" 
			   accept="image/*" />
{% else %}
		<input type="file" name="{{ blk.name }}" id="{{ #upload }}" />
{% endif %}
    </div>
</div>

{% if blk.is_required %}
    {% validate id=#upload name=blk.name type={presence} %}
{% endif %}
