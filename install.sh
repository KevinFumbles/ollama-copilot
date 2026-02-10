#/bin/bash

go build
mkdir -p $HOME/.local/bin

# Stop service if exists to avoid "Text file busy"
if systemctl --user is-active --quiet ollama-copilot.service; then
  echo "Stopping ollama-copilot service..."
  systemctl --user stop ollama-copilot.service
fi

cp ollama-copilot $HOME/.local/bin/ollama-copilot

echo "Install in systemd? [y/N]"
read INSTALL_SYSTEMD
if [[ $INSTALL_SYSTEMD == "y" ]]
then
  echo "Number of tokens to predict? [default: 25]"
  read NUM_PREDICT
  if [[ -z $NUM_PREDICT ]]
  then
    NUM_PREDICT=25
  fi

  echo "instalando systemctl"
  mkdir -p $HOME/.config/systemd/user/
  cp ollama-copilot.service $HOME/.config/systemd/user/ollama-copilot.service
  sed -i "s|ExecStart=.*|ExecStart=$HOME/.local/bin/ollama-copilot -num-predict $NUM_PREDICT|g" $HOME/.config/systemd/user/ollama-copilot.service
  systemctl --user daemon-reload
  systemctl --user enable ollama-copilot.service
  systemctl --user start ollama-copilot.service
fi

if [ -d "$HOME/.config/nvim" ] || command -v nvim &> /dev/null
then
  echo "Neovim detected. Install configuration? [y/N]"
  read INSTALL_NVIM
  if [[ $INSTALL_NVIM == "y" ]]
  then
    echo "Configuring Neovim..."
    NVIM_CONFIG_DIR="$HOME/.config/nvim"
    mkdir -p "$NVIM_CONFIG_DIR"
    if [ -f "$NVIM_CONFIG_DIR/init.lua" ]; then
      echo 'vim.g.copilot_proxy = "http://localhost:11435"' >> "$NVIM_CONFIG_DIR/init.lua"
      echo 'vim.g.copilot_proxy_strict_ssl = false' >> "$NVIM_CONFIG_DIR/init.lua"
    else
      echo 'let g:copilot_proxy = "http://localhost:11435"' >> "$NVIM_CONFIG_DIR/init.vim"
      echo 'let g:copilot_proxy_strict_ssl = v:false' >> "$NVIM_CONFIG_DIR/init.vim"
    fi
  fi
fi

if [ -d "$HOME/.config/Code" ] || command -v code &> /dev/null
then
  echo "VSCode detected. Install configuration? [y/N]"
  read INSTALL_VSCODE
  if [[ $INSTALL_VSCODE == "y" ]]
  then
    VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"
    if [ -f "$VSCODE_SETTINGS" ]; then
      echo "Configuring VSCode..."
      python3 -c "
import json, os
path = os.path.expanduser('$VSCODE_SETTINGS')
try:
    with open(path, 'r') as f:
        data = json.load(f)
except Exception:
    data = {}
data['github.copilot.advanced'] = data.get('github.copilot.advanced', {})
data['github.copilot.advanced']['debug.overrideProxyUrl'] = 'http://localhost:11437'
data['http.proxy'] = 'http://localhost:11435'
data['http.proxyStrictSSL'] = False
with open(path, 'w') as f:
    json.dump(data, f, indent=4)
"
    else
      echo "VSCode settings.json not found at $VSCODE_SETTINGS"
    fi
  fi
fi

if [ -d "$HOME/.config/zed" ] || command -v zed &> /dev/null || command -v zed-editor &> /dev/null
then
  echo "Zed detected. Install configuration? [y/N]"
  read INSTALL_ZED
  if [[ $INSTALL_ZED == "y" ]]
  then
    ZED_SETTINGS="$HOME/.config/zed/settings.json"
    if [ -f "$ZED_SETTINGS" ]; then
      echo "Configuring Zed..."
      python3 -c "
import json, os
path = os.path.expanduser('$ZED_SETTINGS')
try:
    with open(path, 'r') as f:
        data = json.load(f)
except Exception:
    data = {}
data.setdefault('features', {})['edit_prediction_provider'] = 'copilot'
data['show_completions_on_input'] = True
data.setdefault('edit_predictions', {})['copilot'] = {
    'proxy': 'http://localhost:11435',
    'proxy_no_verify': True
}
with open(path, 'w') as f:
    json.dump(data, f, indent=4)
"
    else
      echo "Zed settings.json not found at $ZED_SETTINGS"
    fi
  fi
fi

