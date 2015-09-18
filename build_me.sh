#!/bin/bash

#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.

## Let me introduce myself...

echo ">>>>> zeKrnl build script for LG Optimus G Pro E98x"
echo ">>>>> Written and fixed by gromikakao@github (https://github.com/gromikakao/), based oon old script from XDA"
echo ">>>>> Licenced as GPL, so you can share & edit, just don't make it forget who original author is"
echo " "
echo " "

## Configuration part

# For Arch linux users (I don't know if anyone else has this problem)
# Our precious distro uses python3 as default, but for successful Android building we need python2.7
# Since we don't have a function like set-defaults on Ubuntu/Mint, we have to do it the old way.
# Make sure you have instaled everything described here:
# ++++ https://wiki.archlinux.org/index.php/Android#Building_Android
# 
# This version of script will check do you have python27 virtual env, activate if you have it, and install if you don't.
# Only two things this script needs are
# a) proper installation of build-tools, as described on link above
# b) a path where you installed/want to install python27 virtual env.

venv_path="/media/data/py27_venv/"

# Now we need some informations about your toolchain.
# Legend:
# - toolchains_dir -> location where toolchains are located
# - toolchain_name -> name of the directory toolchain is located

toolchains_dir="/media/data/toolchains"
toolchain_name="linaro_a15_484-2014.11"

# Now, name of the configuration file...
defconfig_name="cyanogenmod_e980_defconfig"

# Set number of threads/cores. If you have 4 cores, set it to 4+1=5.
# General rule: n cores => value is n+1. Set it to 1 if you want to watch line by line and hunt for errors
jobs=2

# Name of example boot.img to use for boot.img regeneration
template_bootimg="boot-cm12.1.img"

# Kernel name
KERNEL_NAME=$(sed -n '/DEVEL_NAME/p' Makefile | head -1 | cut -d'=' -f 2)

# Kernel version appendix
KERNEL_VERSION=$(sed -n '/EXTRAVERSION/p' Makefile | head -1 | cut -d'=' -f 2)

# Build timestamp
TIMESTAMP=$(date +"%d%m%Y-%H%M%S")

# Build number prefix
BUILD_NUM_PREFIX="_#"

# And finaly, information about architecture you're building for. 
# OFC, if you're using this for OGPro, you gonna need arm...
device_arch="arm"

## It's fun time! Don't edit this if you really don't have a need for that.

# Variables needed for command line options. 0 = not set, 1=yes, 2=no
# - Create new config
NEW_CONFIG=0
# - Clean up
CLEAN_UP=0
# - Generate boot.img
BOOT_IMG_GEN=0
# - Generate flashable zip
ZIP_GEN=0

# Function to generate boot image and flashable zip
function generate_bootImg {
	# Check if abootimg binary exist
	echo "-> Starting boot.img generation"
	echo " "
	
	echo "+ Checking if abootimg is in PATH.."
	abootimg_pwd=$(which abootimg)
	if [ -e "$abootimg_pwd" ]; then
		echo "++ abootimg found."
	else
		echo "++ abootimg binary not found; aborting"
		exit
	fi
	
	# Check if there is existing, example boot.img to use as template
	echo " "
	echo "+ Checking if template boot.img exists..."
	if [ -e "$PWD/build_tools/template_img/$template_bootimg" ]; then
		echo "++ Template boot.img found, extracting"
		abootimg -x "build_tools/template_img/$template_bootimg"
		mv bootimg.cfg "build_tools/template_img/"
		mv initrd.img "build_tools/template_img/"
		mv zImage "build_tools/template_img/"
		echo " "
		echo "++ Template extracted"
	else
		echo "++ Template boot.img not found, aborting."
		exit
	fi
	
	# Generate new boot.img
	echo "+ Starting generation of new boot.img"
	echo " "
	echo "++ Copying zImage from arch/$ARCH/boot..."
	cp -rvf "arch/$ARCH/boot/zImage" "build_tools/"
	echo "++ Generating boot.img"
	abootimg --create "$PWD/build_tools/boot.img" -f "$PWD/build_tools/template_img/bootimg.cfg" -k "$PWD/build_tools/zImage" -r "$PWD/build_tools/template_img/initrd.img"
	if [ -e "$PWD/build_tools/boot.img"	]; then
		echo "+++ Success, boot.img generated"
	else
		echo "+++ Failure, boot.img not generated"
	fi
	
	# Cleanup
	echo "++ Cleaning up..."
	rm -rvf "build_tools/template_img/bootimg.cfg"
	rm -rvf "build_tools/template_img/initrd.img"
	rm -rvf "build_tools/template_img/zImage"
	
	if [ -e "$PWD/build_tools/boot.img"	]; then
		echo "+ Do you want to generate flashable zip?"
		select ans in "y" "n"; do
			case $ans in
				y )
					generate_flashableZip
					break;;
				n)
					break;;
			esac
		done
	fi
}

