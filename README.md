## GeoTag for macOS -- macOS 15 or later for latest version

GeoTag is a free OS X single window application that allows you to update image
metadata with geolocation tags by selecting one or more images then panning and
zooming within a a map to the place the image was recorded. Clicking on the map
will add the location to the selected photos.  Clicking on a new location will
change the geolocation for the selected photos.  Zoom in on the map and fine
tune the location with a click.  The built in ExifTool utility is used to write
location data to the images when you save your changes.  ExifTool only modifies
image metadata -- your image pixels are not touched.

See <http://exiftool.org> for information about ExifTool.
**ExifTool is built-in to GeoTag.**

### Version requirements

- GeoTag 5.7+ requires macOS 15 (Sequoia) or later.
- GeoTag 5.2 thru 5.6 requires macOS 14 (Sonoma) or later.
  ![warning] 
  There is a map pin location issue when running on early versions of macOS
  Sonoma. If you see a pin placed above the point you clicked/tapped you are
  seeing this bug. Apple fixed the issue in version 14.4 (or perhaps it was
  14.4.1). It is not a problem in the latest versions of Sonoma or in Sequoia.
- Use GeoTag 5.1 if running on macOS Ventura.
- Those running earlier versions of macOS can use GeoTag version 4.15.

## WIP

### Updates

- show image names in orange when it appears to be a valid image format
  but there is no existing metadata or the metadata can not be read. This
  is the case with Fujifilm Compressed Raw files, for example. If the
  image can not be previewed it is a format that can not be decoded.
  Otherwise it is an image with no metadata.

- Add a find command (shortcut ⌘F) to the edit menu. The command will
  select the map search field.

- Show City/State/Country/Country Code in the info pane.

- Settings window re-design

- Exiftool version 13.45

### Bug Fixes

- Only the first raw-jpg pair was processed when the Disable paired jpegs
  option was set. All pairs are now properly processed.

### Known Issues

- Developer issue: User Interface testing is broken.  Sometimes the tests
  pass. Sometimes they crash at startup.  Sometimes the main window
  never opens.  I believe this is an XCUITest issue, probably triggered
  by something GeoTag or the GeoTag tests do. Otherwise I'd expect
  to see others complaining of the problem.

## GeoTag 5.6

### Updates

- Allow a larger Name column in the table. If the file name does not fit
  in the given space truncate characters in the middle of the name instead
  of the end allowing the file extension to be seen.

- Add a View menu option to select an alternate layout where the image
  is below the table in the left pane instead of avbove the map in the
  right pane. Current layout and pane divider locations are saved across
  program execution.

- Changes needed for macOS 26.

- ExifTool 13.37


### Bug Fixes

- Alert the user when access to the Photos Library is denied.

- The delay between cliking on the map and appearance of a pin is better.

- Display the tool-tip for the "Extend track timestamps" setting.

- Restore display the elevation for a location when hovering over the
  latitude or longitude.

- Clicking on a map search saved value a second and subsequent time will
  recenter the map on the location if it isn't in view.

- Closing the window with changes pending and no backup folder selected
  now quits the app instead of again reminding you that no backup folder
  is selected.

- Closing a window with pending changes does not close the window until
  the user has a chance to answer the "do you really mean it?" message.
  The app was closing the window then immediately re-opening it to
  display the message.

### Known issues

- undo/redo menu items are always enabled, even when there are no undo or
  redo actions that could be performed. The menu titles are also not updated
  for the action to be performed.
- When showing pins for all selected locations the red (most selected) pin
  may be hidden by the pin of another location near by unless the zoom level
  is such that both locations are slightly separated on the map.
- when changing the selection to an image that has a location some of the pin
  may off the map view.  In an extreme case only the point of the pin is on
  the map and can not be seen. If you do not see a pin when you expect to
  zoom out slightly.
- Double clicking to zoom in or option-double clicking to zoom out will
  move the pins of selected items. Deselect all items or use a different
  zoom method to workaround this issue.
- Double click to zoom in/out was hit or miss when tested on an intel
  Mac running macOS Sequoia 15.7. Suggest using other methods of
  zooming the map.
- paste sometimes not enabled after cut. Can not reproduce on demand.

---

### Operating Instructions:

*See <https://www.snafu.org/GeoTag/GeoTag5Help/> for more information.*

Run Program.  Use the Open command from the menu or ⌘O to select files to
modify. You can also drag files from the finder into the table on the left side
of the application window.  Or you may select images from your Photos
Library. File names shown in a light grey color are not recognized as valid
image files or are disabled for other reasons.  Such files can not be
modified. Dragging or opening a folder will add all the files in the folder
and any subfolders.

Select one or more images. When selecting multiple images one of the
images is considered the "most selected". The name of the most selected
image is shown in yellow using a bolder font.  The thumbnail of the most
selected image is displayed in the image well (upper right portion of the
window). Its location (if any) is marked on the map.

Click on the map to set or change the location of all selected images. Existing
location can be changed by clicking on the desired location. Hitting the delete
key will remove location information from all selected images.  You can
Undo/Redo image location changes.

Double click the map to zoom in. Option-double click to zoom out. Or use
pinch gestures to zoom in and out if using a touch pad.

Five map styles --- Standard, Imagery, Hybrid, Standard with traffic, and
Hybrid with traffic --- are supported. Right click on the map to select
the desired map style. If you find yourself working in a specific area of a
map you can save the location and zoom level by right clicking on the map
and selecting *Save map location*.  When GeoTag is launched the map will
load to the last saved location using the last map style selected.

You may cut or copy location information from a single image and then paste
that information into one or more images.  If you make an error you can
undo/redo your changes. You can undo all changes to all images by selecting
"Discard changes" from the "File" menu.  All Undo/Redo information is cleared
once changes are discarded or saved.

The original versions of images that have been updated are saved are in a
backup folder.  The backup folder may be changed using GeoTag Settings.
The first time GeoTag is run it will prompt you to select a backup folder.
Images updates can not be saved until a backup folder is selected or backups
are disabled (not recommended).

Cut, Copy, Paste, Delete, and Clear Image List can be accessed from
a pop up menu by right clicking on an entry in the list.

### Build Instructions for developers

* Get current sources from github -- https://github.com/marchyman/GeoTag
* GeoTag uses a project.yml file and [xcodegen](https://github.com/yonaskolb/XcodeGen)
  to generate the GeoTag.xcodeproj bundle. Install and run `xcodegen`.
* Open the generated project in Xcode
* ⌘R will build and run, ⌘B to build only

Please report bugs, make requests, etc. [here](https://github.com/marchyman/GeoTag/issues)
