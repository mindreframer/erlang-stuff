<table class="table">
	<tr>
		<td></td>
		<td>
			{% if a.id %}
				{% button text=_"Revert to this version" class="btn btn-success" 
					action={confirm text=_"Are you sure you want to revert to this version?"
									ok=_"Revert"
									action={postback postback={revert rsc_id=a.rsc_id rev_id=a.id}
													delegate=`controller_admin_backup_revision`}
							}
				%}
			{% else %}
				<b><ins>{_ current version _}</ins></b>
			{% endif %}
		</td>
		<td>
			{% if b.id %}
				{% button text=_"Revert to this version" class="btn btn-danger"
					action={confirm text=_"Are you sure you want to revert to this version?"
									ok=_"Revert"
									action={postback postback={revert rsc_id=b.rsc_id rev_id=b.id}
													delegate=`controller_admin_backup_revision`}
							}
				%}
			{% endif %}
		</td>
	</tr>
{% with b.id as has_diff %}
{% for k,a,b in diff %}
{% if not k|member:[`modifier_id`, `modified`, `version`] %}
	<tr {% if has_diff %}class="do_make_diff"{% endif %}>
		<th>{{ k }}</th>
 		<td>{{ a }}</td>
		<td>{{ b }}</td>
	</tr>
{% endif %}
{% endfor %}
{% endwith %}
</table>