function generate_flashableZip {
	# Generate flashable zip if boot image is created
	echo " "
	if [ -e "$PWD/build_tools/boot.img"	]; then
		echo "+ Generating flashable zip"
		# Create tmp directory if doesn't exist
		if [ ! -d "build_tools/tmp" ]; then
			mkdir "build_tools/tmp"
		fi
		
		# Create out directory if it doesn't exist
		if [ ! -d "build_tools/out" ]; then
			mkdir "build_tools/out"
		fi
		
		# Copy needed files to tmp dir
		cp -rvf "build_tools/zip_file/" "build_tools/tmp/zip_file/"
		cp -rvf "build_tools/boot.img" "build_tools/tmp/zip_file/"
		
		# Check if there modules directory tmp zip_file
		if [ -d "build_tools/tmp/zip_file/system/lib/modules" ]; then
			mkdir -p "build_tools/tmp/zip_file/system/lib/modules"
		fi
		
		# Copy modules
		echo "++ Copying modules"
		cp -rvf "drivers/crypto/msm/qce40.ko" "build_tools/tmp/zip_file/system/lib/modules"
		cp -rvf "drivers/crypto/msm/qcedev.ko" "build_tools/tmp/zip_file/system/lib/modules"
		cp -rvf "drivers/crypto/msm/qcrypto.ko" "build_tools/tmp/zip_file/system/lib/modules"
		cp -rvf "drivers/scsi/scsi_wait_scan.ko" "build_tools/tmp/zip_file/system/lib/modules"
		
		echo " "
		
		# Generate updater-script and copy
		echo "++ Generating updater-script"
		# TODO updater-script generation
		cp -rvf "build_tools/updater-script" "build_tools/tmp/zip_file/META-INF/com/google/android/"
		echo " "
		
		# Generate ZIP
		work_dir=$PWD
		echo "++ Changing working dir to tmp/zip_file"
		cd "build_tools/tmp/zip_file/"
		echo "++ Creating zip file..."
		zip flashable.zip -r .
		echo "++ Returning back to work dir"
		cd $work_dir
		
		# Copy zip file to build_tools/out
		echo "++ Copying flashable zip from tmp to build_tools/out"
		cp -rvf "$PWD/build_tools/tmp/zip_file/flashable.zip" "$PWD/build_tools/out/flashable.zip"
		
		# Get build num
		build_num=$(cat .build_no)
		BUILD_NUM="$BUILD_NUM_PREFIX$build_num"
		
		
		# Renaming zip file
		ZIP_FILE_NAME="$KERNEL_NAME$KERNEL_VERSION-$TIMESTAMP$BUILD_NUM.zip"
		ZIP_FILE_NAME_SIGNED="$KERNEL_NAME$KERNEL_VERSION-$TIMESTAMP$BUILD_NUM-SIGNED.zip"
		echo "++ Renaming zip file to $ZIP_FILE_NAME"
		mv "$PWD/build_tools/out/flashable.zip" "$PWD/build_tools/out/$ZIP_FILE_NAME"
		echo " "
		
		# Sign zip file
		echo "++ Signing zip file"
		java -jar "build_tools/tools/SignApk/signapk.jar" "build_tools/tools/SignApk/testkey.x509.pem" "build_tools/tools/SignApk/testkey.pk8" "build_tools/out/$ZIP_FILE_NAME" "build_tools/out/$ZIP_FILE_NAME_SIGNED"
		echo "++ Done."	
		
		# Generate MD5 sums for zips
		echo " "
		echo "++ Generating MD5 sums for zip files..."
		cur_dir="$PWD"
		cd "$PWD/build_tools/out/"
		md5sum_nosign=$(md5sum $ZIP_FILE_NAME)
		md5sum_sign=$(md5sum $ZIP_FILE_NAME_SIGNED)
		cd "$cur_dir"
		echo "++ $md5sum_nosign"
		echo "++ $md5sum_sign"
		echo $md5sum_nosign >> "$PWD/build_tools/out/$ZIP_FILE_NAME.md5sum"
		echo $md5sum_sign >> "$PWD/build_tools/out/$ZIP_FILE_NAME_SIGNED.md5sum"
	
		
		# Cleanup
		echo " "
		echo "++ Removing tmp directory"
		rm -rvf "build_tools/tmp"
		
		# Inform
		echo " "
		echo "++ Your flashable zip can be found in $PWD/build_tools/out"
		echo "++ Unsigned flashable zip: $ZIP_FILE_NAME"
		echo "++ Signed flashable zip: $ZIP_FILE_NAME_SIGNED"

	fi
}


