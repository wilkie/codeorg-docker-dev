# Code<span>.org Docker Dev Environment

The Code<span>.org Docker dev environment enables you to develop on the Code<span>.org platform using Docker containers.

Doing so offers many advantages over a development environment directly on your laptop. These include:

- No need to worry about managing dependencies (e.g., setting up rbenv, managing versions of Ruby, or removing/installing Ruby gems).
- Rebuilding your development environment is scripted, which makes it easy to test new changes and roll them back, such as a new version of a Ruby gem or even a new version of MySQL. 
- It's easier to have multiple versions of the Code<span>.org dev environment and database on the same machine.
- A docker-based development environment works better for Code<span>.org volunteers, who may not want to install a bunch of our dependencies directly on their employer-provided machines.
- The docker-based environment uses Ubuntu, which mimics our production environment (and reduces the chance of things working on your laptop, but not on our production servers).
- When you are not developing, you can pause/stop the dev containers which frees up more resources on your machine.
- Rebuilding a container is a lot easier than rebuilding your laptop!

## How does it work?

The Code<span>.org Docker dev environment uses docker compose to create two containers: web and db. 

The web container runs all of the code required for dashboard and pegasus. All of the source code is stored on the host laptop under the "src" sub-directory.

The db container runs the same version of MySQL as production. All of the data files for MySQL are stored on the host laptop using the "data" sub-directory.

Docker networking provides a connection between the two containers. Much of this is handled internally. For instance, the db container exposes port 3306 for MySQL access to the web container.

<img src="./containers.png" width=400>

## Pre-requisite: Docker Desktop

The only pre-requisite you need on your host laptop is Docker desktop.  If you don't have it already installed and running, you can download it [here](https://www.docker.com/products/docker-desktop/). 

