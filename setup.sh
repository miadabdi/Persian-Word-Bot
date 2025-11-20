#!/bin/bash

# Configuration
SERVICE_NAME="persianbot"
DESCRIPTION="Persian Word of the Day Bot"
SCRIPT_NAME="persian_word_bot.py"

# Get the real user (if running as sudo, get the original user)
if [ $SUDO_USER ]; then
    REAL_USER=$SUDO_USER
else
    REAL_USER=$(whoami)
fi

# Get the current directory
PROJECT_DIR=$(pwd)
VENV_DIR="$PROJECT_DIR/venv"
VENV_PYTHON="$VENV_DIR/bin/python"
VENV_PIP="$VENV_DIR/bin/pip"
SCRIPT_PATH="$PROJECT_DIR/$SCRIPT_NAME"

echo "🔧 Starting setup for user: $REAL_USER"

# 1. Check for Python Script
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Error: Could not find $SCRIPT_NAME in $PROJECT_DIR"
    exit 1
fi

# 2. Check/Create Virtual Environment
if [ ! -d "$VENV_DIR" ]; then
    echo "⚠️  Virtual environment not found. Creating one..."
    
    # We run this command as the REAL_USER so the folder isn't owned by root
    if sudo -u "$REAL_USER" python3 -m venv "$VENV_DIR"; then
        echo "✅ Virtual environment created."
    else
        echo "❌ Error creating venv. Make sure python3-venv is installed (sudo apt install python3-venv)."
        exit 1
    fi
else
    echo "✅ Virtual environment found."
fi

# 3. Install Dependencies
echo "📦 Installing dependencies..."
# We install specific packages directly to ensure they exist
if sudo -u "$REAL_USER" "$VENV_PIP" install python-telegram-bot schedule mnk-persian-words; then
    echo "✅ Dependencies installed."
else
    echo "❌ Error installing dependencies."
    exit 1
fi

# 4. Create the .service file content
echo "📝 Generating systemd service file..."
SERVICE_CONTENT="[Unit]
Description=$DESCRIPTION
After=network.target

[Service]
User=$REAL_USER
WorkingDirectory=$PROJECT_DIR
ExecStart=$VENV_PYTHON $SCRIPT_PATH
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target"

# 5. Write the file to /etc/systemd/system/
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

# Use bash -c to handle the redirection with sudo permissions
bash -c "echo \"$SERVICE_CONTENT\" > $SERVICE_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Service file created at $SERVICE_FILE"
else
    echo "❌ Error writing service file. Are you running with sudo?"
    exit 1
fi

# 6. Enable and Start the service
echo "⚙️  Reloading Systemd and starting service..."
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl restart $SERVICE_NAME

# 7. Show status
echo "📊 Checking status..."
systemctl status $SERVICE_NAME --no-pager

echo ""
echo "🎉 Setup Complete! Your bot is running."
echo "   View logs with: sudo journalctl -u $SERVICE_NAME -f"