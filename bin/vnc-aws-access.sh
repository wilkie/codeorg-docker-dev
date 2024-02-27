cd /app

echo "Hi"
ls ~/.aws

# We might run a VNC server to give a means of interacting with Firefox inside
# the container.
XVFB_PID=
if [[ -z ${DISPLAY} ]]; then
    export DISPLAY=:0
    Xvfb -screen :0 1024x768x16 2> /dev/null > /dev/null &
    XVFB_PID=$!
    sleep 3
    x11vnc 2> /dev/null > /dev/null &
    X11VNC_PID=$!

    echo "No DISPLAY set."
    echo "Please connect a VNC client to localhost (port 5900)"
    echo "and follow the instructions."
    echo ""
fi

# Run the aws_access binary
cd /app/src
echo "Running ./bin/aws_access"
./bin/aws_access

# Close any open VNC server sessions
if [[ ! -z ${XVFB_PID} ]]; then
    kill -9 ${X11VNC_PID}
    kill -9 ${XVFB_PID}
fi

echo "Done."
