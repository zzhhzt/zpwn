FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# Password arguments (can be overridden during build)
ARG ROOT_PASSWORD=123456
ARG ZPWN_PASSWORD=123456

# 0. Global Environment Settings
ENV TZ=Asia/Shanghai
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# 1. System Setup and Package Installation (Optimized)
RUN dpkg --add-architecture i386 && \
    sed -i 's@//.*archive.ubuntu.com@//mirrors.tuna.tsinghua.edu.cn@g' /etc/apt/sources.list.d/ubuntu.sources && \
    sed -i 's@//.*security.ubuntu.com@//mirrors.tuna.tsinghua.edu.cn@g' /etc/apt/sources.list.d/ubuntu.sources && \
    apt-get -y update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    lib32z1 apt-transport-https \
    python3 python3-pip python3-venv python3-poetry python3-dev python3-setuptools \
    libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev libc6-dbg libc6-dbg:i386 libgcc-s1:i386 \
    vim nano netcat-openbsd openssh-server git unzip curl tmux konsole wget sudo \
    bison flex build-essential gcc-multilib \
    qemu-system-x86 qemu-user qemu-user-binfmt \
    gcc gdb gdbserver gdb-multiarch clang lldb make cmake \
    zsh \
    ruby-full \
    patchelf \
    nasm \
    cpio \
    zstd \
    file \
    gawk \
    net-tools \
    iputils-ping \
    libffi-dev \
    libssl-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 2. SSH and User Configuration (Combined)
RUN rm -f /etc/service/sshd/down && \
    sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -ri 's/#UseDNS\ no/UseDNS\ no/g' /etc/ssh/sshd_config && \
    sed -ri "s/StrictModes yes/StrictModes no/g" /etc/ssh/sshd_config && \
    sed -ri "s/UsePAM yes/UsePAM no/g" /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    usermod -l zpwn -d /home/zpwn -m ubuntu && \
    groupmod -n zpwn ubuntu && \
    echo "root:${ROOT_PASSWORD}" | chpasswd && \
    echo "zpwn:${ZPWN_PASSWORD}" | chpasswd && \
    echo "zpwn ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# 3. Python Venv, Tmux Configuration and Startup Script (Optimized)
RUN python3 -m venv /pip_venv && \
    chown -R zpwn:zpwn /pip_venv && \
    echo "\n\n# pip venv\nsource /pip_venv/bin/activate" >> /home/zpwn/.bashrc && \
    # Configure tmux with mouse support using heredoc
    cat > /home/zpwn/.tmux.conf << 'EOF'
# Tmux configuration with mouse support
set -g mouse on
set -g mode-keys vi
set -g history-limit 10000
setw -g mouse on
# Enable mouse scrolling
bind -n WheelUpPane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "if -Ft= '#{pane_in_mode}' 'send-keys -M' 'copy-mode -e; send-keys -M'"
# Enable mouse drag to select and copy
bind -n DragBorder if-shell -Ft= '#{mouse_any_flag}' "send-keys -M" "copy-mode -eM"
EOF
    # Configure vim with Chinese encoding support
    cat > /home/zpwn/.vimrc << 'EOF'
" Vim configuration with Chinese encoding support
" Set encoding
set encoding=utf-8
set termencoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8,gbk,gb2312,gb18030,big5

" Display settings
set ambiwidth=double
set formatoptions+=mM
set nobackup
set noswapfile

" Syntax highlighting
syntax on
set hlsearch
set incsearch

" Line numbers
set number
set relativenumber

" Indentation
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
set smarttab

" Visual settings
set ruler
set laststatus=2
set showcmd
set wildmenu
set wildmode=list:longest

" Chinese specific settings
set guifont=Courier\ New:h12
if has('gui_running')
    set guioptions+=a
endif
EOF
    cp /home/zpwn/.vimrc /root/.vimrc && \
    chown zpwn:zpwn /home/zpwn/.vimrc && \
    # Create global vim configuration for all users
    cat > /etc/vim/vimrc.local << 'EOF'
" Global vim configuration for Chinese encoding support
set encoding=utf-8
set termencoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8,gbk,gb2312,gb18030,big5
set ambiwidth=double
EOF
    cp /home/zpwn/.tmux.conf /root/.tmux.conf && \
    echo "#!/bin/sh\nservice ssh restart\nsleep infinity" > /root/start.sh && \
    chmod +x /root/start.sh

# -----------------------------------------------------------------------------
# ZSH Setup (Optimized) - Single RUN for all ZSH operations
# -----------------------------------------------------------------------------
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    git clone https://github.com/zsh-users/zsh-autosuggestions /home/zpwn/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting /home/zpwn/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' /home/zpwn/.zshrc && \
    echo "\n# pip venv\nsource /pip_venv/bin/activate" >> /home/zpwn/.zshrc && \
    # Copy Zsh setup to root and configure shells
    cp -r /home/zpwn/.oh-my-zsh /root/.oh-my-zsh && \
    cp /home/zpwn/.zshrc /root/.zshrc && \
    sed -i 's|/home/zpwn|/root|g' /root/.zshrc && \
    chsh -s /bin/zsh root && \
    chsh -s /bin/zsh zpwn

