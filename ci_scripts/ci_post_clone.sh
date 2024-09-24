#!/bin/sh
brew install cocoapods
echo "Cocoapods安装完毕"
echo "开始设置Cocoapods"
pod setup
echo "Cocoapods设置完毕"
echo "开始安装Pods依赖库"
pod install
echo "Pods依赖库安装完毕"
