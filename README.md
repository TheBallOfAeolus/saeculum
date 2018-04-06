# saeculum

A bash scripts that creates a time-lapse video providing options to add the exif time, description or a signature.
 
I love the GoPro time-lapse functionality, but I wasn't able to find any command line solution that would navigate through all the folders created under DCIM and create a time-lapse video for me.

## Features 
### added
* **recursively** go through **subfolders**
* **add** automatically on the bottom right the **date and time** of each picture taken (original **exif**)
* if restarted, it will automatically **continue from** where it **left**
* **add** an **annotation/description** on the video (bottom left)
* **add** a **signature/trademark** on the video (top right in vertical)
* creates a **cheatsheet**/text with the command used for the video
### to do
* tilt-shift video
* refactor to provide more video editing options
* if succesful automatically delete temporary pictures and folders
* add a watermark

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
:~$ ./create_time-lapse_video.sh <~/TheFolder/WhereYouPicturesAreLocated>
```

If you really want to install it, in Ubuntu you can move the script (or link -s) to ~/bin.
Remember to re-reload .profile
```
:~$ . ~/.profile
```
## Example

In this [Google drive link](https://drive.google.com/open?id=1cvwKGKIOoQJYrZujpnomUSjLde-LVSCQ), you can find a folder with the original pictures I have used for the following examples.
_As you can see, I have replicated the same folder stracture you can find in GoPro or other cameras._

### Using the script without options

```
:~$ create_time-lapse_video.sh 20160615_test/
```

example: https://youtu.be/ylO_mTFh2W8

The script by default will read the exif information and add the date at the bottom right of the picture

### Generate the video without a date

```
:~$ create_time-lapse_video.sh -d "" 20160615_test/
```

example: https://youtu.be/RC7Ni6qIObI

As commented by default the exif date is automatically added. 

If we do not want to display any information at all we need to pass ```-d ""```

### Use a specific description instead of the deafult exif date

```
:~$ create_time-lapse_video.sh -d "2099 Jan 33" 20160615_test/
```

example: https://youtu.be/i27lYU95qB8

Instead of using the exif information of every picture, we can force a specific information to be displayed instead.

### Add an annotation

```
:~$ create_time-lapse_video.sh -a "testing test" 20160615_test/
```

Example: https://youtu.be/cPavlMViS3Q

If we need to add a specific description, we can do it by using the option -a 


### Add an annotation and a signature

```
:~$ create_time-lapse_video.sh -a "testing test" -s "my@signature.com or https://test.testing" 20160615_test/
```

Example: https://youtu.be/0U8THadjH7E

Using the option ```-s ""``` a smaller vertical description on the top right is displayed, this can be used to trademark or url ot a simple signature.

## Authors

* **The Ball Of Aeolus** - *Initial work* - [TheBallOfAeolus](https://github.com/TheBallOfAeolus)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details


