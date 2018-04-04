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
  echo "$0 usage:" && grep " .)\\ #" "$0";
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
#  printf "  tiltshift: %s\\n" "${tiltshift}"
  printf "  annotate: %s\\n" "${annotation}"
  printf "  date_and_time: %s\\n" "${date_and_time}"
  printf "  signature: %s\\n" "${signature}"
#  printf "  watermark: %s\\n" "${watermark}"
  shift $((OPTIND-1))
  printf "  Remaining arguments are: %s\\n" "$*"
}

# Adding the date and time, the annotation and the signature to the temporary picture
_add_annotation_signature_date_and_time_on_picture ()
{
  convert "$1" \
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
  "$temporary_file_with_annotation_signature_date_and_time_on_picture"
}

# Confirm if the original folder exists
_confirm_if_original_folder_exists ()
{
  if [ ! -d "${original_folder_name}" ]; then
    printf "I couldn't find the folder %s\\n" "$original_folder_name"
    _print_help
    exit $E_BADDIR
  else
    printf "\\nWe have found %s\\n" "$original_folder_name"
    printf "We will now start creating temporary folders needed for the time-lapse video.\\n\\n"
  fi;
}




# ----------------------------------- #
#   here is where the magic happens   #
# ----------------------------------- #

# test if `mencoder` is available
MENCODER=$(command -v mencoder 2> /dev/null)
if [ -z "$MENCODER" ]; then
  printf "mencoder is not available, please install it\\n"
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

# TODO repeat for every folder, the script right now will come back with an error if multiple folders are introduced
shift $((OPTIND-1))
original_folder_name="$*"


_display_options_selected ""


_confirm_if_original_folder_exists ""

trap _stop_it SIGINT SIGTERM


# Create temporay folder
temp_folder="temp_${original_folder_name}"
if [ ! -d "$temp_folder" ]; then
  mkdir -p "$temp_folder";
fi;

# step 01.1 confirm if the folder where the temporary images are going to be created exist, if it doesn't create it
added_time_temp_folder="${temp_folder}added_time"
if [ ! -d "$added_time_temp_folder" ]; then
  mkdir -p "$added_time_temp_folder";
fi;

## step 01.2 count total amount of files to know create the %
total_amount_of_pictures_to_process=$(find "$original_folder_name" -name '*.jpg' -or -name '*.JPG' | wc -l)
amount_of_files_processed=0

## step 01.3 Add date and time to each picture

#for file in $(find "$original_folder_name" -name '*.jpg' -or -name '*.JPG')
while IFS= read -r -d '' file
do printf "For the following: %s adding date and time\\n" "$file"
  #dir=${file%/*}
  full_file_name=${file##*/}
  filename=${full_file_name%.*}
  #extension=${file##*.}
  output=${filename}_DT.jpg
  temporary_file_with_annotation_signature_date_and_time_on_picture=${added_time_temp_folder}"/"${output}
  #printf "$dir\\n"
  #printf "$full_file_name\\n"
  #printf "$filename\\n"
  #printf "$extension\\n"
  #printf "$output\\n"
  #printf "$temporary_file_with_annotation_signature_date_and_time_on_picture\\n"
  (( amount_of_files_processed++ ))
  percentage_processed=$(echo "scale=2; ${amount_of_files_processed}*100/${total_amount_of_pictures_to_process}" | bc)
  printf "${amount_of_files_processed} of ${total_amount_of_pictures_to_process} files processed = ${percentage_processed}%%\\n"
  
  if [ ! -f "${temporary_file_with_annotation_signature_date_and_time_on_picture}" ]; then
    _add_annotation_signature_date_and_time_on_picture "${file}"
    ## TO DO while terminated by Control-C
    printf "CREATED %s\\n\\n" "${temporary_file_with_annotation_signature_date_and_time_on_picture}"
  else
    printf "Skipping file, already exist\\n\\n"
  fi
done <   <(find "${original_folder_name}" \( -name '*.jpg' -or -name '*.JPG' \) -print0)






## Step 99 create video
# check if the file containing the list of picture is already there, if so delete it
if [ -f "${temp_folder}"/list_of_files_with_added_time.txt ]; then
  rm "${temp_folder}"/list_of_files_with_added_time.txt
fi;
# create a file with the list of pictures that mencoder will use
for f in "$PWD"/"${added_time_temp_folder}"/*
do
  case "$f" in
    *jpg) echo "$f" >> "${temp_folder}"list_of_files_with_added_time.txt;;
    *) true;;
  esac
done

# cleaning variables for mencoder and descriptions
cleaned_scale=${scale//[-+=.,:]/x}
cleaned_original_folder_name=${original_folder_name//[+= .,?\\\/:]/_}
cleaned_annotation=${annotation//[+= .,?\\\/:]/_}
video_file_name="${cleaned_original_folder_name}_-_${cleaned_annotation}_-_fps_${fps}_-_scale_${cleaned_scale}.avi"

#mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=21600000 -o "${video_file_name}" -mf type=jpeg:fps="${fps}" mf://@"$PWD"/"${temp_folder}"/list_of_files_with_added_time.txt -vf scale="${scale}"
generate_video="mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:vbitrate=21600000 -o ${video_file_name} -mf type=jpeg:fps=${fps} mf://@${PWD}/${temp_folder}list_of_files_with_added_time.txt -vf scale=${scale}"
eval "$generate_video"

printf "\\n\\n CONGRATS\\n"
printf "%s\\n" "${video_file_name}"
printf "created in local directory\\n\\n"

## creates a file with the most useful commands
cheat_sheet_file_with_commands_used="${PWD}/${temp_folder}/cheat_sheet_with_commands_used.txt"
{
  printf "## If you have deleted some pictures from the processed picture's folder and you want to re-create the list of jpg, run the folllowing command ##\\n" 
  printf "ls -1v %s/%s/* | grep jpg > %slist_of_files_with_added_time.txt" "$PWD" "${added_time_temp_folder}" "$temp_folder"
  printf "\\n\\n## If you want to modify the mencoder command, here you can find the one used by the script ##\\n" 
  printf "%s" "${generate_video}"
} > "${cheat_sheet_file_with_commands_used}"

## TO DO add summary of video:
# total duration of captured video from first exif to last
# total duration of generated time-lapse video

## TO DO video editing
# export options 
# add metadata information in video


exit 0