## Function to start build in trivia mode
function start_build {
	mess=0
	
	echo "-> Starting build of $KERNEL_NAME$KERNEL_VERSION"
	echo " "
	
	# Let's check does defconfig file exist
	echo "+ Checking if $defconfig_name exists in $PWD/arch/$ARCH/configs/"
	if [ ! -e "$PWD/arch/$ARCH/configs/$defconfig_name" ]; then
		echo "++ ERROR: defconfig doesn't exist. Check the filename and file presence and try again"
		exit
	fi
	
	echo " "
	# Let's check if make defconfig was already run
	echo "+ Checking for existing configuration..."
	if [ ! -e "$PWD/.config" ]; then
		echo "++ Kernel configuration not found. Creating new..."
		make $defconfig_name;
		if [ -e ".build_no" ]; then
			rm -rvf ".build_no"
			echo "1" >> ".build_no"
		else
			echo "1" >> ".build_no"
		fi		
		
		# Check if configuration is actually made
		if [ -e "$PWD/.config" ]; then
			echo " "
			echo "+++ New configuration created, cleaning mess..."
			echo " "
			make clean
		else
			echo " "
			echo "+++ ERROR: make defconfig never finished, aborting..."
			exit
		fi
	else
		echo "++ Kernel configuration found. Do you want to reuse it or write new?"
		select ans in "New" "Reuse"; do
			case $ans in
				New )
					echo " "
					echo "+++ Clean up..."
					make mrproper
					echo " "
					echo "+++ Writing new .config file...";
					make $defconfig_name;
					
					# Set build_num variable
					if [ -e ".build_no" ]; then
						rm -rvf ".build_no"
						echo "1" >> ".build_no"
					else
						echo "1" >> ".build_no"
					fi	
					
					# Check if configuration is actually made
					if [ -f "$PWD/.config" ]; then
						echo "++++ New configuration created"
					else
						echo "++++ ERROR: make defconfig never finished, aborting..."
						exit
					fi
					break;;
				Reuse )
					echo "+++ Configuration will be reused"
					echo " "
					mess=1
					
					# Set build_num variable
					if [ -e ".build_no" ]; then
						old_build_num=`cat .build_no`
						new_build_num=$((old_build_num+1))
						rm -r ".build_no"
						echo "$new_build_num" >> ".build_no"
					else
						echo "1" >> ".build_no"
					fi	
					
					break;;
			esac
		done
	fi
	
	if [ $mess == 1 ]; then
		echo "+ Your build folder is 'dirty', do you want to clean it?"
		select ans in "y" "n"; do
			case $ans in
				y )
					echo "++ Cleaning build dir..."
					echo " "
					make clean
					$(mess=0)
					break;;
				n ) 
					break;;
			esac
		done
	fi
	
	echo " "		
	# Check for any last minute changes
	echo "+ Everything looks steady and ready. Do you want to make some final changes to the config?"
	select yn in "y" "n"; do
		case $yn in
			y ) 
				echo "++ Running make menuconfig. Don't forget to save!";
				echo " ";
				make menuconfig;
				break;;
			n ) 
				echo "++ Ok, ready to continue."
				echo " "
				break;;
		esac
	done
	echo "+ Press any key to start."
	read blah
	echo " "
	echo "++ Starting build #$(cat .build_no)"
	echo " "				
	time make -j$jobs;
	
	# Check if build was a success and if yes, ask user for boot.img generation
	if [ -e "$PWD/arch/$ARCH/boot/zImage" ]; then
		echo " "
		echo "+ Build successful. Do you want to generate boot img?"
		select bla in "y" "n"; do
			case $bla in
				y ) 
					generate_bootImg
					echo " "
					echo "+++++++++++++++ FINISHED +++++++++++++++++"
					break;;
				n )
					echo "+++++++++++++++ FINISHED +++++++++++++++++"
					exit;;
			esac
		done
	else
		echo " "
		echo "+ Build failed; check output for errors and try again after fixing them"
		exit
	fi
}

