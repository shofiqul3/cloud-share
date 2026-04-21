# Termux File Share Server Setup Guide

## 📋 Overview
A modern, lightweight file sharing server for Termux with a clean web interface. Supports files up to 10GB with drag-and-drop functionality, QR code sharing, and direct downloads.

## ✨ Features
- **Web Interface**: Modern UI with drag-and-drop support
- **Large Files**: Supports uploads up to 10GB
- **QR Codes**: Generate QR codes for easy file sharing
- **Mobile Friendly**: Responsive design for all devices
- **Password Protection**: Optional authentication
- **Clipboard Sharing**: Text sharing functionality

## 🚀 Quick Installation

### Method 1: One-line Install (Recommended)
```bash
pkg update -y && pkg upgrade -y && pkg install -y git && git clone https://github.com/shofiqul3/cloud-share && cd cloud-share && chmod +x setup.sh && bash setup.sh
