<a id="{{ #fb_logon }}" href="#facebook"><img src="/lib/images/fb-login-button.png" width="154" height="22" alt="Facebook login button" /></a>

{% wire id=#fb_logon 
	action={mask target=mask_target|default:"logon_outer" message="Waiting for Facebook …"}
	postback={logon_redirect ready_page=page user_id=user_id}
	delegate=`mod_facebook`
%}
