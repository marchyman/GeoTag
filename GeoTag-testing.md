* Initial run (defaults delete org.snafu.GeoTag before running)
  Image backup folder can not be found sheet should be shown.
  open settings window and select a backup folder.  Close and quit.
  
* Launch.  Open settings and verify backup folder set.  Open "GeoTag About"
  and check program version.  Quit.

* Select image in finder and use Open With selecting the version of GeoTag
  noted in the previous step.  Verify image is loaded into table.

* select image and assign a location by clicking on the map.
  Verify map pin placed
  Verify location assigned to image with coords colored green in table.

* Use Cmd-Z to undo change.  Verify.

* Use Shift-Cmd-Z to redo change.  Verify.

* File -> Discard changes.
  Verify confirmation dialog.  Select Cancel.  Verify coords not changed.
  Repeat, selecting "I'm Sure".  Verify coords reset.

* File -> Clear Image List.
  Verify empty table.

* File -> Open
  Select a single image from TestPictures
  Verify image loaded into table.
  Drag TestPictures onto GeoTag
  Verify images loaded
  Verify Warning about duplicate image displayed
  Verify images with sidecar files have a * after their name.
  Verify images are listed in alpha order
  Click on the Name column to reverse the sort.  Verify
  Click in the timestamp column, verify sort
  
* File -> Open
  Select TestTrack.gpx
  Verify track loaded sheet displayed
  Verify track shown on map
  
* View -> Hide disabled files
  Verify disabled files hidden.
  Cmd-D to re-show the file.  Verify.
  Cmd-D again.  Verify files hidden.
  
* Select all (Cmd-A) and Locn From Track (Cmd-L)
  Verify locations updated.
  Verify location for out of date image not updated.
  Verify one image is "most selected"
  Verify the location for that image is shown on the map.

* Select View -> Pin view options -> Show pins for all selected items
  Verify multiple pins on the map
  Verify one pin is red
  Verify other pins have a yellow center.

* Cmd-Click on the most selected item to deselect it.
  Verify some other item becomes most selected
  Verify the red pin changes to show the location of the new most selected.

* Use Cmd-W to close the window.
  Verify an "are you sure" confirmation is shown.
  Click cancel
  Use File -> Discard changes, confirm
  Use GeoTag -> Settings or Cmd-, to open the Settings window.
  Click on the main window.
  Use Cmd-W or File -> Close to close the main window.
  Verify the Settings window is active.
  Use Cmd-W or File -> Close to close the settings window.
  Verify the settings window closes
  Verify the app quit
  
* Launch the application Select Help -> GeoTag 5 Help…
  Verify Browser opens at the GeoTag 5 help pages.  Close browser.
  Open TestData that includes a bad GPX file
  Verify the GPX file loaded sheet shows the bad file
  Dismiss the sheet
  Select File -> Discard tracks.
  Verify the track on the map goes away
  Open only the bad track
  Verify the appropriate sheet is displayed.
  Quit
  
* Prepare a folder of test images without locations
  Add a track log for the images to the folder.
  Launch GeoTag.
  Open Settings window and enable these options:
  - Set File Modification Times
  - Update GPS Date/Time
  - Tag Updated files
  Verify the tag is set to GeoTag
  Change the tag to GeoTagTest.
  Close the window.
  Drag the test folder to GeoTag
  Dismiss the tracks loaded sheet
  Select all (Cmd-A)
  Locn From track (Cmd-L)
  Update location with File -> Save or Cmd-S
  Verify the following:
  - Location coordinates turned from green to black (or white if selected)
  - The backup folder contains copies of the updated images or xmp files.
  - the images that were updated in the prepared folder have a finder tag
    of "GeoTagTest". No tag should have been given to the updated XMP
    file.
  - Verify the timestamp of changed files matches the Date/Time of the
    original file. If there is an XMP file only the timestamp of the XMP
    file will be changed.
  Quit

* Launch GeoTag
  Open settings window
  Verify changes made in the previous test not changed.
  Turn off Tag Updated Files and close window
  Drag the test folder onto GeoTag, again.
  Verify the images have locations assigned.
  Hover the mouse over coordinates.
  Verify an elevation is displayed in the tool tip.
  Select all images and hit the Delete key.
  Verify locations have been removed.
  Save the changes.
  Check the Backups folder.
  Verify that a -1 version of each file saved exists.
  Cycle through the Map Configuration options.
  Verify the map changes.
  Set the configuration to Hybrid.
  Use the map search bar to select some location.
  Verify the search worked.
  Verify the search was added to recent searches (Search bar icon pull down)
  Click the Save map location button to save the current location.
  Quit GeoTag.

* Launch GeoTag
  Verify the configuration and map location are as saved.
  Drag in the test images and track.  Assign locations from the track.
  Select several images. Use cmd-i or click on the info button.
  Verify the inspector opens on the right side of the window.
  Adjust the time by one hour.
  Verify all of the selected images were adjusted by exactly one hour.
  Verify the timestamp is shown in a green font.
  Close the inspector.
  Undo the change.
  Verify the times reverted to their original value and color.
  Select a range of images.
  Turn on Show pins for all selected items
  Use Cmd-C to copy from the the current location.
  Use Cmd-V to paste into all selected locations.
  Verify all items have the same location.
  Verify only 1 red pin is on the map
  Undo the change.
  Verify the locations have been restored
  Verify other pins are on the map.
  Right click on an image.  Select Show in Finder
  Verify a finder window opens with the appropriate image selected.
  Quit GeoTag.  Answer "I,m sure" to the confirmation dialog.

* Launch GeoTag
  Open settings window and check the Disable paired jpeg option
  Use View -> Show/Hide Disabled Files to show disabled files
  Drag in images that includes a raw/jpeg pair
  Verify the Jpeg is disabled
  Use View -> Show/Hide Disabled Files to show and hide the file
  Assign a location to one image.
  Usd Cmd-X to cut the location from the image.
  Select two other images and use Cmd-V
  Verify the image locations are updated.
  Verify there is a pin on the map at the desired location.

* Select Edit -> Specify Time Zone
  Verify the Specify Camera Time Zone window opens
  Select a time zone other than the current time zone.
  Click on the Change button.
  Select Edit -> Specify Time Zone again
  Verify the "current" value is the value selected above.
  Quit GeoTag

* Launch GeoTag.
  Drag in a large number (> 1000) images. [photos/year/2024]
  Note the time it takes to load images
  - about 8-9 seconds for the table to start being populated,
  - about 16-17 seconds for the load to complete
  Select an image.  Note the time it takes before the image
  thumbnail is displayed
  - Very quick for jpeg
  - slightly longer for DNGs, but still fairly quick
  Quit GeoTag

* Launch GeoTag
  Drag in TestData
  Dismiss track log sheet
  Select an image and verify the thumbnail loads
  Use View -> Alternate layout
  - Verify the thumbnail moved below the table of images
  - Verify the right pane contains only the map and map search bar
  Quit GeoTag

Remove test configuration with
defaults delete org.snafu.GeoTag

