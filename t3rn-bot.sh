#!/bin/bash

# Skrip Auto Bridge untuk t3rn

# Definisi variabel
SCRIPT_PATH="$HOME/bot.sh"
REPO_URL="https://github.com/cxqsb/t3rn-bot.git"
DIR_NAME="t3rn-bot"
PYTHON_FILE="keys_and_addresses.py"
DATA_BRIDGE_FILE="data_bridge.py"
BOT_FILE="bot.py"
VENV_DIR="t3rn-env"

# Fungsi untuk menampilkan menu utama
function main_menu() {
    while true; do
        clear
        echo "=============================================="
        echo "        Auto Bridge Bot untuk t3rn"
        echo "=============================================="
        echo "1. Jalankan bot"
        echo "2. Keluar"
        read -p "Pilih opsi (1/2): " option
        case $option in
            1) execute_bot ;;
            2) echo "Keluar."; exit 0 ;;
            *) echo "Pilihan tidak valid."; sleep 2 ;;
        esac
    done
}

# Fungsi untuk menjalankan bot
function execute_bot() {
    if ! command -v git &> /dev/null; then
        echo "Git tidak ditemukan, menginstal..."
        sudo apt update && sudo apt install -y git
    fi

    if ! command -v python3 &> /dev/null; then
        echo "Python3 tidak ditemukan, menginstal..."
        sudo apt update && sudo apt install -y python3 python3-pip python3-venv
    fi

    if [ -d "$DIR_NAME" ]; then
        cd "$DIR_NAME" && git pull origin main
    else
        git clone "$REPO_URL" && cd "$DIR_NAME"
    fi

    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip
    pip install web3 colorama

    read -p "Masukkan private key (pisahkan dengan spasi jika lebih dari satu): " private_keys_input
    read -p "Masukkan label untuk setiap private key (pisahkan dengan spasi): " labels_input

    IFS=' ' read -r -a private_keys <<< "$private_keys_input"
    IFS=' ' read -r -a labels <<< "$labels_input"

    if [ "${#private_keys[@]}" -ne "${#labels[@]}" ]; then
        echo "Jumlah private key dan label tidak sesuai!"
        exit 1
    fi

    echo "Menulis file $PYTHON_FILE..."
    cat > $PYTHON_FILE <<EOL
private_keys = [
$(printf "    '%s',\n" "${private_keys[@]}")
]

labels = [
$(printf "    '%s',\n" "${labels[@]}")
]
EOL

    read -p "Masukkan nilai 'Base - OP Sepolia': " base_op_sepolia_value
    read -p "Masukkan nilai 'OP - Base': " op_base_value

    echo "Menulis file $DATA_BRIDGE_FILE..."
    cat > $DATA_BRIDGE_FILE <<EOL
data_bridge = {
    "Base - OP Sepolia": "$base_op_sepolia_value",
    "OP - Base": "$op_base_value"
}
EOL

    echo "Menjalankan bot di background..."
    screen -dmS t3rn python3 $BOT_FILE
    echo "Bot berjalan! Gunakan 'screen -r t3rn' untuk melihat log."
    read -n 1 -s -r -p "Tekan tombol apapun untuk kembali ke menu utama..."
}

# Menjalankan menu utama
main_menu
