#!/bin/bash -xe
clear
chmod 777 *.*;
Disc_number=1/1;
Bit_rate=320;
Sample_rate=44.1;
FlacDir=Flac
Picture_name="Front.jpg"
MusicFilesDirectoryName=Disc
MusicFilesDirectoryNameFlac="$MusicFilesDirectoryName$FlacDir"
ImagesFilesDirectoryName=Covers
WaveFileName=temp.wav

Artist="";
Album="";
Genre="";
Year=0;
FlacFilesCount=0;

main()
{
	PrepareEnvironment
	ConvertFiles
	FolderManage
	echo "Conversiond ended."
}

function PrepareEnvironment
{
	CheckForNecessaryApplications
	CheckForFolderFile
}

function CheckForNecessaryApplications
{
	AppIsInstalled flac
	AppIsInstalled lame
	AppIsInstalled id3v2	
}

function AppIsInstalled
{
	local applicationName="$1";
	hash $applicationName 2>/dev/null || { echo >&2 "I require $applicationName but it's not installed.  Aborting."; exit 1; }
}

function CheckForFolderFile
{
	if [ ! -f "$Picture_name" ]; then
		echo "Picture file $Picture_name not found, aborting script."
		exit 1;
	fi
}

function ConvertFiles
{
	FlacFilesCount=`CountTracks`
	for a in *.flac
	do
		ConvertFlac "$a"
	done
}

# Check if track contains 0 while less than 10, if not - add 0 to track.
function CountTracks
{
	local FlacFilesCount=`ls -lhs | grep .flac | wc -l`;
	FlacFilesCount=`AddPrecedingZero $FlacFilesCount`;
	echo $FlacFilesCount;
}

function ConvertFlac
{
	echo "Processing file $1 ... "
	printf "Geting tags from flac file... "
	Artist=`metaflac "$1" --show-tag=ARTIST | sed 's/.*=//'`;
	Album=`metaflac "$1" --show-tag=ALBUM | sed 's/.*=//'`;
	Genre=`metaflac "$1" --show-tag=GENRE | sed 's/.*=//'`;
	Year=`metaflac "$1" --show-tag=DATE | sed 's/.*=//'`;
	Title=`metaflac "$1" --show-tag=TITLE | sed 's/.*=//'`;
	Track=`metaflac "$1" --show-tag=TRACKNUMBER | sed 's/.*=//'`;	
	Track=`AddPrecedingZero $Track`
	if [ "$Artist" == "" ];then
		echo "Artist tag is empty, aborting."
		exit 1;
	fi
	if [ "$Album" == "" ];then
		echo "Album tag is empty, aborting."
		exit 1;
	fi
# Set filename to Track - Title.
	Outlame="$Track $Title.mp3";
# Print ID3 tags and target filename
	printf "Done."
	echo -e "\nTrack \t= $Track/$FlacFilesCount";
	echo -e "Year \t= $Year"
	echo -e "Title \t= $Title";
	echo -e "Artist \t= $Artist" 
	echo -e "Album \t= $Album" 
	echo -e "Genre \t= $Genre" 
# flac decoding and mp3 coding with selected options:
	#flac -c -d "$1" | lame --ti "$Picture_name" -b "$Bit_rate" -m s -q 0 -s "$Sample_rate" - "$Outlame"
	#-d = decode, -c = write output to sdout
	flac -f -d "$1" -o "$WaveFileName"
	lame --noreplaygain --ti "$Picture_name" -b "$Bit_rate" -m s -q 0 -s "$Sample_rate" "$WaveFileName" "$Outlame"
	rm -f "$WaveFileName"
	#Set mp3 file tags as they were in flac file.
	id3v2 --song "$Title" "$Outlame";
	id3v2 --track "$Track/$FlacFilesCount" "$Outlame";
	id3v2 --artist "$Artist" "$Outlame";
	id3v2 --album "$Album" "$Outlame";
	id3v2 --genre "$Genre" "$Outlame";
	id3v2 --year "$Year" "$Outlame";
	id3v2 --TPOS "$Disc_number" "$Outlame";
}

function AddPrecedingZero
{
	Temp="$1";
	if [ $1 -le 9 ];then 
		if [[ "$1" != 0? ]];then
			Temp=`echo "0$1"`
		fi
	fi 
	echo "$Temp"
}

function FolderManage
{
	MoveMusicFiles
	MoveImageFiles
}

function MoveMusicFiles
{
	mkdir --parents --mode=777 "$MusicFilesDirectoryName"
	mv *.mp3 "$MusicFilesDirectoryName"
	mkdir --parents --mode=777 "$MusicFilesDirectoryNameFlac"
	mv *.flac "$MusicFilesDirectoryNameFlac"
}

function MoveImageFiles
{
	mkdir --parents --mode=777 "$ImagesFilesDirectoryName" 
	mv *.jpg "$ImagesFilesDirectoryName" 
	mv *.png "$ImagesFilesDirectoryName" 
	mv *.jpeg "$ImagesFilesDirectoryName"
	mv *.bmp "$ImagesFilesDirectoryName" 
}

main "$@";

