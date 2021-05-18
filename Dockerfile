ARG FROM_IMAGE=ros:melodic

FROM $FROM_IMAGE 

# Install Lubuntu desktop
# Install some goodies
# net-tools for noVNC below
# libopencv-dev
# Clean
RUN apt-get update --fix-missing && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        lubuntu-desktop \
        xvfb \
        terminator \
        vim nano \
        git gitk git-gui \
        cmake \
        qt5-default qtcreator \
        net-tools \
        libopencv-dev \
        python3-pyqt5 && \
    apt-get clean && \
    apt-get autoremove && \
    rm -r /var/lib/apt/lists/*

# Fetch and install Anaconda3 and dependencies
ARG conda_dir=/opt/anaconda3
ARG conda_bin_dir=${conda_dir}/bin
RUN wget http://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash Miniconda3-latest* -fbp $conda_dir

# Add Anaconda3 to the PATH
ENV PATH ${conda_bin_dir}:$PATH

# Update pip
# TODO conda is not properly cloning as it should here (files are copied instead of linked...)
RUN /bin/bash -c "\
    conda update -n base conda && \
    pip install --upgrade pip && \
    conda create -y -n cpu python=3.6 && \
    source activate cpu && \
    conda install -y sympy scikit-learn scikit-image pillow flask-socketio plotly nb_conda pyqtgraph seaborn pandas h5py cython && \
    conda install -y -c menpo opencv3 && \
    conda install -y -c conda-forge eventlet ffmpeg && \
    pip install moviepy peakutils jupyterthemes && \
    pip install socketIO-client transforms3d && \
    conda clean -y -a && \
    source deactivate cpu && \
    \
    conda create -y -n gpu --clone cpu && \
    \
    conda install -y -n cpu tensorflow && \
    conda clean -y -a && \
    \
    conda install -y -n gpu tensorflow-gpu && \
    conda clean -y -a && \
    \
    conda install -y -n cpu -c pytorch pytorch torchvision && \
    conda clean -y -a"

# Fetch and install NodeJS
ARG nodejs_version=14.17.0
RUN curl https://nodejs.org/dist/v${nodejs_version}/node-v${nodejs_version}-linux-x64.tar.xz -o node.tar.xz && \
    echo 'Unpacking...' && tar xf node.tar.xz && \
    mv node-* /opt/node && \
    rm node.tar.xz

# Fetch and install Chrome
RUN curl https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o chrome.deb && \
    dpkg -i chrome.deb && \
    rm chrome.deb

# Fetch and install Visual Studio Code
RUN curl https://az764295.vo.msecnd.net/stable/431ef9da3cf88a7e164f9d33bf62695e07c6c2a9/code_1.28.0-1538751525_amd64.deb -o code.deb && \
    dpkg -i code.deb && \
    rm code.deb

# Fetch and install VirtualGL
ARG virtual_gl_version=2.6.5
RUN wget https://sourceforge.net/projects/virtualgl/files/$virtual_gl_version/virtualgl_${virtual_gl_version}_amd64.deb/download -O vgl.deb && \
    dpkg -i vgl.deb && \
    rm vgl.deb

# Fetch and install TurboVNC
ARG turbovnc_version=2.2.6
RUN wget https://sourceforge.net/projects/turbovnc/files/$turbovnc_version/turbovnc_${turbovnc_version}_amd64.deb/download -O tvnc.deb && \
    dpkg -i tvnc.deb && \
    rm tvnc.deb

# Fetch and install noVNC
RUN git clone https://github.com/novnc/noVNC /opt/noVNC && \
    git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify

# Fetch and install NoMachine. See https://www.nomachine.com/DT08M00100
#RUN curl https://download.nomachine.com/download/6.2/Linux/nomachine_6.2.4_1_amd64.deb -o nomachine.deb && \
#    echo "210bc249ec9940721a1413392eee06fe *nomachine.deb" | md5sum -c && \
#    dpkg -i nomachine.deb && \
#    rm nomachine.deb

RUN sudo apt update && sudo apt install -y xfce4-panel xfce4-session


# Clean
RUN apt-get clean && \
    apt-get autoremove && \
    rm -r /var/lib/apt/lists/*

# Add NodeJS to the PATH
ENV PATH /opt/node/bin:$PATH

# Prepare for nvidia-docker - See https://github.com/plumbee/nvidia-virtualgl
LABEL com.nvidia.volumes.needed="nvidia_driver"
ENV PATH /usr/local/nvidia/bin:/opt/VirtualGL/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}

# Set this variable so that Gazebo properly loads its UI when using VirtualGL - See https://github.com/P0cL4bs/WiFi-Pumpkin/issues/53
ENV QT_X11_NO_MITSHM 1

# Create a utils/ dir and add it to the PATH.
ARG utils_bin_dir=/opt/utils/bin
RUN sudo mkdir -p ${utils_bin_dir}
ENV PATH ${utils_bin_dir}:$PATH

# Create a command to run Jupyter notebooks
ARG jupyter_run=${utils_bin_dir}/jupyter-server-run
RUN printf "%s\n" \
           "#!/bin/bash" \
           "" \
           "jupyter notebook --no-browser --ip='*'" > ${jupyter_run} \
    && \
    chmod a+x ${jupyter_run}

# Create a command to set the jupyter theme
ARG jupyter_theme=${utils_bin_dir}/jupyter-theme-set
RUN printf "%s\n" \
           "#!/bin/bash" \
           "" \
           "jt -T -cellw 1400 -t chesterish -fs 8 -nfs 6 -tfs 6" > ${jupyter_theme} \
    && \
    chmod a+x ${jupyter_theme}

# Add a user
RUN useradd -m -s /bin/bash orion

# Add a group, assign the user to it and give the group sudo rights.
# It's useful to give sudo rights to the group, instead of to the user, so that
# sudo will continue to work in case the user is renamed. 
RUN groupadd sudonopass
RUN usermod -a -G sudonopass orion
RUN echo "%sudonopass ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# The next commands will be run as the new user
USER orion

# Seems to be needed here instead of above...
# Configure VirtualGL
RUN sudo /opt/VirtualGL/bin/vglserver_config -config +s +f -t

# Create some useful default aliases
RUN printf "%s\n" \
           "alias cp=\"cp -i\"" \
           "alias mv=\"mv -i\"" \
           "alias rm=\"rm -i\"" >> ~/.bash_aliases

# Set Keras to use Tensorflow
RUN mkdir ~/.keras && echo "{ \"image_dim_ordering\": \"tf\", \"epsilon\": 1e-07, \"backend\": \"tensorflow\", \"floatx\": \"float32\" }" >  ~/.keras/keras.json

# Set the cpu env as default
RUN echo "source activate cpu" >> ~/.bashrc

# Run these import once so they don't happen every time the container is run
# Matplotlib needs to build the font cache
RUN /bin/bash -c "source activate cpu && python -c 'import matplotlib.pyplot as plt'"
# Download ffmpeg
#RUN /bin/bash -c "source activate cpu && (echo 'import imageio'; echo 'imageio.plugins.ffmpeg.download()') | python"
#RUN (echo "import imageio"; echo "imageio.plugins.ffmpeg.download()") | python

# Set the working directory
WORKDIR /src

# The port where the vnc server will be running
EXPOSE 5901
# The port where the noVNC server will be running
EXPOSE 6080
# The port where jupyter will be running
EXPOSE 8888

# Create a command to run when the container starts.
# It will ask to create a user password and launch a NoMachine server if
# the $LAUNCH_NOMACHINE variable is set. The user password won't be saved
# between sessions (unlike the VNC password).
# It will create a screen and launch TurboVNC, with an option to run noVNC as
# well if the $LAUNCH_NOVNC environment variable is set.
ENV startup=${utils_bin_dir}/startup
RUN printf "%s\n" \
           "#!/bin/bash" \
           "" \
           "if ! [ -z \${LAUNCH_NOMACHINE+x} ] ; then" \
           "  # Check password status, and set a password if not set"\
           "  PASS_STATUS=\"\$(passwd --status | awk '{print \$2}')\"" \
           "  if [ \"\$PASS_STATUS\" != \"P\" ] ; then" \
           "    echo You have to set a password for user \'\$(whoami)\' in order to use NoMachine:" \
           "    sudo passwd --quiet -d \$(whoami)" \
           "    passwd" \
           "    if [ \$? -ne 0 ] ; then" \
           "      exit \$?" \
           "    fi" \
           "  fi" \
           "  # \$LAUNCH_NOMACHINE variable is set. Launch the NoMachine server" \
           "  sudo /etc/NX/nxserver --startup" \
           "fi" \
           "" \
           "if ! [ -z \${LAUNCH_NOVNC+x} ] ; then" \
           "  # \$LAUNCH_NOVNC variable is set. Launch TurboVNC, and if successful, noVNC" \
           "  /opt/TurboVNC/bin/vncserver" \
           "  if [ \$? -eq 0 ] ; then" \
           "    /opt/noVNC/utils/launch.sh --vnc localhost:5901;" \
           "  fi" \
           "else" \
           "  # \$LAUNCH_NOVNC variable is NOT set. Launch TurboVNC only" \
           "  /opt/TurboVNC/bin/vncserver" \
           "fi" | sudo tee ${startup} > /dev/null  \
           "xfce4-session --display=:1 &" \
    && \
    sudo chmod a+x ${startup}

# Run the startup script
# Variable expansion doesn't work when using the array version of command,
# so we're manually expanding ${startup} here...
# We do this instead of CMD so that the ${startup} script runs as PID 1 and not
# as a subprocess
CMD ["/opt/utils/bin/startup"]