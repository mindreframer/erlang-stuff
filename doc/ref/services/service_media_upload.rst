
.. include:: meta-media_upload.rst

Service URL::

  /api/base/media_upload


Request method(s):
  POST

Upload media items into Zotonic. Pass in the `file` argument for the
actual file. Because it’s a file upload, the post payload should be
`multipart/form-data` encoded (which is the standard for file
uploads). Proper authorization is needed to use this API call, either
through session cookie or using OAuth. The value returned is a single
integer with the ID of the newly created media rsc.

Other arguments to this API call that can be passed in are: title,
summary, body, chapeau, subtitle, website, page_path.

When upload succeeds it returns a JSON object like the following::

  {"rsc_id": 123}

Where `rsc_id` is the id of the newly created :term:`resource`.

In case of failure, a JSON message like the following is returned::

  {"error": {"code": 403, "message": "Access denied"}}
