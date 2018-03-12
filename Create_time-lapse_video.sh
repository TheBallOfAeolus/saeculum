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
## TODO:need to add a confirmation that the folder exists.
if [ "$#" != "1" ]; then
  printf "I need the folder name where all the original pictures are\\n"
  printf "Please, enter folder name:\\n"
  read -r original_folder_name
else
  original_folder_name="$1"
fi;
cleaned_original_folder_name=${original_folder_name//[+= .,?\\\/:]/_}

# Confirm if the folder request exist
original_pictures_folder_location=$original_folder_name
if [ ! -d $original_pictures_folder_location ]; then
  printf "I couldn't find the folder $original_pictures_folder_location\\n"
  printf "Please make sure $original_folder_name exist.\\n"
else
  printf "\\nWe have found $original_folder_name\\n"
  printf "We will now start creating temporary folders needed for the time-lapse video.\\n\\n"
fi;

# Create temproray folder
temp_folder="temp_${original_folder_name}"
if [ ! -d $temp_folder ]; then
  mkdir -p $temp_folder;
fi;

#### Step 01 add date and description to pictures ####
printf "#### Adding the time and date to each picture ####\\n"

if [ -f $temp_folder/description_displayed_in_video.txt ]; then
  description=`cat $temp_folder/description_displayed_in_video.txt`
  printf "We have found the following description previously used for this time-lapse:\\n"
  printf "${description}\\n\\n"
  read -p "Press enter to continue"
else
  printf "Please add the description you would like to have in front of the date and time:\\n"
  read -r description
  echo "${description}" > $temp_folder/description_displayed_in_video.txt
fi;
cleaned_description=${description//[+= .,?]/_}

# step 01.1 confirm if the folder where the temporary images are going to be created exist, if it doesn't create it
added_time_temp_folder="${temp_folder}/added_time"
if [ ! -d $added_time_temp_folder ]; then
  printf "\\n\\nCreating the temporary folder where we will be storing the pictures with the date and time.\\n\\n"
  mkdir -p $added_time_temp_folder;
else
  printf "\\n\\nIt seems we have found a previously created $added_time_temp_folder\\n"
  printf "The app won't overwrite already created files, it will automatically continue where it left.\\n"
  printf "If you want to force the creation of the files, please delete the temp folder and run the script again.\\n\\n"
  read -p "Press enter to continue"
fi;

## step 01.2 count total amount of files to know create the %
total_amount_of_pictures_to_process=$(find $original_pictures_folder_location -name '*.jpg' -or -name '*.JPG' | wc -l)
amount_of_files_processed=0

## step 01.3 Add date and time to each picture

for file in $(find $original_pictures_folder_location -name '*.jpg' -or -name '*.JPG')
do printf "For the following: $file adding date and time\\n"
  dir=${file%/*}
  full_file_name=${file##*/}
  filename=${full_file_name%.*}
  extension=${file##*.}
  output=${filename}_DT.jpg
  temporary_file_with_date_and_time=$added_time_temp_folder"/"$output
  #printf "$dir\\n"
  #printf "$full_file_name\\n"
  #printf "$filename\\n"
  #printf "$extension\\n"
  #printf "$output\\n"
  #printf "$temporary_file_with_date_and_time\\n"
  let amount_of_files_processed=amount_of_files_processed+1
  percentage_processed=$(echo "scale=2; $amount_of_files_processed*100/$total_amount_of_pictures_to_process" | bc)
  printf "$amount_of_files_processed of $total_amount_of_pictures_to_process files processed = ${percentage_processed}%%\\n"

  if [ ! -f $temporary_file_with_date_and_time ]; then
    # Change the font variable to point to your font location
    font="/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
    
    # GoPRO: Width: 2592, Height: 1944. Using pointsize: 43
    pointsize=43
    
    # Adding description date and time
    convert $file \
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
    $temporary_file_with_date_and_time
    printf "CREATED $temporary_file_with_date_and_time\\n\\n"
  else
    printf "Skipping file, already exist\\n\\n"
  fi
done

## Step 02 create video
#printf "${temp_folder}\\n"
#printf "${added_time_temp_folder}\\n"
ls -1v $PWD/${added_time_temp_folder}/* | grep jpg > $temp_folder/list_of_files_with_added_time.txt

# 1080p@24fps, no sound
# fps=24
# scale=1920:1080

# 4k@90fps, no sound
fps=60
scale=3840:2160
cleaned_scale=${scale//[-+=.,:]/x}

video_file_name="${cleaned_original_folder_name}_-_${cleaned_description}_-_fps_${fps}_-_scale_${cleaned_scale}.avi"

mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=21600000 -o $video_file_name -mf type=jpeg:fps=$fps mf://@$PWD/${temp_folder}/list_of_files_with_added_time.txt -vf scale=$scale

printf "\\n\\n CONGRATS\\n"
printf "$video_file_name\\n"
printf "created in local directory\\n\\n"

## creates a file with the most useful commands
printf "## If you delete some pictures from the folder and you want to re-create the list, run the first ls command ##\\n" > $PWD/$temp_folder/cheat_sheet_with_commands_used.txt
printf "ls -1v $PWD/${added_time_temp_folder}/* | grep jpg > $temp_folder/list_of_files_with_added_time.txt" >> $PWD/$temp_folder/cheat_sheet_with_commands_used.txt
printf "\\n\\n## If you want to modify the mencoder command, here you can find the original one used ##\\n" >> $PWD/$temp_folder/cheat_sheet_with_commands_used.txt
printf "mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=21600000 -o $video_file_name -mf type=jpeg:fps=$fps mf://@$PWD/${temp_folder}/list_of_files_with_added_time.txt -vf scale=$scale" >> $temp_folder/cheat_sheet_with_commands_used.txt


exit 0