# -----------------------------------------------------------------------------
# Pre-compiled Glibc Versions
# -----------------------------------------------------------------------------
WORKDIR /glibc
COPY --from=skysider/glibc_builder64:2.19 /glibc/2.19/64 /glibc/2.19/64
COPY --from=skysider/glibc_builder32:2.19 /glibc/2.19/32 /glibc/2.19/32
COPY --from=skysider/glibc_builder64:2.23 /glibc/2.23/64 /glibc/2.23/64
COPY --from=skysider/glibc_builder32:2.23 /glibc/2.23/32 /glibc/2.23/32
COPY --from=skysider/glibc_builder64:2.24 /glibc/2.24/64 /glibc/2.24/64
COPY --from=skysider/glibc_builder32:2.24 /glibc/2.24/32 /glibc/2.24/32
COPY --from=skysider/glibc_builder64:2.27 /glibc/2.27/64 /glibc/2.27/64
COPY --from=skysider/glibc_builder32:2.27 /glibc/2.27/32 /glibc/2.27/32
COPY --from=skysider/glibc_builder64:2.28 /glibc/2.28/64 /glibc/2.28/64
COPY --from=skysider/glibc_builder32:2.28 /glibc/2.28/32 /glibc/2.28/32
COPY --from=skysider/glibc_builder64:2.29 /glibc/2.29/64 /glibc/2.29/64
COPY --from=skysider/glibc_builder32:2.29 /glibc/2.29/32 /glibc/2.29/32
COPY --from=skysider/glibc_builder64:2.30 /glibc/2.30/64 /glibc/2.30/64
COPY --from=skysider/glibc_builder32:2.30 /glibc/2.30/32 /glibc/2.30/32
COPY --from=skysider/glibc_builder64:2.31 /glibc/2.31/64 /glibc/2.31/64
COPY --from=skysider/glibc_builder32:2.31 /glibc/2.31/32 /glibc/2.31/32
COPY --from=skysider/glibc_builder64:2.33 /glibc/2.33/64 /glibc/2.33/64
COPY --from=skysider/glibc_builder32:2.33 /glibc/2.33/32 /glibc/2.33/32
COPY --from=skysider/glibc_builder64:2.34 /glibc/2.34/64 /glibc/2.34/64
COPY --from=skysider/glibc_builder32:2.34 /glibc/2.34/32 /glibc/2.34/32
COPY --from=skysider/glibc_builder64:2.35 /glibc/2.35/64 /glibc/2.35/64
COPY --from=skysider/glibc_builder32:2.35 /glibc/2.35/32 /glibc/2.35/32
COPY --from=skysider/glibc_builder64:2.36 /glibc/2.36/64 /glibc/2.36/64
COPY --from=skysider/glibc_builder32:2.36 /glibc/2.36/32 /glibc/2.36/32

# -----------------------------------------------------------------------------
# 4. Install Tools and Final Configuration (Fully Optimized)
# -----------------------------------------------------------------------------
RUN gem sources --add https://mirrors.tuna.tsinghua.edu.cn/rubygems/ --remove https://rubygems.org/ && \
    gem install one_gadget seccomp-tools && \
    rm -rf /var/lib/gems/*/cache/* && \
    /pip_venv/bin/pip config set global.index-url http://pypi.tuna.tsinghua.edu.cn/simple && \
    /pip_venv/bin/pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn && \
    /pip_venv/bin/pip install -U pip && \
    /pip_venv/bin/pip install --no-cache-dir \
    setuptools \
    wheel \
    pwntools \
    ropgadget \
    z3-solver \
    smmap2 \
    apscheduler \
    ropper \
    unicorn \
    keystone-engine \
    capstone \
    angr \
    pebble \
    r2pipe \
    poetry && \
    git clone https://github.com/dev2ero/LibcSearcher.git /opt/LibcSearcher && \
    cd /opt/LibcSearcher && \
    /pip_venv/bin/python3 setup.py develop && \
    cd / && \
    git clone https://github.com/pwndbg/pwndbg /opt/pwndbg && \
    cd /opt/pwndbg && chmod +x setup.sh && ./setup.sh && \
    cd / && \
    git clone --depth 1 https://github.com/scwuaptx/Pwngdb.git /opt/Pwngdb && \
    git clone https://github.com/matrix1001/glibc-all-in-one.git /opt/glibc-all-in-one && \
    cd /opt/glibc-all-in-one && python3 update_list && \
    # GDB Configuration using heredoc for cleaner output
    cat > /root/.gdbinit << 'EOF'
source /opt/pwndbg/gdbinit.py
source /opt/Pwngdb/pwngdb.py
source /opt/Pwngdb/angelheap/gdbinit.py
define hook-run
python import angelheap
end
EOF
    # Final setup and permissions
    cp /root/.gdbinit /home/zpwn/.gdbinit && \
    chown zpwn:zpwn /home/zpwn/.gdbinit && \
    chmod -R 777 /opt/glibc-all-in-one && \
    chmod -R 755 /glibc && \
    mkdir -p /ctf/work && \
    chown -R zpwn:zpwn /ctf

# Reset WORKDIR to the new ctf work directory
WORKDIR /ctf/work

CMD ["/root/start.sh"]

EXPOSE 22