## Function to start build with parameters given on command-line
function start_build_cmd {
	echo "-> Starting build of $KERNEL_NAME$KERNEL_VERSION"
	echo " "
	
	# Let's check does defconfig file exist
	echo "+ Checking if $defconfig_name exists in $PWD/arch/$ARCH/configs/"
	if [ ! -e "$PWD/arch/$ARCH/configs/$defconfig_name" ]; then
		echo "++ ERROR: defconfig doesn't exist. Check the filename and file presence and try again"
		exit
	fi
	
	echo " "
	
	##### CHECK CONFIG BLOCK #####
	
	# First, let's check if user wants new configuration or to recreate
	if [[ $NEW_CONFIG==1 ]]; then
		echo "++ Removing any old configs, cleaning up and making new config"
		# Check if old config is there, delete it and run mrproper
		if [ -e "$PWD/.config" ]; then 
			rm -rvf "$PWD/.config";
			make mrproper
		fi
		
		make $defconfig_name
		
		if [ -e ".build_no" ]; then
			rm -rvf ".build_no"
		fi
		echo "1" >> ".build_no"
		
		# Check if configuration is actually made
		if [ -e "$PWD/.config" ]; then
			echo " "
			echo "+++ New configuration created!"
			echo " "
		else
			echo " "
			echo "+++ ERROR: make defconfig never finished, aborting..."
			exit
		fi	
	elif [[ $NEW_CONFIG==2 ]]; then
		# Let's make sure user isn't a complete idiot...
		echo "++ Checking if config exists..."
		if [ ! -e "$PWD/.config" ]; then
			echo "+++ Config doesn't exist, creating!"
			make $defconfig_name
		else
			echo "+++ Config found, resuming normal operation"
			if [ -e ".build_no" ]; then
				old_build_num=`cat .build_no`
				new_build_num=$((old_build_num+1))
				rm -r ".build_no"
				echo "$new_build_num" >> ".build_no"
			else
				echo "1" >> ".build_no"
			fi	
		fi
	else
		# User was a lazy ass and didn't specify a valid value for config state,
		# so we're gonna assume that he wants new config
		echo "++ Creating new config and cleaning up since there was no input about this one..."
		make mrproper
		make $defconfig_name
		# Check if configuration is actually made
		if [ -e "$PWD/.config" ]; then
			echo " "
			echo "+++ New configuration created!"
			echo " "
		else
			echo " "
			echo "+++ ERROR: make defconfig never finished, aborting..."
			exit
		fi	
	fi
	
	##### CHECK CLEAN BLOCK #####
	is_dirty=$(find . name "*.o" | wc -l)
	if [[ $CLEAN_UP==1 ]]; then
		echo "++ Checking if there is something to clean..."
		if [[ $is_dirty>0 ]]; then
			echo "+++ Output is dirty, running make clean"
			make clean
		else
			echo "+++ Output is not dirty, resuming..."
		fi
	elif [[ $CLEAN_UP==2 ]]; then
		echo "++ Using dirty output... beware, Dragons passing by."
	else 
		echo "++ Wrong value for needed parameter, assuming 'keep dirty'"
	fi
	
	
	##### RUN THE BUILD #####
	echo "+ All set. Starting build"
	echo " "
	echo "++ Starting build #$(cat .build_no)"
	echo " "				
	time make -j$jobs;
	
	# Check if build was a success and if yes, ask user for boot.img generation
	if [ -e "$PWD/arch/$ARCH/boot/zImage" ]; then
		echo " "
		echo "+ Build successful."
	else
		echo " "
		echo "+ Build failed; check output for errors and try again after fixing them"
		exit
	fi
	
	##### CREATE BOOT.IMG #####
	echo " "
	if [[ $BOOT_IMG_GEN==1 ]]; then
		generate_bootImg
	else 
		# Check if there is an old boot.img, and remove it.
		if [ -e "$PWD/build_tools/boot.img" ]; then
			echo "+ Removing boot.img from previous build"
			rm -rvf "$PWD/build_tools/boot.img"
		fi
	fi
	
	##### CREATE FLASHABLE ZIP #####
	if [[ $ZIP_GEN==1 ]]; then
		if [[ $BOOT_IMG_GEN==2 ]]; then
			echo "+ You have selected to create a new flashable zip, but you don't want to create new boot.img... Sum-ting-wrong"
			echo "++ Generating new boot.img for you..."
			generate_bootImg
		fi
		generate_flashableZip
	fi
	
	echo "+++++ DONE +++++"
	
}

