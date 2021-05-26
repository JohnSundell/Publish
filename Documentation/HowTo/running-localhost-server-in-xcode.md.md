#  Running localhost server in Xcode

If you haven't already open package containing your website in Xcode.
You can do it by either running `open Package.swift` in terminal or double clicking `Package.swift` in Finder.

After Xcode fetches all package dependencies you should see the default build sheme.
(It's the name of your website right to the run button on the toolbar.)

## Creating run scheme

1. Click the build scheme and select "Edit scheme..." from the dropdown.
2. Small window will appear. In it click "Duplicate Scheme" and select name for your run scheme, for example "Run [nameOfYourPage]"
3. From left pane select Run
4. Change the executable to `publish-cli`
5. Then in Arguments tab add `run` to "Arguments Passed on launch"
6. Lastly in Options tab check "Use custom working directory:" option and select folder containing your `Package.swift` file
7. Click "Close" to close the small window

Now you can run your project (`Cmd+R` or press Run button on the toolbar) and your website will be built and served locally.

## Going back to publishing

Because we didn't delete the original build scheme you can select it from the dropdown by clicking the name of your run scheme and selecting the original one.

## Changing the port

Because baisicly we are just running `publish run` in more complicated way, we can of course change the port on which the website is served.

To do this change `run` from step 5 to `run -p PORT` (eg. `run -p 1337`).
Or add `-p PORT` as another argument passed on launch.
