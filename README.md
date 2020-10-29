Lodr is a loader for [lovr](https://lovr.org/).

# How to use

Clone or download this repo. Stick the lovr-lodr directory in your command line after the executable name.

If `lovr.exe` is the LÖVR command line on your system and `your-game` is your project directory, run

    lovr.exe lovr-lodr your-game

If files change in `your-game` while it is running, lodr will automatically relaunch it.

## Configuration options

Lodr checks for a "lodr" table in the configuration table from conf.lua. You can set options like:

    function lovr.conf(t)
        t.lodr = {
            checksPerFrame = 1   -- How many files lovr checks for changes every frame (default 10)
            watch = {"main.lua"} -- Watch only these files (by default watches every file in directory tree)
        }
    end

# License

(c) 2018 Andi McClure

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