## Function to check does python venv exist
function createVenv {
	pyvenv --system-site-packages --copies "$venv_path"
}

## Print help message if some of script parameters are bad
function print_error_msg {
	echo "/*********************** HELP! ***************************/"
	echo "To use turn-table mode, don't pass any arguments."
	echo " "
	echo "To automate scrirpt's work, pass needed arguments:"
	echo "\t -c # || --clean # -> Clean up before building"
	echo "\t -g # || --generate # -> Reuse old config or generate new"
	echo "\t -i # || --img # -> Generate boot.img"
	echo "\t -z # || --zip # -> Generate flashable zip"
	echo "# is a numeric value; 1 for yes, 2 for no"
	echo "If some of variables aren't defined, script will let it's"
	echo "own free will decide..."
	echo "/********************* END HELP! *************************/"
}

########## FUNTIME ###############

## Check if you're running Arch
echo "-> Checking if running on Arch Linux..."

distro=`cat /etc/os-release | grep ID |  cut -d'=' -f 2`

if [ "$distro" == "arch" ]; then
	echo "+ Running on Arch Linux"
	if [ -d "$venv_path" ]; then
		echo "++ python27 virtual env. installed in $venv_path, activating"
		source "$venv_path/bin/activate"
	else
		echo "++ python27 virtual env. not found, checking if installer is present..."
		pyvenv_path=$(which pyvenv)
		if [ -e "$pyvenv_path" ]; then
			echo "+++ pyvenv available, installing..."
			createVenv
		else
			echo "+++ pyvenv binary not found, aborting..."
			exit
		fi
	fi
fi

echo " "

### Check for toolchains
echo "-> Checking if toolchain is installed..."

toolchain_path="$toolchains_dir/$toolchain_name/bin/arm-cortex_a15-linux-gnueabihf-"
if [ -d "$toolchains_dir/$toolchain_name/bin/" ]; then
	echo "+ Toolchain path set to $toolchain_path"
else
	echo "+ Toolchain not found on $toolchain_path, aborting..."
	exit
fi

### We're alive, let's create needed variables
echo " "
echo "-> Setting variables:"
export CROSS_COMPILE=$toolchain_path
echo "+ CROSS_COMPILE=$CROSS_COMPILE"
export ARCH=$device_arch
echo "+ ARCH=$ARCH"
echo "+ building config $defconfig_name"
echo "+ Using $jobs threads"

echo " "

if [[ $# == 1 ]]; then
	case $key in
		*)
			print_error_msg;
			break;;
	esac
elif [[ $# > 1 ]]; then
	while [[ $# > 1 ]]; do
		key="$1"
		case $key in
			-c|--clean)
			CLEAN_UP="$2"
			shift # past argument
			;;
			-g|--generate)
			NEW_CONFIG="$2"
			shift # past argument
			;;
			-i|--img)
			BOOT_IMG_GEN="$2"
			shift # past argument
			;;
			-i|--img)
			BOOT_IMG_GEN="$2"
			shift # past argument
			;;
			*)
				print_error_msg
				# unknown option
			;;
		esac
		shift # past argument or value
	done
	start_build_cmd;
else
	start_build;
fi
