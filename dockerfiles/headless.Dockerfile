FROM codedotorg/codedotorg-web

RUN sudo apt update
RUN sudo apt install xvfb x11vnc -y
RUN sudo apt install libgl1-mesa-dev libosmesa6-dev libpci-dev firefox -y
