#!/bin/bash

# Function to check if a package is installed
check_and_install() {
    PACKAGE=$1
    if ! dpkg -s $PACKAGE >/dev/null 2>&1; then
        echo "Installing $PACKAGE..."
        sudo apt-get install -y $PACKAGE
    else
        echo "$PACKAGE is already installed."
    fi
}

# Check if the user passed a directory argument
if [ -z "$1" ]; then
    echo "Usage: $0 <image_directory>"
    exit 1
fi

IMAGE_DIR=$1

# Check if the directory exists
if [ ! -d "$IMAGE_DIR" ]; then
    echo "Directory $IMAGE_DIR does not exist."
    exit 1
fi

# Check and install Python, Tkinter, and pip
check_and_install python3
check_and_install python3-tk

# Check if pip3 is installed
if ! command -v pip3 &>/dev/null; then
    echo "Installing pip3..."
    sudo apt-get install -y python3-pip
else
    echo "pip3 is already installed."
fi

# Check if Pillow is installed, install if not
if ! python3 -c "import PIL" &>/dev/null; then
    echo "Installing Pillow..."
    pip3 install pillow
else
    echo "Pillow is already installed."
fi

# Create a Python script for the image viewer
cat <<EOF >image_viewer.py
import os
import sys
from tkinter import Tk, Label, Button
from PIL import Image, ImageTk

def get_image_width(image_path):
    with Image.open(image_path) as img:
        return img.width

def load_images(directory):
    image_files = [f for f in os.listdir(directory) if f.endswith(('.png', '.jpg', '.jpeg'))]
    image_files.sort(key=lambda f: get_image_width(os.path.join(directory, f)))
    return image_files

def show_image(image_path):
    image = Image.open(image_path)
    photo = ImageTk.PhotoImage(image)
    label.config(image=photo)
    label.image = photo  # Keep reference to avoid garbage collection
    window.title(f"Viewing: {os.path.basename(image_path)}")

def next_image(event=None):
    global current_image_index
    if current_image_index < len(images) - 1:
        current_image_index += 1
        show_image(os.path.join(image_dir, images[current_image_index]))

def previous_image(event=None):
    global current_image_index
    if current_image_index > 0:
        current_image_index -= 1
        show_image(os.path.join(image_dir, images[current_image_index]))

if len(sys.argv) < 2:
    print("Usage: python3 image_viewer.py <image_directory>")
    sys.exit(1)

image_dir = sys.argv[1]

window = Tk()
window.title("Image Viewer")

# Bind left and right arrow keys to navigation
window.bind('<Left>', previous_image)
window.bind('<Right>', next_image)

images = load_images(image_dir)
current_image_index = 0

label = Label(window)
label.pack()

prev_button = Button(window, text="Previous", command=previous_image)
prev_button.pack(side="left")

next_button = Button(window, text="Next", command=next_image)
next_button.pack(side="right")

if images:
    show_image(os.path.join(image_dir, images[current_image_index]))

window.mainloop()
EOF

# Run the Python image viewer with the provided image directory
python3 image_viewer.py "$IMAGE_DIR"

