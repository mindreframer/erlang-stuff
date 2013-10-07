/* adminwidget js
----------------------------------------------------------

@package:	Zotonic 2009, 2012
@Author:	Tim Benniks <tim@timbenniks.nl>

Copyright 2009 Tim Benniks
Copyright 2012 Arjan Scherpenisse

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

---------------------------------------------------------- */

$.widget("z.adminwidget", 
{
    _init: function() 
    {
	    var self = this;
	    self.element.addClass("widget-active");
	    self.item = self.element.find("div.widget-content");
	    self.header = self.element.find("h3:first");
        self.tabs = self.element.find(".language-tabs");
        if (self.options.minifier) {
            self.icon = $("<i>").appendTo(self.header);
            self.header
                .css("cursor", "pointer")
                .bind("mouseover", function(){self.icon.addClass('icon-white');})
                .bind("mouseout", function(){self.icon.removeClass('icon-white');})
                .attr("title", z_translate("Click to toggle"))
                .click(function(ev){self.toggle(ev);});
        }
        if (self.options.minifiedOnInit && self.options.minifier)
            self.hide(true);
        else
            self.show(true);
    },

    toggle: function(ev) {
    	if (	$(ev.target).hasClass('widget-header')
    		||	$(ev.target).hasClass('icon-plus')
    		||	$(ev.target).hasClass('icon-minus')) {
		    var self = this;
		    var id = self.element.attr("id");
		    self.setVisible(!self.showing);
	    	if (id) z_event("adminwidget_toggle", {id: id, showing: self.showing});
	    	ev.stopPropagation();
	    }
    },

    setVisible: function(v, skipAnim) {
	    var self = this;
	    v ? self.show(skipAnim) : self.hide(skipAnim);
    },
    
    hide: function(skipAnim) {
	    var self = this;
	    if (skipAnim) 
	        self.item.hide();
	    else
	        self.item.slideUp(200);
        if (self.tabs)
            self.tabs.hide();
	    self.icon.attr("class", "pull-right icon-plus");
	    self.showing = false;
    },

    show: function(skipAnim) {
	    var self = this;
	    if (skipAnim) 
	        self.item.show();
	    else
	        self.item.slideDown(200);
        if (self.tabs)
            self.tabs.show();
	    if (self.icon)
            self.icon.attr("class", "pull-right icon-minus");
	    self.showing = true;
    }
});

$.z.adminwidget.defaults = {
    minifiedOnInit: false,
    minifier: true
};