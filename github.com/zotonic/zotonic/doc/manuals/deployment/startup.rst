.. _manual-deployment-startup:

Automatic startup on system boot
================================

Once you have Zotonic running, you want to make sure that it
automatically starts up when the server reboots, so that the website
keeps running after a power failure, for example.


Creating an init script
-----------------------

The :ref:`Zotonic shell command <manual-cli>` can start Zotonic in the
background and stop it again.

.. highlight:: bash

An init script will just need to call the zotonic command with either
`start` or `stop`. On debian systems it might look like this::

  #!/bin/sh -e

  ### BEGIN INIT INFO
  # Provides:             zotonic
  # Required-Start:       $local_fs $remote_fs $network $time postgresql
  # Required-Stop:        $local_fs $remote_fs $network $time postgresql
  # Should-Start:         
  # Should-Stop:          
  # Default-Start:        2 3 4 5
  # Default-Stop:         0 1 6
  # Short-Description:    Zotonic
  ### END INIT INFO

  # Set any environment variables here, e.g.:
  #export ZOTONIC_IP="127.0.0.1"
  
  /usr/bin/sudo -u zotonic -i /home/zotonic/zotonic/bin/zotonic $@


For other environment variables which can be set, see :ref:`manual-deployment-env`.
