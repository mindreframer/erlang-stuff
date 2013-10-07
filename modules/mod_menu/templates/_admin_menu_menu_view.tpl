<div class="widget" id="{{ #menu }}">
	<h3 class="widget-header">
		{_ Menu _}
	</h3>
	<div class="widget-content">

        <span class="btn-group pull-right">
            <a href="#" class="btn dropdown-toggle" data-toggle="dropdown">{_ Add menu item _} <span class="caret"></span></a>
            <ul class="dropdown-menu">
                <!-- dropdown menu links -->
                <li><a href="#" data-where="top">&uarr; {_ Add top _}</a></li>
                <li><a href="#" data-where="bottom">&darr; {_ Add bottom _}</a></li>
            </ul>
        </span>

        <p>
            {_ Click on <strong>Add menu item</strong> or <strong>Menu item</strong> to add pages. _}
            <br/>{_ Drag menu items in the menu up, down, left or right to structure the menu. _}
        </p>

        {% block menu_tree %}
		<ul class="tree-list do_menuedit" id="menu-{{ id }}" data-menuedit="item_template: '_menu_edit_item.tpl'">
			{% for mid, path, action in id.menu|menu_flat %}
				{% include "_menu_edit_item.tpl" c=forloop.counter id=mid %}
			{% endfor %}
		</ul>
		{% endblock %}
	</div>
</div>

{% include "_menu_edit_scripts.tpl" menu_id=#menu in_sorter="menu-"++id %}
