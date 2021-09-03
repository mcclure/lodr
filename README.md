Lodr is a hot-loader for [lovr](https://lovr.org/). It restarts Lovr with updated code without Lovr itself having to quit and reopen.

# How to use

## On Oculus Quest

Go to the [releases page](https://github.com/mcclure/lodr/releases) for Lodr and download the newest `org.lovr.hotswap` APK. This has Lodr prebuilt in it.

You will need your Quest in [developer mode](https://learn.adafruit.com/sideloading-on-oculus-quest/enable-developer-mode). You will also need the `adb` command line tool. For example, on Macintosh, you can get `adb` by installing [Homebrew](https://brew.sh/) and running `brew cask install android-platform-tools`; or, you can install [Android Studio](https://developer.android.com/studio), install "Android SDK Platform-Tools" during the first-run setup, and then run `export PATH="~/Library/Android/sdk/platform-tools:$PATH"` in your Terminal.app window before running the following commands. On Windows, to run adb, you can run [these instructions](https://www.howtogeek.com/125769/how-to-install-and-use-abd-the-android-debug-bridge-utility/) (but you will also need to install the special [Quest ADB driver for Windows](https://developer.oculus.com/downloads/package/oculus-adb-drivers/)).

After downloading `org.lovr.hotswap.apk`, `cd` to your download folder and run:

    adb install -r org.lovr.hotswap.apk

You only have to do this once.

Now, whenever you have new software to upload, `cd` to the directory containing your files and run:

    adb push --sync . /sdcard/Android/data/org.lovr.hotswap/files/.lodr

You can run this while Lodr is running.

If your program contains print statements, you can view them with:

    adb logcat | grep -i lovr

## On a desktop computer

Clone or download this repo. Stick the lovr-lodr directory in your command line after the executable name.

If `lovr.exe` is the LÖVR command line on your system and `your-game` is your project directory, run

    lovr.exe lovr-lodr your-game

If files change in `your-game` while it is running, lodr will automatically relaunch it.

# Configuration options

Lodr checks for a "lodr" table in the configuration table from conf.lua. You can set options like:

    function lovr.conf(t)
        t.lodr = {
            checksPerFrame = 1   -- How many files maximum lovr checks for changes every frame (default 10)
            watch = {"main.lua"} -- Watch only these files (by default watches every file in directory tree)
        }
    end

# License

(c) 2018 Andi McClure

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