If you are on a Linux machine, you can follow the instructions [here](https://docs.docker.com/desktop/install/linux-install/).

Also, ensure you can run Docker as a non-root user, following [these instructions](https://docs.docker.com/engine/install/linux-postinstall/).

You will need to ensure that `docker compose` is usable in your install.
Occasionally the `compose` features are installed separately.
The `cdo` script can install this as a plugin for an existing Docker install via `cdo install:docker-compose`.

The `cdo` script will be able to address some simple issues and give more information as needed.

Note: This repo has been tested using Docker versions as low as 20.10.17 and as new as 24.0.6.

## Step 1: The `cdo` command and Setup

All functions you may wish to apply to the code-dot-org project are encapsulated neatly in the provided "`cdo`" binary.
To use, simply try poking around its own documentation:

```
# In the base directory
./cdo
```

And to get a listing of commands:

```
./cdo help
```

And help on a specific command:

```
./cdo help init
```

To put our directory in your `PATH` and simply use `cdo` wherever, run the `init` command:

```
./cdo init
```

Now you can, from any point in the repository space, just run the `cdo` command.

## Step 2: Full development setup

Run the setup command to build the containers and install the libraries.

```
cdo setup
```

## Optional: Configure AWS credentials (Code.org Engineers/Contributers Only)

For code.org developers, special access and logging is done via their AWS credentials.

You do not need AWS access to contribute to the codebase. By default, the install step
will write a configuration that assumes you do not have any access. However, you may
go through the process of generating your credentials anyway.

- Refer to these instructions [here](https://docs.google.com/document/d/1dDfEOhyyNYI2zIv4LI--ErJj6OVEJopFLqPxcI0RXOA/edit#heading=h.nbv3dv2smmks).
- Place the `config` file for the container in the file `aws/config`
- Generate an authentication token using `cdo aws:authenticate`
- A Firefox window should pop up (or you are instructed to point a VNC client to a port)
- Confirm your google authentication.
- Confirm the script tells you your ARN.

## Step 3: Running tests

To run pegasus tests (Optionally, supply a file from the pegasus/test directory):

```
cdo test:pegasus
cdo test:pegasus test_forms.rb
```

To run dashboard unit tests (Optionally, supply a file from the dashboard/test directory):

```
cdo test:unit
cdo test:unit models/lessons_standard_test.rb
```

To run dashboard UI tests (Optionally, supply a file from the dashboard/test/ui directory):

```
cdo test:ui
cdo test:ui foundations/header.feature
```

To run JavaScript unit tests (Optionally, supply a file from the apps/test directory):

```
cdo test:js
cdo test:js unit/templates/rubrics/LearningGoalTest.jsx
```

## Development

### Committing / Linting

The best practice for committing is to ensure that the linting hooks run. To do that, add files to stage the commit and then do `git commit -v` to commit the staged content (and `-v` to see the content that you are actually committing so you write a good commit message).

The hooks will perform all the linting passes for all the files currently modified in the index.

To run the lint process manually, you can use the various `cdo lint` commands.

Let's say the `git commit` failed due to a React component failing a lint check:

```
/app/src/apps/src/templates/rubrics/RubricContainer.jsx
  65:6  error  React Hook useEffect has a missing dependency: 'getTeacherFeedback'. Either include it or remove the dependency array  react-hooks/exhaustive-deps
```

Ok, let's run that lint pass which should reproduce that error:

```
cdo lint:js src/templates/rubrics/RubricContainer.jsx
```

We can attempt to have it automatically fix any style conventions using the `--fix` argument:

```
cdo lint:js src/templates/rubrics/RubricContainer.jsx --fix
```

For errors in stylesheets found within React component sources:

```
src/templates/rubrics/rubrics.module.scss
 114:14  ✖  Expected quotes around "checkbox"  selector-attribute-quotes
```

We can do a similar set of things, including using the `--fix` argument:

```
cdo lint:styles src/templates/rubrics/rubrics.module.scss --fix
```

When the linting pass succeeds, you can then commit the change.

### Maintenance

When you check out new changes, you can run the blanket `install` command to perform any necessary migrations and library installs:

```
cdo install
```

That's usually all one needs to do, but you can follow that with a full build as well to be sure:

```
cdo build
```

### Installing new gems

When you edit the `Gemfile` within the repository directory (e.g. `./src/Gemfile`), run the `cdo install:gems` command.

### Enabling Backend Experiments

Experiments are triggered via the `DCDO` `experiment_value` system.
Here, the `experiment_value` function looks for the tag to exist within the request itself or if it is set broadly as a `DCDO` variable.

To set such a variable, just use `cdo dcdo:set`:

```
cdo dcdo:set gender 1
```

This enables the 'gender' experiment by giving it a truthy value.

You can see what variables are set via the `dcdo:list` command which outputs a JSON dictionary with all set variables:

```
cdo dcdo:list

{
  "gender": 1
}
```

## Optional: Run/Debug Dashboard and Pegasus (RubyMine)

To setup the remote Ruby SDK:

- Start containers, if they are not running, using `cdo server` or manually via `docker compose up`.
- From RubyMine, open the "./src" folder. Ignore the "missing gem dependencies" messages when RubyMine first starts.
- Wait until file indexing completes, then right click on the ./src/dashboard folder in the project pane and select "Mark Directory as... Ruby Project Root"
- In RubyMine, go into preferences and navigate to the "Ruby SDK and Gems" settings.
- Click on the + button to create a new configuration and select "Remote Interpreter or Version Manager".
- Select the Docker Compose (not Docker!) radio button, point to the docker compose yml file (in the codeorg-docker-dev dir), and select the "web" as the image name. For the ruby path, enter "/home/cdodev/.rbenv/versions/2.6.6/bin/ruby".
- Click OK to create the remote Ruby SDK. RubyMine will list and synchronize the gems from the container.
- Click on the "Edit Path Mappings" icon. Create a new path mapping. Local src folder should map to "/app/src" on the container.
- Ensure that the "Remote: ruby" configuration is the default and click OK to exit preferences.
- RubyMine will now download and index the gems, which will take a few minutes to complete.
- Once complete, you will be able to navigate around the code base.

To create a new run/debug configuration:

- Create a new Rails run/debug configuration (or edit the current one if auto-created).
- In the rails configuration, make sure the "Thin" server is selected".
- **Optional**: If you have AWS access, add the environment variable, `AWS_PROFILE=cdo`
- Select "Use other SDK" and select the Remote SDK from the container.
- Select docker-compose exec as the attach method (RubyMine will attach to the running container instead of creating a new one)
- Click on Run or Debug to start Dashboard. Browse to http://localhost:3000. Any breakpoints hit will drop back to the IDE.

To run the rails console from within RubyMine:

- Select Run Rails Console...
- If the console fails, edit the newly created rails console configuration and, if you have AWS access, add the `AWS_PROFILE=cdo` environment var.

## Optional: Run/Debug Dashboard and Pegasus (VS Code)

- Start containers, if they are not running, using `cdo server` or manually using `docker compose up`
- Ensure the [Docker extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker) is installed.
- Click on the Docker icon in the sidebar and locate the "Containers" panel.
- Right click on the "codeorg-docker-dev-web" container and select "Attach Visual Studio Code". This will open a new VS Code Window, attached to the docker container.
- If it is not already installed, add the [Ruby language extension](https://marketplace.visualstudio.com/items?itemName=rebornix.Ruby) to the remote VS Code instance.
- Create a new run/launch configuration using the following: 

```
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Dashboard",
      "type": "Ruby",
      "request": "launch",
      "program": "/home/cdodev/.rbenv/versions/3.0.5/bin/bundle",
      "args": ["exec", "thin", "start", "-a", "0.0.0.0", "-p", "3000"],
      "useBundler": true,
      "showDebuggerOutput": true,
      "cwd":"${workspaceRoot}/dashboard"
    }
  ]
}
```

- Click on the run "Debug Dashboard" button (or press F5) to start debugging.
- Set breakpoints in your code and browse to http://localhost:3000.

## Optional: Run/Debug Dashboard and Pegasus in a container running on a remote Linux host (VS Code)

Ensure that you can ssh into the remote host and it has Docker installed.

- Follow steps 1-3 above to copy the codedotorg-docker-repo to the remote host and start the containers.
- Install the Remote-SSH VS Code extension
- CTRL-Alt-P and Remote-SSH: Connect to host
- username@host:port (e.g., simon@remote:22)
- Once connected, follow the instructions as per above section (Run/Debug Dashboard and Pegasus using VS Code).

## Optional: Speeding up zsh access to the ./src directory

If you are using [zsh](https://ohmyz.sh/), you may find your terminal is slow when in the ./src directory. This is due to the size of our repository and how zsh displays git info in it's prompt.

To disable git info in the prompt (and speed up the terminal), run the following command from the ./src directory:

- `git config oh-my-zsh.hide-info 1`

## FAQ

### Q: If I delete the containers, does it delete any data?

No, all data resides on the host laptop and is mounted by the containers when they start. Source is kept in the ./src folder. MySQL database files are kept in the ./.mysql-data folder. MinIO (S3) data is kept in the `./minio...` paths. The installed ruby gems are in `./rbenv` and a copy of the installed nvm packages are in `./nvm`.

You can have it reset some of this data using the various `cdo reset` commands.

### Q: Does my IDE run in a container?

No, your IDE runs on your host laptop as normal.

### Q: Where do I set my IDE to point to?

Use your preferred IDE to open the ./src folder - just as you would if you were developing on your host laptop. As this is a mounted volume in the web container, any changes are reflected immediately.

### Q: Can I pause containers?

Yes, you can use pause and unpause commands with Docker compose:

```
docker compose pause|unpause
```

### Q: How do I rebuild my database?

First, you can backup the existing database by copying the `./.mysql-data` directory. This is the persisted data for the `db` container.

You can drop the database with `cdo reset:db` and then run the `cdo seed` step or, more thoroughly and so to include migrations, the `cdo build` step.

All of the MySQL database files are held in the `./mysql-data` directory. To rebuild the database from scratch, simply delete this folder, restart the containers, and run the seeding step again via `cdo build`.

### Q: I need to install a new Gem. How do I do this?

Edit src/Gemfile and then run the `cdo install:gems` step. More thoroughly, run the `cdo install:ruby` step which also performs a `rake install` and a reseeding of the test database.

### Q: Is using Docker slower than developing on my laptop?

There should be little noticeable performance difference between developing using Docker and on your host laptop. Older versions of Docker used to have performance issues when mounting large volumes, but this has since been resolved with VirtioFS.

### Q: Do I need to install Ruby and/or MySQL on my host laptop?

No! The only required dependency on the host laptop is Docker desktop. The script can also install the appropriate version of Docker Compose for you via `cdo install:docker-compose`.

### Q: Does this work on Windows-based PCs?

It should, but this README needs to include the Windows-equivalent commands and/or how this would work with WSL. PRs welcome :)

### Q: Does this work for M1-based Macs?

Yes, the dev environment works for both x86 and ARM64-based machines.

### Q: Does this work for Linux-based PCs?

Yes. These instructions will also work for Linux-based server images (such as an EC2 instance running in AWS).
