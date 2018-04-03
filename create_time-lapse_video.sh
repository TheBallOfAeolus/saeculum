#!/bin/bash

#*********************************************************************************************#
#                        https://github.com/TheBallOfAeolus/saeculum                          #
#                                  written by TheBallOfAeolus                                 #
#                                         March 2018                                          #
#                                                                                             #
#  Creates a time-lapse video, from a folder containing multiple pictures and or sub-folders  #
#     Providing the ability to add a description and/or the exif date and/or a signature.     #
#*********************************************************************************************#


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



### ERROR CODES ###
E_BADDIR=85                     # No such directory.
E_CANNOTEXECUTE=126             # Command invoked cannot execute



### DEFAULT VALUES ###

# for video formatting
fps=60
scale=3840:2160

# for date and notes displayed in pictures
font="/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"  # using mono so date and time do not "dance" in video
pointsize=43      # with GoPRO: Width: 2592, Height: 1944. Using pointsize: 43

# for signature displayed in pictures
signature_pointsize=16
signature_font="/usr/share/fonts/truetype/msttcorefonts/comic.ttf"

# by default the date and time is the picture original exif information
date_and_time="%[exif:DateTimeOriginal]"



### FUNCTIONS ###

# print help
_print_help()
{
  echo "$0 usage:" && grep " .)\ #" $0;
  exit 0;
}

# stop the script if Control-C is selected
_stop_it ()
{
  kill -s SIGTERM $!
  exit 0
}

# used only for testing
_display_options_selected ()
{
  printf "options selected are:\\n"
#  printf "  tiltshift: $tiltshift\\n"
  printf "  annotate: $annotation\\n"
  printf "  date_and_time: ${date_and_time}\\n"
  printf "  signature: $signature\\n"
#  printf "  watermark: $watermark\\n"
  shift $(($OPTIND - 1))
  printf "  Remaining arguments are: %s\n" "$*"
}

# Adding the date and time, the annotation and the signature to the temporary picture
_add_annotation_signature_date_and_time_on_picture ()
{
  convert $1 \
  \( -font $font \
  -pointsize $pointsize \
  -fill white \
  -strokewidth 2 \
  -stroke Black \
  -gravity SouthEast \
  -annotate +$pointsize+$pointsize "$date_and_time" \)\
  \( -font $font \
  -pointsize $pointsize \
  -fill white \
  -strokewidth 2 \
  -stroke Black \
  -gravity SouthWest \
  -annotate +$pointsize+$pointsize "$annotation" \)\
  \( -font $signature_font \
  -pointsize $signature_pointsize \
  -stroke snow2 \
  -gravity NorthEast \
  -annotate 270x270+16+16 "$signature" \)\
  $temporary_file_with_annotation_signature_date_and_time_on_picture
}

# Confirm if the original folder exists
_confirm_if_original_folder_exists ()
{
  if [ ! -d $original_folder_name ]; then
    printf "I couldn't find the folder $original_folder_name\\n"
    _print_help
    exit $E_BADDIR
  else
    printf "\\nWe have found $original_folder_name\\n"
    printf "We will now start creating temporary folders needed for the time-lapse video.\\n\\n"
  fi;
}




# ----------------------------------- #
#   here is where the magic happens   #
# ----------------------------------- #

# test if `mencoder` is available
MENCODER=`which mencoder 2> /dev/null`
if [ -z $MENCODER ]; then
  echo '`mencoder` is not available, please install it'
  exit 1
fi


## get the options
[ $# -eq 0 ] && _print_help
while getopts "t :h:d:a:s:w:" options; do
  case $options in
    a) # Annotate: add a caption/description on the left of the time-lapse video.
      annotation=${OPTARG}
    ;;
    d) # Date&Time: use this option to specify a specific static date (by default the script will read the exif information and add it to the video)
      date_and_time=${OPTARG}
    ;;
    s) # Signature: add the signature/credit description small and in vertical top right position.
      signature=${OPTARG}
    ;;
    h | *) # Help: Display help.
      _print_help
      exit 0
    ;;
  esac
done

# TODO repeat for every folder, the script right now will take the last entry as folder to work with.
shift $(($OPTIND - 1))
original_folder_name="$*"


_display_options_selected

_confirm_if_original_folder_exists


