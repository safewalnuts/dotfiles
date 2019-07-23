#!/bin/bash
set -e -u -x

function help
{
  cat <<EOF
Usage: $_ [option]

Options
  help              Print this message
  caml              Install OCaml-related things
  conda             Install Anaconda
  fonts             Install d2coding, powerline fonts
  dot               Install dotfiles
  pkg               Install packages
  rtags             Install rtags env
  zsh               Install zsh
  z                 Install z env
  all               Install all above (default)
EOF
}

ALL=yes
CONDA=
CAML=
FONTS=
DOT=
PKG=
ZSH=
Z=
RTAGS=

while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
    caml)
      ALL=no
      CAML=yes
      shift
      ;;
    conda)
      ALL=no
      CONDA=yes
      shift
      ;;
    fonts)
      ALL=no
      FONTS=yes
      shift
      ;;
    dot)
      ALL=no
      DOT=yes
      shift
      ;;
    pkg)
      ALL=no
      PKG=yes
      shift
      ;;
    rtags)
      ALL=no
      RTAGS=yes
      shift
      ;;
    zsh)
      ALL=no
      ZSH=yes
      shift
      ;;
    z)
      ALL=no
      Z=yes
      shift
      ;;
    all)
      ALL=yes
      shift
      ;;
    -h|--help|help|h|--h|-help)
      help
      exit 0
      ;;
    *)
      #unknown option
      help
      exit 2
  esac
  #shift #past argument or value
done

function install_opam_packages {
  opam install -y merlin tuareg ocp-indent ocamlformat
}

function install_opam_2.0 {
  # require sudoer
  sh <(curl -sL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)
  opam init

  opam switch create local 4.08.0 -j6
}

function install_anaconda {
  wget https://repo.anaconda.com/archive/Anaconda3-2019.03-Linux-x86_64.sh -O conda.sh
  chmod +x conda.sh
  ./conda.sh -b
  echo "source ~/anaconda3/etc/profile.d/conda.sh" >> ~/.bashrc
}

function install_my_neofetch {
  git clone https://github.com/skicombinator/neofetch
  pushd neofetch
  sudo make install
  popd

  # always print neofetch with memory usage %
  echo "neofetch --memory_percent on" >> ~/.bashrc
  echo "neofetch --memory_percent on" >> ~/.zshrc
}

function install_rustup {
  curl https://sh.rustup.rs -sSf | sh
  echo "source ~/.cargo/env" >> ~/.bashrc
}

function install_packages {
  # neovim
  sudo add-apt-repository ppa:neovim-ppa/unstable --yes

  # emacs >= 25
  sudo add-apt-repository ppa:kelleyk/emacs --yes

  sudo apt-get update

  # install my file list
  sudo apt-get install m4 emacs25 silversearcher-ag \
       tmux texlive-full ko.tex-base graphviz \
       neovim thunderbird thunderbird-locale-ko \
       ruby ruby-dev htop openssh-server curl\
       tree etckeeper gcc make cmake -y

  git submodule init
  git submodule update

  install_my_neofetch

  # install rustup instead of debian cargo package
  install_rustup
  # install useful cargo package
  cargo install dutree loc
}

function install_zsh {
  sudo apt-get install zsh cmake --yes
  curl -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh

  git clone https://github.com/bhilburn/powerlevel9k ~/.oh-my-zsh/custom/themes/powerlevel9k
  sed 's/^ZSH_THEME=\"\(.*\)\"/ZSH_THEME=\"powerlevel9k\/powerlevel9k\"/g' -i ~/.zshrc

  cat ./zsh/alias >> ~/.zshrc
  cat ./zsh/rc >> ~/.zshrc
}

function install_z {
  # z setup
  # https://github.com/rupa/z.git
  git clone --recursive https://github.com/rupa/z.git
  mkdir ~/.config -p
  mv z ~/.config/
  echo ". \$HOME/.config/z/z.sh" >> ~/.bashrc
  echo ". \$HOME/.config/z/z.sh" >> ~/.zshrc
}

function install_fonts {
  # prerequirements
  mkdir -p ~/.local/share/fonts
  sudo apt-get install zip --yes
  git submodule init
  git submodule update

  # d2coding
  pushd d2codingfont
  # 1.3.2 is latest
  unzip D2Coding-Ver1.3.2-20180524.zip
  cp D2Coding/*.ttf ~/.local/share/fonts/
  popd

  # powerline
  pushd powerline
  ./install.sh
  popd

  # load fonts
  fc-cache -vf ~/.local/share/fonts/
}

function install_dot {
  # dotfiles setting
  mkdir ~/.config -p
  mkdir ~/.config/nvim -p

  cp ./nvim/init.vim ~/.config/nvim/
  cp ./tmux/.tmux.conf ~/.tmux.conf

  # emacs setting
  mkdir ~/.emacs.d -p
  mkdir ~/.emacs.d/themes -p
  mkdir ~/.emacs.d/config -p
  mkdir ~/.emacs.d/snippets/c++-mode -p

  cp ./emacs/.editorconfig ~/
  cp ./emacs/dracula-theme.el ~/.emacs.d/themes/
  cp ./emacs/init.el ~/.emacs.d/
  cp ./emacs/config/* ~/.emacs.d/config/
  cp ./emacs/snippets/c++-mode/* ~/.emacs.d/snippets/c++-mode/

  cat ./bash/alias >> ~/.bashrc
  cat ./bash/rc >> ~/.bashrc

  # global nautilus setting
  gsettings set org.gnome.nautilus.preferences default-folder-viewer 'list-view'
  gsettings set org.gnome.nautilus.preferences default-sort-order 'type'
  gsettings set org.gnome.nautilus.preferences show-hidden-files false

  # global keyboard speed setting
  gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 30
  gsettings set org.gnome.desktop.peripherals.keyboard delay 210

  # flake8 config for emacs
  cp ./flake8/flake8 ~/.config/flake8
}

function install_rtags {
  git clone --recursive https://github.com/Andersbakken/rtags.git
  pushd rtags
  cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 .
  make -j4
  mkdir -p ~/bin/rtags
  cp bin/* ~/bin/rtags/
  echo "export PATH=\$PATH:\$HOME/bin/rtags" >> ~/.bashrc
  echo "export PATH=\$PATH:\$HOME/bin/rtags" >> ~/.zshenv
  popd
}

# check all first
if [ "$ALL" = "yes" ]; then
  #sudo apt-get install git  # git must included
  install_packages
  install_dot
  install_zsh
  install_z
  install_rtags
  install_fonts
  install_opam_2.0
  install_anaconda
  exit 0
fi


# if both option is on respectively, check install first
if [ "$PKG" = "yes" ]; then
  install_packages
fi

if [ "$DOT" = "yes" ]; then
  install_dot
fi

if [ "$FONTS" = "yes" ]; then
  install_fonts
fi

if [ "$ZSH" = "yes" ]; then
  install_zsh
fi

if [ "$Z" = "yes" ]; then
  install_z
fi

if [ "$RTAGS" = "yes" ]; then
  install_rtags
fi

if [ "$CAML" = "yes" ]; then
  install_opam_2.0
  install_opam_packages
fi

if [ "$CONDA" = "yes" ]; then
  install_anaconda
fi
