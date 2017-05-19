#!/bin/bash

invalid=0
restoredir=
usbdev=
array=
updateurl="https://raw.githubusercontent.com/gitislife/pi/master/pi_3_arcade.sh"
prompt(){
	printf "\033[0;31mpi_3_arcade script written by LWX, this script comes with ABSOLUTELY NO WARRANTY!\033[0m\n"
	printf "\033[0;32mVersion 1.0\n\n\033[0m"
	echo "What do you want to do?"
		echo "1. Clone/Flash image file onto sd card"
		echo "2. Backup sd card into image file"
		echo "3. Check for updates"
		read choice
}
read_dir(){
	count=0
		for i in *
			do
				(( count++ ))
					array[$count]=$i
					done
					echo "Select backup/restore directory: "
					for ((i=1; i<=$count; i++))
						do
							echo $i.${array[$i]}
						done
							read dirnum
							restoredir=${array[$dirnum]}
}
read_dev(){
	echo "Enter sd card device, either sdb or mmc* usually"
		ls /dev/sd*
		read sd_var
		usbdev="/dev/$sd_var"
}
eval(){
	case $choice in
		1)
		echo "You chose to flash image file onto sd card!"
		echo "Press Enter to continue.."
		read p
		invalid=0
		read_dir
		read_dev
		restore -i $restoredir -o $usbdev
		;;
	2)
		echo "You chose to backup sd card into an image file!"
		echo "Press Enter to continue.."
		read p
		invalid=0
		read_dir
		read_dev
		backup -i $usbdev -o ./$restoredir
		;;
	3)
		echo "Checking for updates..."
		wget -N -q $updateurl
		[ $? -eq 0 ] && (
				clear
				echo "Updated successfully!"
				echo "Re-run script to start again!"
				)
		;;
	*)
		invalid=1
		;;
	esac
}
restore(){
	COL_HIGHLIGHT="\033[0;33m"
		COL_RESET="\033[0m"
		AUTOMATIC=0
		INDIR="<none>"
		OUTFILE="<none>"
		command -v partclone.restore >/dev/null || { echo -e "\n*** Error: partclone.restore not available\n"; exit 23; }
	while getopts ":i:ao:" optname; do
	case "$optname" in
		"i")
			INDIR=$OPTARG
			;;
		"o")
			OUTFILE=$OPTARG
			;;
		"a")
			AUTOMATIC=1
			;;
		"?")
			echo -e "\n*** Error: unknown option -$OPTARG\n"
			exit 1
			;;
		":")
			echo -e "\n*** Error: missing argument for option -$OPTARG\n"
			exit 2
			;;
		*)
			echo -e "\n*** Error: cannot process options\n"
			exit 99
			;;
		esac
			done
			if [[ $INDIR == "<none>" ]]; then
				echo -e "\n*** Error: no -i option specified\n"
					exit 3
					fi
					if [[ $OUTFILE == "<none>" ]]; then
						echo -e "\n*** Error: no -o option specified\n"
							exit 4
							fi
							if [[ ! -d $INDIR ]]; then
								echo -e "\n*** Error: directory $INDIR doesn't exist, specify a different path\n"
									exit 5
									fi
									if [[ ! -b $OUTFILE ]]; then
										echo -e "\n*** Error: $OUTFILE is not a valid block device\n"
											exit 6
											fi
											if [[ ! -f $INDIR/mbr.img ]]; then
												echo -e "\n*** Error: cannot find MBR image\n"
													exit 7
													fi
													if   [[ -f $INDIR/boot.img ]]; then
														INEXT="img"
															COMPRESSION=0
															COMPR_DESCR="uncompressed"
															elif [[ -f $INDIR/boot.img.bz2 ]]; then
															INEXT="img.bz2"
															COMPRESSION=1
															COMPR_DESCR="compressed"
													else
														echo -e "\n*** Error: cannot find boot image\n"
															exit 8
															fi
															if [[ ! -f $INDIR/system.$INEXT ]]; then
																echo -e "\n*** Error: cannot find system image\n"
																	exit 9
																	fi
																	echo -ne "\n${COL_HIGHLIGHT}Ready to perform restore of RPi sd card $OUTFILE from $COMPR_DESCR image in ${INDIR}${COL_RESET}\n"
																	if [[ $AUTOMATIC == 0 ]]; then
																		echo
																			read -p "Do you want to continue? (y/n) "
																			if [[ ! $REPLY =~ [yY] ]]; then
																				echo -e "\n*** Aborting\n"
																					exit 98
																					fi
																					fi
																					echo -e "\n${COL_HIGHLIGHT}Unmounting $OUTFILE...${COL_RESET}\n"
																					umount ${OUTFILE}?
																					echo -e "\n${COL_HIGHLIGHT}Restoring MBR...${COL_RESET}\n"
																					dd bs=512 count=1 of=$OUTFILE if=$INDIR/mbr.img
																					sync
																					partprobe $OUTFILE
																					echo -e "\n${COL_HIGHLIGHT}Restoring boot partition...${COL_RESET}\n"
																					if [[ $COMPRESSION == 1 ]]; then
																						bunzip2 -c $INDIR/boot.$INEXT | partclone.restore --source - --output ${OUTFILE}1
																					else
																						partclone.restore --output ${OUTFILE}1 --source $INDIR/boot.$INEXT
																							fi
																							echo -e "\n${COL_HIGHLIGHT}Restoring system partition...${COL_RESET}\n"
																							if [[ $COMPRESSION == 1 ]]; then
																								bunzip2 -c $INDIR/system.$INEXT | partclone.restore --source - --output ${OUTFILE}2
																							else
																								partclone.restore --output ${OUTFILE}2 --source $INDIR/system.$INEXT
																									fi
																									echo -e "\n${COL_HIGHLIGHT}Setting up swap partition...${COL_RESET}\n"
																									mkswap ${OUTFILE}3
																									sync
																									echo -e "\n${COL_HIGHLIGHT}Everything is Ok.${COL_RESET}\n"
}
backup(){
	COL_HIGHLIGHT="\033[0;33m"
		COL_RESET="\033[0m"
		COMPRESSION=0
		AUTOMATIC=0
		INFILE="<none>"
		OUTDIR="<none>"
		command -v partclone.fat     >/dev/null || { echo -e "\n*** Error: partclone.fat not available\n"; exit 21; }
	command -v partclone.extfs   >/dev/null || { echo -e "\n*** Error: partclone.extfs not available\n"; exit 22; }
	while getopts ":ci:ao:" optname; do
	case "$optname" in
		"c")
			COMPRESSION=1
			;;
		"i")
			INFILE=$OPTARG
			;;
		"o")
			OUTDIR=$OPTARG
			;;
		"a")
			AUTOMATIC=1
			;;
		"?")
			echo -e "\n*** Error: unknown option -$OPTARG\n"
			exit 1
			;;
		":")
			echo -e "\n*** Error: missing argument for option -$OPTARG\n"
			exit 2
			;;
		*)
			echo -e "\n*** Error: cannot process options\n"
			exit 99
			;;
		esac
			done
			if [[ $INFILE == "<none>" ]]; then
				echo -e "\n*** Error: no -i option specified\n"
					exit 3
					fi
					if [[ $OUTDIR == "<none>" ]]; then
						echo -e "\n*** Error: no -o option specified\n"
							exit 4
							fi
							if [[ ! -e $OUTDIR ]]; then
								echo -e "\n*** Error: $OUTDIR Does not exist!\n"
									exit 5
									fi
									if [[ ! -b $INFILE ]]; then
										echo -e "\n*** Error: $INFILE is not a valid block device\n"
											exit 6
											fi
											echo -ne "\n${COL_HIGHLIGHT}Ready to perform backup of RPi sd card $INFILE to folder $OUTDIR"
											if [[ $COMPRESSION == 0 ]]; then
												echo -e " without compression${COL_RESET}"
													OUTEXT="img"
											else
												echo -e " with compression${COL_RESET}"
													OUTEXT="img.bz2"
													fi
													if [[ $AUTOMATIC == 0 ]]; then
														echo
															read -p "Do you want to continue? (y/n) "
															if [[ ! $REPLY =~ [yY] ]]; then
																echo -e "\n*** Aborting\n"
																	exit 98
																	fi
																	fi
																	echo -e "\n${COL_HIGHLIGHT}Creating $OUTDIR directory${COL_RESET}"
																	mkdir --parents $OUTDIR
																	if [[ ! -d $OUTDIR ]]; then
																		echo -e "\n*** Error: cannot create $OUTDIR directory\n"
																			exit 7
																			fi
																			echo -e "\n${COL_HIGHLIGHT}Unmounting $INFILE...${COL_RESET}\n"
																			umount ${INFILE}?
																			echo -e "\n${COL_HIGHLIGHT}Backing up MBR...${COL_RESET}\n"
																			dd bs=512 count=1 if=$INFILE of=$OUTDIR/mbr.img
																			sync
																			echo -e "\n${COL_HIGHLIGHT}Backing up boot partition...${COL_RESET}\n"
																			if [[ $COMPRESSION == 1 ]]; then
																				partclone.fat   --clone --source ${INFILE}1 --output - | bzip2 -9 > $OUTDIR/boot.$OUTEXT
																			else
																				partclone.fat   --clone --source ${INFILE}1 --output $OUTDIR/boot.$OUTEXT
																					fi
																					echo -e "\n${COL_HIGHLIGHT}Backing up system partition...${COL_RESET}\n"
																					if [[ $COMPRESSION == 1 ]]; then
																						partclone.extfs --clone --source ${INFILE}2 --output - | bzip2 -9 > $OUTDIR/system.$OUTEXT
																					else
																						partclone.extfs --clone --source ${INFILE}2 --output $OUTDIR/system.$OUTEXT
																							fi
																							if [[ ! -f $OUTDIR/mbr.img ]]; then
																								echo -e "\n*** Error: $OUTDIR/mbr.img is missing, something went wrong\n"
																									exit 8
																									fi
																									if [[ ! -f $OUTDIR/boot.$OUTEXT ]]; then
																										echo -e "\n*** Error: $OUTDIR/boot.$OUTEXT is missing, something went wrong\n"
																											exit 9
																											fi
																											if [[ ! -f $OUTDIR/system.$OUTEXT ]]; then
																												echo -e "\n*** Error: $OUTDIR/system.$OUTEXT is missing, something went wrong\n"
																													exit 10
																													fi
																													echo -e "\n${COL_HIGHLIGHT}Everything is Ok.${COL_RESET}\n"
}

if [ "$EUID" -ne 0 ]
  then 
        printf "\033[0;31mpi_3_arcade script written by LWX, this script comes with ABSOLUTELY NO WARRANTY!\033[0m\n"
        printf "\033[0;32mVersion 1.0\n\n\033[0m"
	echo "Please run as root"
  exit
fi


prompt
eval
while [ $invalid == 1 ]
do
clear
echo -e "You entered an invalid selection!\nTry again!\n"
prompt
eval
done
