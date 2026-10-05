( [RU](./README-RU.md) )
( [DE](./README-DE.md) )
---
# Comtact Small Web Service

## Licensing.

Everything is distributed under the MIT license. Use of the application is at your own risk. The developer bears no responsibility whatsoever. Full or partial modification of the code is possible at your discretion. It is desirable to include a link to the original repository.

## Purpose.

The server is designed for minimal system management based on computing systems with limited resources, such as single-board computers. For example, in "Smart home" control systems, technological tools built on the basis of ARM, x86. Or as an additional means of virtual hosting. The server is a lightweight script processor for text files with the ability to run shell processes and stream the output to a browser. It can operate as a standalone application or as a service. Interaction with the Linux operating system.

## Installation and Launch Methods.

The program can be launched as a third-party application, or integrated as a systemd service. During operation, a configuration file is created, which can be located either in the user directory or in /etc. It is also possible (but not mandatory) to place a directory with additional HTML, JavaScript, and shell scripts.

## Code Compilation Method.

The application was created in Free Pascal in the Lazarus environment with cross-compilation capability. For convenient installation, FPCUpDelux was used, which automatically installs the entire environment and cross-compilation tools for various platforms.

---

### 1. Description of the Main Page and Script Interaction Principle

The main page can be reconfigured to use a different interface, but here we explain how the scripts interact with each other.  
The main page consists of a fixed panel with a menu button and a client area where the results of the executed scripts are displayed.  
The client area is implemented using an `<iframe>` element. The main page contains several JavaScript helper functions.  

When the menu button is clicked, the `loadMenu()` function sends an asynchronous AJAX request to the server. Upon receiving a response, it builds a tree of menu items and displays it to the user.  

When a menu item is selected, JavaScript changes the `src` property of the `contentFrame` (iFrame) element to the value corresponding to the selected menu item. This way, the content of the new request is displayed inside the frame.  

Another helper function is `requestServer(URL)`. It performs an asynchronous request to the server and returns the result. It can be used to add new variables to the server, modify menu items, and perform other actions.  

#### 1.1. Internal Server URLs

##### 1.1.1. `/shell`
Executes a command passed in the `cmd` parameter. Implemented in the `shell.thtml` file.  
Example: `/shell?cmd=python myscript.py`  

##### 1.1.2. `/menulist`
Returns a list of menu items and their commands. By default, they are read from the configuration file, but they can be modified using the `/menu` request sent asynchronously by the `requestServer()` function.  

##### 1.1.3. `/menu`
Allows managing the menu:  
- `/menu?clear` — clears the list;  
- `/menu?default` — restores the list from the configuration file;  
- `/menu?captionX=My caption in menu X&cmdX=my URL` — modifies or adds a menu item with the specified caption and URL.  
All commands can be combined in a single request. They are executed in the order specified in the URL.  

##### 1.1.4. `/envvar`
Adds a new variable and its value for use in templates.  
Example: `/envvar?myvar=My value` — the variable can be referenced in the template as `$(myvar)`.  

##### 1.1.5. `/stop`
Stops listening on the port and terminates the application.  

##### 1.1.6. `/shellresponse`
Returns all unread data from the output stream after executing a command via `/shell`. If no command is running, a 404 error code is returned.  

##### 1.1.7. `/shellrun`
Returns a 200 code if a command was launched via `/shell`. Otherwise, it returns a 404 code.  

### 2. Description of the Configuration File

#### 2.1. `Application` Section

##### 2.1.1. `Port` Parameter
Specifies the port on which the server will listen for requests. The default is 8080. When changing the port, ensure firewall access is configured. For example, using the `ufw` utility:  
```bash
sudo ufw allow 8080/tcp
```

##### 2.1.2. `RootPath` Parameter
Contains the path to the directory with the templates for requested pages. The default is `/var/techtool/thtml/`, but any other directory can be used for debugging.  

##### 2.1.3. `RootFileName` Parameter
Specifies the name of the template file to be used when the URL `/` is called.  

##### 2.1.4. `WorkDir` Parameter
Contains the path to the folder for temporary files, such as logs. The default is `/tmp`.  

#### 2.2. `MENU[X]` Section
The number in the section name is mandatory and must be unique.  

##### 2.2.1. `MenuCaption` Parameter
Contains the text displayed to the user in the menu.  

##### 2.2.2. `MenuCommand` Parameter
Contains the URL of the page to be called (see URL description).  

### 3. URL Processing

When specifying a script name with or without an extension, the server searches for the file in the path specified in the configuration file (`APPLICATION.RootPath`). If the file is not found, the browser receives a 404 response.  

When a page is requested, the server performs the following substitutions:  

#### 3.1. Configuration Variables
In the script, specify the section name and parameter (without a separator) in uppercase.  
For example: `$(APPLICATIONPORT)`  

#### 3.2. Environment Variables
In the script, specify the variable name with case sensitivity.  
For example: `$(SHELL)`  

#### 3.3. Variables Defined by the Developer During Shell Execution
The conditions are the same as for environment variables.  

### 4. Debugging Scripts with CSWS

This directory contains three pre-compiled versions of the program, designed for different platforms:

- **`aarch64-linux`** — version for Raspberry Pi devices;
- **`x86_64-win64`** — version for 64-bit Windows systems;
- **`x86_64-linux`** — version for 64-bit Linux systems.

Launching the application with a separate configuration file allows for flexible customization of parameters and templates, making it easier to debug scripts. This enables testing their functionality directly in a browser without the need to make changes on the Raspberry Pi device.

#### 4.1. Command Line Parameters

The program supports the following command-line parameters:

- **`--conf="my.conf"`**  
  Launches the program using the specified configuration file. This allows for the use of custom settings and templates.

- **`--stop`**  
  Stops the program if it is already running.

- **`--envvar`**  
  Displays a list of all environment variables available to the program.

- **`--addmenu="<menu caption>:=:<command>"`**  
  Adds a new menu section to the configuration file.  
  - `<menu caption>` — the menu title;  
  - `<command>` — the command associated with this menu item.

