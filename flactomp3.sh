#!/bin/bash
clear
createDirectory="False";
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
	PrepareEnvironment "$@";
	ConvertFiles
	FolderManage
	CheckForFilesCount
	echo "Conversiond ended."
}

function PrepareEnvironment
{
	CheckForNecessaryApplications
	local imageExist=$(CheckForFolderFile)
	if [ "$imageExist" == "False" ];then
		echo "There is no file $Picture_name in current directory."
		echo "Searching for file in input files..."
		ExportImageFromFile
	fi
	imageExist=$(CheckForFolderFile)
	if [ "$imageExist" == "False" ];then
		echo "Cannot find file $Picture_name and cannot export it from flac file. Aborting script."	
		exit 1;
	fi
	echo "Done."
	DecideIfCreateDiscDirectory "$@";
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

function ExportImageFromFile
{
	for a in *.flac
	do
		metaflac "$a" --export-picture-to="$Picture_name"
		local imageExist=$(CheckForFolderFile)
		if [ "$imageExist" == "True" ];then
			break;
		fi
	done
}

function DecideIfCreateDiscDirectory
{
	if [ "$1" == "--create-disc-directory" ];then
		createDirectory="True";
		echo "Directory $MusicFilesDirectoryName will be created.";
	fi
}

function CheckForFolderFile
{
	if [ -f "$Picture_name" ]; then
		echo "True";
	else
		echo "False";
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
	local Artist=`metaflac "$1" --show-tag=ARTIST | sed 's/.*=//'`;
	local Album=`metaflac "$1" --show-tag=ALBUM | sed 's/.*=//'`;
	local Genre=`metaflac "$1" --show-tag=GENRE | sed 's/.*=//'`;
	if [ "$Genre" == "" ];then
		echo "Genre tag is empty, aborting."
		exit 1;
	fi

	local Year=`metaflac "$1" --show-tag=DATE | sed 's/.*=//'`;
	local Title=`metaflac "$1" --show-tag=TITLE | sed 's/.*=//'`;
	local Track=`metaflac "$1" --show-tag=TRACKNUMBER | sed 's/.*=//'`;	
	local containsTracksCount=$(TrackNumberContainTrackCount $Track)
	if [ "$containsTracksCount" == "True" ];then
		echo "Track number ( $Track ) contains slash..."
		Track=$(RemoveTracksCountFromTracknumber $Track)
	fi
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
	flac --decode-through-errors -f -d "$1" -o "$WaveFileName"
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

function TrackNumberContainTrackCount
{
	local TRACKNUMBER=$1
	if [[ $TRACKNUMBER == */* ]];then
		echo "True"
	else
		echo "False"
	fi
}

function RemoveTracksCountFromTracknumber
{
	local trackNumber=$1
	local result=`echo $trackNumber | cut -f1 -d"/"`
	echo "$result"
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
	if [ "$createDirectory" == "True" ];then 
		mkdir --parents "$MusicFilesDirectoryName"
		mv *.mp3 "$MusicFilesDirectoryName"
	fi
	mkdir --parents "$MusicFilesDirectoryNameFlac"
	mv *.flac "$MusicFilesDirectoryNameFlac"
}

function MoveImageFiles
{
	if [ "$createDirectory" == "True" ];then 
		mkdir --parents "$ImagesFilesDirectoryName" 
		mv *.jpg "$ImagesFilesDirectoryName" 
		mv *.png "$ImagesFilesDirectoryName" 
		mv *.jpeg "$ImagesFilesDirectoryName"
		mv *.bmp "$ImagesFilesDirectoryName" 
	fi
}

function CheckForFilesCount
{
	local mp3FilesCount=0
	if [ "$createDirectory" == "True" ];then 
		mp3FilesCount=`ls -lhs $MusicFilesDirectoryName | grep mp3 | wc -l`
	else
		mp3FilesCount=`ls -lhs | grep mp3 | wc -l`
	fi

	local flacFilesCount=`ls -lhs $MusicFilesDirectoryNameFlac | grep flac | wc -l`
	if [ $flacFilesCount -eq $mp3FilesCount ];then
		echo "Mp3 files count match flac files count."
	else
		echo "Something gone wrong, mp3 files count does not match flac files count."
	fi
}

main "$@";
