if uname -a | grep Darwin 1>/dev/null && \
   [ -d /opt/local/bin ] &&
   [ -d /opt/local/sbin ]; then

# Adapting your PATH environment variable for use with MacPorts.
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"

fi

