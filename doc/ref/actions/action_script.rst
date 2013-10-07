
.. include:: meta-script.rst


This action executes Javascript directly. It can be used to interface with non-Zotonic Javascript libraries and functions.

Example::

   {% button title="hello" action={script script="alert('hello world')"} %}

Clicking on the button will show a Javascript alert with the text `hello world` in it.
