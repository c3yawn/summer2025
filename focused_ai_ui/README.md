# Getting Started
* Open the [EduLense Deployment & Operations Guide](https://umgc-cappms.azurewebsites.net/download/162f237e-ca87-476e-922f-9a5bdfe98627----EduLense%20Deployment%20and%20Operations%20Guide%20M4.pdf)
* Install Flutter (Section 3.3)
* Install Android Studio (Section 3.4)
* Install the Flutter extension for VS Code (this should also automatically install the Dart extension but if not, install that too)

# To run the app
Change directory to pubspec.yaml `cd "C:\Users\jmsna\OneDrive\Desktop\UMGC Summer 2025\SWEN 670\summer2025\focused_ai_ui"`
Must run with port `3000` or `5000` to satisfy CORS error: `flutter run -d chrome --web-port 3000`

# To commit changes
* In the CLI, change to your root directory (vscode terminal puts you there by default)
* Type `git status` to see all modified files.
* To add a file to staging (prepare it for a commit) type `git add {filepath}` where filepath is the path of whatever file you want to stage. (e.g., .\docker_resources\javascript_dockerfile\). If you type out the first few letters of the filepath and press the tab button it will automatically put the full path for you (as long as there are not other files with the same starting letters).
* To add all files at once to staging type `git add .`
* If you want to remove a file from staging, type in `git restore --staged [file]`.
* Once all the changes you want to commit are staged, you can type `git status` again to make sure all the files you want are staged (will be in green)
* To commit the files, type in `git commit -m ""` (put in a message in between the quotes related to the changes you made. For example, `git commit -m "added javascript capability"`)
* To push the commits to the github repository, type in `git push -u origin {branch name}` (where {branch name} is replaced with where you want to push the changes. For example, `git push -u origin team-c/code-compiler`). Once you have pushed something to the branch, all future pushes can be done with just `git push`