# Create temporay folder
temp_folder="temp_${original_folder_name}"
if [ ! -d $temp_folder ]; then
  mkdir -p $temp_folder;
fi;

trap _stop_it SIGINT SIGTERM

#### Step 01 add date and description to pictures ####
printf "#### Adding the time and date to each picture ####\\n"
config_file_where_annotation_is_stored="$temp_folder/annotation_displayed_in_video.txt"
if [ -f $config_file_where_annotation_is_stored ]; then
  annotation=`cat $config_file_where_annotation_is_stored`
  printf "We have found the following description previously used for this time-lapse:\\n"
  printf "${annotation}\\n\\n"
  read -p "Press enter to continue"
else
  echo "${annotation}" > $config_file_where_annotation_is_stored
fi;

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
total_amount_of_pictures_to_process=$(find $original_folder_name -name '*.jpg' -or -name '*.JPG' | wc -l)
amount_of_files_processed=0

## step 01.3 Add date and time to each picture

for file in $(find $original_folder_name -name '*.jpg' -or -name '*.JPG')
do printf "For the following: $file adding date and time\\n"
  dir=${file%/*}
  full_file_name=${file##*/}
  filename=${full_file_name%.*}
  extension=${file##*.}
  output=${filename}_DT.jpg
  temporary_file_with_annotation_signature_date_and_time_on_picture=$added_time_temp_folder"/"$output
  #printf "$dir\\n"
  #printf "$full_file_name\\n"
  #printf "$filename\\n"
  #printf "$extension\\n"
  #printf "$output\\n"
  #printf "$temporary_file_with_annotation_signature_date_and_time_on_picture\\n"
  let amount_of_files_processed=amount_of_files_processed+1
  percentage_processed=$(echo "scale=2; $amount_of_files_processed*100/$total_amount_of_pictures_to_process" | bc)
  printf "$amount_of_files_processed of $total_amount_of_pictures_to_process files processed = ${percentage_processed}%%\\n"
  
  if [ ! -f $temporary_file_with_annotation_signature_date_and_time_on_picture ]; then
    
    _add_annotation_signature_date_and_time_on_picture "$file"
    ## TO DO while terminated by Control-C
    printf "CREATED $temporary_file_with_annotation_signature_date_and_time_on_picture\\n\\n"
  else
    printf "Skipping file, already exist\\n\\n"
  fi
done






## Step 99 create video
#printf "${temp_folder}\\n"
#printf "${added_time_temp_folder}\\n"
ls -1v $PWD/${added_time_temp_folder}/* | grep jpg > $temp_folder/list_of_files_with_added_time.txt


cleaned_scale=${scale//[-+=.,:]/x}
cleaned_original_folder_name=${original_folder_name//[+= .,?\\\/:]/_}
cleaned_annotation=${annotation//[+= .,?\\\/:]/_}
video_file_name="${cleaned_original_folder_name}_-_${cleaned_annotation}_-_fps_${fps}_-_scale_${cleaned_scale}.avi"

mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=21600000 -o $video_file_name -mf type=jpeg:fps=$fps mf://@$PWD/${temp_folder}/list_of_files_with_added_time.txt -vf scale=$scale

printf "\\n\\n CONGRATS\\n"
printf "$video_file_name\\n"
printf "created in local directory\\n\\n"

## creates a file with the most useful commands
printf "## If you delete some pictures from the folder and you want to re-create the list, run the first ls command ##\\n" > $PWD/$temp_folder/cheat_sheet_with_commands_used.txt
printf "ls -1v $PWD/${added_time_temp_folder}/* | grep jpg > $temp_folder/list_of_files_with_added_time.txt" >> $PWD/$temp_folder/cheat_sheet_with_commands_used.txt
printf "\\n\\n## If you want to modify the mencoder command, here you can find the original one used ##\\n" >> $PWD/$temp_folder/cheat_sheet_with_commands_used.txt
printf "mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=21600000 -o $video_file_name -mf type=jpeg:fps=$fps mf://@$PWD/${temp_folder}/list_of_files_with_added_time.txt -vf scale=$scale" >> $temp_folder/cheat_sheet_with_commands_used.txt

## TO DO add summary of video:
# total duration of video
# from first exif to last
# total duration of time-lapse captured

# TO DO
# add information in video


exit 0
