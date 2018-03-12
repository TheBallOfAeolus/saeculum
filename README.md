# saeculum

This is a simple bash scripts that creates a time-lapse video, adding a description and the exif time of when each photo was taken. 
 
I love the GoPro time-lapse functionality, but I wasn't able to find any command line solution that would navigate through all the folders created under DCIM and create a time-lapse video for me.

## Features
### added
* recursively go through subfolders
* add automatically on the bottom right the date and time of each picture taken (original exif)
* if restarted, it will automatically continue from where it left
* add a description on the video
* creates a text with the command used for the video
### to do
* tilt-shift images and video
* refactor to provide more video editing options
* if succesful automatically delete temporary pictures and folders
* add a watermark
* add a small "trademark" on a side

## Getting Started

The script is expecting a folder with all the pictures taken (it will automatically recursively navigate within it and find any JPG or jpg present).

As it is right now, it will create a local temp folder and will add to each picture a specific description and the date and time taken (from the exif information).

If for whatever reason the script is stopped during the process, when re-run it will automatically continue from where it was left.

If it is needed to re-create everything, please delete the temporary folder and run the script again.

### Prerequisites

mencoder

```
:~$ sudo apt-get install mencoder
```

### Installing

Just download the script and run it.

example
```
:~$ git clone https://github.com/TheBallOfAeolus/saeculum.git
:~$ cd saeculum/
:~$ ./Create_Time-lapse_Video.sh <~/TheFolder/WhereYouPicturesAreLocated>
```

If you really want to install it, in Ubuntu you can move the script (or link -s) to ~/bin.
Remember to re-reload .profile
```
:~$ . ~/.profile
```
## Example

I will upload a Youtube soon

## Authors

* **The Ball Of Aeolus** - *Initial work* - [TheBallOfAeolus](https://github.com/TheBallOfAeolus)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details


