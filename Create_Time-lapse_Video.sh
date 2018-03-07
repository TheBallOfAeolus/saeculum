#!/bin/bash
#
# 
# MIT License
# 
# Copyright (c) 2018 TheBallOfAeolus
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of 
# this software and associated documentation files (the "Software"), to deal in the 
# Software without restriction, including without limitation the rights to use, copy, 
# modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
# and to permit persons to whom the Software is furnished to do so, subject to the 
# following conditions:
# The above copyright notice and this permission notice shall be included in all 
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
# CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE 
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
# 
# 





# Accept folder
if [ "$#" != "1" ]; then
  printf "I need the folder name where all the original pictures are\\n"
  printf "Please, enter folder name:\\n"
  read -r VAR_OriginalFolderName
else
  VAR_OriginalFolderName="$1"
fi;
CleanedVAR_OriginalFolderName=${VAR_OriginalFolderName//[+= .,?\\\/:]/_}

# Confirm if the folder request exist
VAR_OriginalPicturesFolderLocation=$VAR_OriginalFolderName
if [ ! -d $VAR_OriginalPicturesFolderLocation ]; then
  printf "I couldn't find the folder $VAR_OriginalPicturesFolderLocation\\n"
  printf "Please make sure $VAR_OriginalFolderName exist.\\n"
else
  printf "\\nWe have found $VAR_OriginalFolderName\\n"
  printf "We will now start creating temporary folders needed for the time-lapse video.\\n\\n"
fi;

# Create temproray folder
VAR_TempFolder="temp_${VAR_OriginalFolderName}"
if [ ! -d $VAR_TempFolder ]; then
  mkdir -p $VAR_TempFolder;
fi;

#### Step 01 add date and description to pictures ####
printf "#### Adding the time and date to each picture ####\\n"

if [ -f $VAR_TempFolder/DescriptionDisplayedInVideo.txt ]; then
  description=`cat $VAR_TempFolder/DescriptionDisplayedInVideo.txt`
  printf "We have found the following description previously used for this time-lapse:\\n"
  printf "${description}\\n\\n"
  read -p "Press enter to continue"
else
  printf "Please add the description you would like to have in front of the date and time:\\n"
  read -r description
  echo "${description}" > $VAR_TempFolder/DescriptionDisplayedInVideo.txt
fi;
CleanedDescription=${description//[+= .,?]/_}

# step 01.1 confirm if the folder where the temporary images are going to be created exist, if it doesn't create it
VAR_AddedTimeTempFolder="${VAR_TempFolder}/AddedTime"
if [ ! -d $VAR_AddedTimeTempFolder ]; then
  printf "\\n\\nCreating the temporary folder where we will be storing the pictures with the date and time.\\n\\n"
  mkdir -p $VAR_AddedTimeTempFolder;
else
  printf "\\n\\nIt seems we have found a previously created $VAR_AddedTimeTempFolder\\n"
  printf "The app won't overwrite already created files, it will automatically continue where it left.\\n"
  printf "If you want to force the creation of the files, please delete the temp folder and run the script again.\\n\\n"
  read -p "Press enter to continue"
fi;

## step 01.2 count total amount of files to know create the %
VAR_TotalAmountOfPicturesToProcess=$(find $VAR_OriginalPicturesFolderLocation -name '*.jpg' -or -name '*.JPG' | wc -l)
VAR_AmountOfFilesProcessed=0

## step 01.3 Add date and time to each picture

for File in $(find $VAR_OriginalPicturesFolderLocation -name '*.jpg' -or -name '*.JPG')
do printf "For the following: $File adding date and time\\n"
  Dir=${File%/*}
  FullFilename=${File##*/}
  Filename=${FullFilename%.*}
  Extension=${File##*.}
  Output=${Filename}_DT.jpg
  TemporaryFileWithDT=$VAR_AddedTimeTempFolder"/"$Output
  #printf "$Dir\\n"
  #printf "$FullFilename\\n"
  #printf "$Filename\\n"
  #printf "$Extension\\n"
  #printf "$Output\\n"
  #printf "$TemporaryFileWithDT\\n"
  let VAR_AmountOfFilesProcessed=VAR_AmountOfFilesProcessed+1
  VAR_PercentageProcessed=$(echo "scale=2; $VAR_AmountOfFilesProcessed*100/$VAR_TotalAmountOfPicturesToProcess" | bc)
  printf "$VAR_AmountOfFilesProcessed of $VAR_TotalAmountOfPicturesToProcess files processed = ${VAR_PercentageProcessed}%%\\n"

  if [ ! -f $TemporaryFileWithDT ]; then
    # Change the font variable to point to your font location
    font="/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
    
    # GoPRO: Width: 2592, Height: 1944. Using pointsize: 43
    pointsize=43
    
    # Adding description date and time
    convert $File \
    -font $font \
    -pointsize $pointsize \
    \( -gravity SouthEast \
      -fill black \
      -annotate +$pointsize+$pointsize %[exif:DateTimeOriginal] \
      -blur 0x2 \)\
    \( -gravity SouthWest \
      -fill black \
      -annotate +$pointsize+$pointsize "$description" \
      -blur 0x2 \)\
    \( -gravity SouthEast \
      -fill white \
      -annotate +$pointsize+$pointsize %[exif:DateTimeOriginal] \)\
    \( -gravity SouthWest \
      -fill white \
      -annotate +$pointsize+$pointsize "$description" \)\
    $TemporaryFileWithDT
    printf "CREATED $TemporaryFileWithDT\\n\\n"
  else
    printf "Skipping file, already exist\\n\\n"
  fi
done

## Step 02 create video
#printf "${VAR_TempFolder}\\n"
#printf "${VAR_AddedTimeTempFolder}\\n"
ls -1v $PWD/${VAR_AddedTimeTempFolder}/* | grep jpg > $VAR_TempFolder/ListOfAddedTimeFiles.txt

# 1080p@24fps, no sound
# fps=24
# scale=1920:1080

# 4k@90fps, no sound
fps=60
scale=3840:2160
CleanedScale=${scale//[-+=.,:]/x}

VideoFileName="${CleanedVAR_OriginalFolderName}_-_${CleanedDescription}_-_fps_${fps}_-_scale_${CleanedScale}.avi"

mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=21600000 -o $VideoFileName -mf type=jpeg:fps=$fps mf://@$PWD/${VAR_TempFolder}/ListOfAddedTimeFiles.txt -vf scale=$scale

printf "\\n\\n CONGRATS\\n"
printf "$VideoFileName\\n"
printf "created in local directory\\n\\n"

## creates a file with the most useful commands
printf "## If you delete some pictures from the folder and you want to re-create the list, run the first ls command ##\\n" > $PWD/$VAR_TempFolder/CheatSheet.txt
printf "ls -1v $PWD/${VAR_AddedTimeTempFolder}/* | grep jpg > $VAR_TempFolder/ListOfAddedTimeFiles.txt" >> $PWD/$VAR_TempFolder/CheatSheet.txt
printf "\\n\\n## If you want to modify the mencoder command, here you can find the original one used ##\\n" >> $PWD/$VAR_TempFolder/CheatSheet.txt
printf "mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=21600000 -o $VideoFileName -mf type=jpeg:fps=$fps mf://@$PWD/${VAR_TempFolder}/ListOfAddedTimeFiles.txt -vf scale=$scale" >> $VAR_TempFolder/CheatSheet.txt


exit 0
