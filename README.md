# iRODS Development Environment

This repository contains tools for the running and troubleshooting of a Docker-containerized iRODS server.

The [irods_testing_environment](https://github.com/irods/irods_testing_environment) can be used to test the packages produced by this repository.

## Contents of this Guide
   1. [General Setup](#general-setup)
      1. [Prerequisites](#prerequisites)
      1. [How to Build](#how-to-build-eg-ubuntu-16)
      1. [How to Run](#how-to-run-eg-ubuntu-16)
      1. [How to Develop](#how-to-develop-eg-ubuntu-16)
   1. [Simplified Setup](#simplified-setup)
   1. [Debugging](#debugging)
      1. [`gdb`](#gdb)
      1. [`rr`](#rr)
      1. [`valgrind`](#valgrind)
      1. [`scan-build`](#scan-build)
      1. ( `cppcheck`, ... ?)
---

## General Setup

### Prerequisites

1. Create custom paths.
```
$ git clone https://github.com/irods/irods_development_environment.git /full/path/to/irods_development_environment_repository_clone
$ git clone --recursive https://github.com/irods/irods.git /full/path/to/irods_repository_clone
$ git clone https://github.com/irods/irods_client_icommands.git /full/path/to/icommands_repository_clone
```
2. Make 3 directories on host machine for docker volume mounts:
```
$ mkdir /full/path/to/irods_build_output_dir
$ mkdir /full/path/to/icommands_build_output_dir
$ mkdir /full/path/to/packages_output_dir
```
Note: It may be useful to keep separate build directories across OS flavors and iRODS branches in order to ensure correctness of builds.

3. Build the Docker images:
```
$ cd /full/path/to/irods_development_environment_repository_clone
$ docker build -f irods_core_builder.centos7.Dockerfile -t irods-core-builder-centos7 .
$ docker build -f irods_core_builder.ubuntu16.Dockerfile -t irods-core-builder-ubuntu16 .
$ docker build -f irods_core_builder.ubuntu18.Dockerfile -t irods-core-builder-ubuntu18 .
$ docker build -f irods_core_builder.ubuntu20.Dockerfile -t irods-core-builder-m:ubuntu-20.04 .
$ docker build -f irods_core_builder.debian11.Dockerfile -t irods-core-builder-m:debian-11 .
$ docker build -f irods_runner.centos7.Dockerfile -t irods-runner-centos7 .
$ docker build -f irods_runner.ubuntu16.Dockerfile -t irods-runner-ubuntu16 .
$ docker build -f irods_runner.ubuntu18.Dockerfile -t irods-runner-ubuntu18 .
```

### How to build (e.g. Ubuntu 16)
1. Run iRODS builder container:
```
$ docker run --rm \
             -v /full/path/to/irods_repository_clone:/irods_source:ro \
             -v /full/path/to/irods_build_output_dir:/irods_build \
             -v /full/path/to/icommands_repository_clone:/icommands_source:ro \
             -v /full/path/to/icommands_build_output_dir:/icommands_build \
             -v /full/path/to/packages_output_dir:/irods_packages \
             irods-core-builder-ubuntu16
```

Usage notes (available by running the above docker container with -h):
```
Builds iRODS repository, installs the dev/runtime packages, and then builds iCommands

Available options:

    --core-only             Only builds the core
    -C, --ccache            Enables ccache for rapid subsequent builds
    -d, --debug             Build with symbols for debugging
    -j, --jobs              Number of jobs for make tool
    -N, --ninja             Use ninja builder as the make tool
    --exclude-unit-tests    Indicates that iRODS unit tests should not be built
    --exclude-microservice-tests
                            Indicates that iRODS tests implemented as microservices
                            should not be built
    --custom-externals      Path to custom externals packages received via volume mount
    -h, --help              This message
```
The `--custom-externals` option allows you to specify a location in the builder container where there are built iRODS externals. This is useful if the platform does not have built externals available in the RENCI repositories or when trying out a modification to the externals. To do this, use a volume mount when running the docker container and specify the mount name with this option (i.e. the path inside the container).

The `--ccache` option allows you to utilize `ccache` in the build process, speeding up subsequent builds of icommands and the iRODS server. Using this option requires the use of an additional volume mount to the `/irods_build_cache` directory, an abbreviated example is as follows:
```
$ docker run --rm \
             ...  \
             -v /full/path/to/build_cache_dir:/irods_build_cache \
             irods-core-builder-ubuntu16 --ccache
```

### How to run (e.g. Ubuntu 16)
1. Run iRODS Runner container:
```
$ docker run -d --name irods-runner-ubuntu16_whatever \
             -v /full/path/to/packages_output_dir:/irods_packages:ro \
             irods-runner-ubuntu16
```
2. Open a shell inside the running container:
```
$ docker exec -it irods-runner-ubuntu16_whatever /bin/bash
```
Note: iRODS and iCommands are not installed out of the box, nor is the ICAT database prepared.
The usual steps of an initial iRODS installation must be followed on first-time installation.

### How to develop (e.g. Ubuntu 16)
1. Edit iRODS/iCommands source files...
2. Build iRODS and iCommands (see "How to build")
3. Install packages of interest on iRODS Runner (inside iRODS Runner container):
```
root@19b35a476e2d:/# dpkg -i /irods_packages/irods-{package_name(s)}.deb
```
4. Test your changes
5. Rinse and repeat

It is encouraged to build your own wrapper script with your commonly used volume mounts to make this process easier.

---

## Simplified Setup

If coming to iRODS for the first time, a more automated approach will do for an introduction:

1. Into a new or initially empty directory, clone this repository:
```
$ mkdir ~/dev_root
$ cd ~/dev_root ; git clone https://github.com/irods/irods_development_environment
```

2. Also clone the source code repos from which to build:
```
$ git clone --recursive https://github.com/irods/irods
$ git clone https://github.com/irods/irods_client_icommands
```

3. Create binary and package output directories:
```
$ mkdir irods_build_output icommands_build_output irods_package_output
```

4. Now we can build and run model setup, using the source and output directories just created.
```
$ cd irods_development_environment
$ ./run_debugger.sh -d .. -V volumes.include.sh --debug
```

5.  This will build a docker image suitable for
   - *initially* running an iRODS server (an old version) installed from the iRODS internet repo
   - upgrading from there to a just-built iRODS server, eg. built from source
   - leveraging debugging tools (currently `gdb`, `rr`, and `valgrind`) against the running iRODS server
     (if we used `--debug` as in the previous step)

6. These are possible informative but otherwise no-op invocations of `run_debugger.sh` :
   - Explain usage:
   ```
   $ ./run_debugger.sh -h
   ```
   - Print out settings but do nothing.
   ```
   $ ./run_debugger.sh  -V volumes.include.sh -d .. --dry-run
   ```
7. Notes
  - When rebuilding, esp for another platform (-p), it may be necessary to clear the binary output directories
    ```
      $ sudo cp -rp  ~/dev_root ~/dev_root.ubuntu16.4-2-stable  # (optionally preserve previous work)
      $ sudo rm -fr ~/dev_root/*_output/* ~/dev_root/*_output/.ninja*
    ```

---

## Debugging

In the run/debug container created by the [simplified](#simplified-setup) procedure, placing `/opt/debug_tools/bin`
at the head of the PATH environment variable will cause the shell to invoke updated versions executables of
`gdb`, `rr`, and `valgrind`.  These can be necessary when debugging symbols are larger than what the tool binaries at
the default install paths can handle.

The system calls necessary for `gdb` and `rr` to function properly on the Linux host necessitate:
   - `/proc/sys/kernel/yama/ptrace_scope` no higher than 0
   - `/proc/sys/kernel/perf_event_paranoid` no higher than 1
   
These can be changed by editing the config files under `/etc/sysctl.*` and reloaded via `sysctl --system`.
Doing this on the host machine should be effective for all containerized `gdb`/`rr` runs as well.

### gdb

Start a debugger container.

 - In terminal #1, as iRODS service account:
    - pkill irodsReServer (prevent API's being invoked from delay server)
    - attach to irods server
    ```
    gdb -p PID
    ```

    with PID = the parent (not grandparent) irodsServer process

    parent PID usually = 1 + grandparent PID

    - Inside the GDB console:
    ```
    set follow-fork-mode child
    b rsApiHandler
    c
    ```

 - In terminal #2:

    run the client to invoke the API

### rr

   - [rr](http://github.com/mozilla/rr) is a GDB work-a-like which
      * records the target process being run and allows replay (a "deterministic run") of that record
      * can therefore capture an error and allow the developer step forward and backward through any of
        the captured PIDs

   - `rr` can be used within graphical environments like [gdbgui](https://gdbgui.com/)
      * gdbgui is easy to [install](https://github.com/cs01/gdbgui/blob/master/docs/INSTALLATION.md)

   - instructional links on

      * [building and installing](https://github.com/mozilla/rr/wiki/Building-And-Installing)
      * [using RR under docker](https://github.com/mozilla/rr/wiki/Docker)

   - basic usage under iRODS:
      - install an iRODS server with debug symbols compiled in.
         (*Can insert **rodsLog(LOG_NOTICE,"...%s..",arg,...)** calls to help ascertaining relevant PID later)*
      - as iRODS, do: `~/irodsctl stop`
      - then, also as iRODS: `cd /usr/sbin ; rr record -w /usr/sbin/irodsServer`
      - (as any user) perform the operations requiring troubleshooting
      - again as iRODS, do: `~/irodsctl stop`
      then:
      ```
      rr ps
      rr replay -p <PID> # or if forked without exec, then "-f <PID>"
      ```

### valgrind

```
# as service account
ubuntu:~$ su - irods
$ cd /var/lib/irods ; ./irodsctl stop
$ cd ..         # Because iRODS can't find the server log otherwise
```
Sample command line:
```
$ valgrind --tool=memcheck --leak-check=full --trace-children=yes \
      --num-callers=200 --time-stamp=yes --track-origins=yes \
      --keep-stacktraces=alloc-and-free --freelist-vol=10000000000 \
      --log-file=$HOME/valgrind_out_%p.txt /usr/sbin/irodsServer
```
Then everything that happens in irodsServer will be valgrinded.
```
#  ps -ef | grep valgrind -> yields PID(s); valgrind hides the process name
```
Other valgrind notes
   - can kill valgrind/iRODS processes with `pkill valgrind`
   - between server runs, be sure to `rm -fr /dev/shm/irods*`


### scan-build

The clang static analyzer can be used when building iRODS.

 - Setup environment:

   ```
   export PATH=/opt/irods-externals/cmake3.11.4-0/bin:$PATH
   export PATH=/opt/irods-externals/clang6.0-0/bin:$PATH
   export CCC_CC=clang
   export CCC_CXX=clang++

 - Build with static analyzer:

   ```
   cmake -DCLANG_STATIC_ANALYZER=ON ..
   scan-build make -j
   ```

   or

   ```
   cmake -DCLANG_STATIC_ANALYZER=ON -GNinja ..
   scan-build ninja
   ```

## How to Build an iRODS Plugin

The plugin builder functions very similarly to the core builder.

In addition to the build and package volume mounts, there also needs to be a volume mount for iRODS core packages (i.e. irods-dev and irods-runtime) so that the plugin can install dependencies.

Build the plugin builder like this (use whatever image tag that you wish):
```bash
docker build -f plugin_builder.ubuntu16.Dockerfile -t irods-plugin-builder:ubuntu-16.04 .
docker build -f plugin_builder.ubuntu18.Dockerfile -t irods-plugin-builder:ubuntu-18.04 .
docker build -f plugin_builder.centos7.Dockerfile -t irods-plugin-builder:centos-7 .
```

And run the plugin builder like this, e.g. ubuntu:16.04:
```bash
docker run --rm \
           -v /full/path/to/irods_plugin_repository_clone:/irods_plugin_source \
           -v /full/path/to/plugin_build_output_dir:/irods_plugin_build \
           -v /full/path/to/plugin_packages_output_dir:/irods_plugin_packages \
           -v /full/path/to/built_irods_packages_dir:/irods_packages \
           irods-plugin-builder:ubuntu-16.04 --build_directory /irods_plugin_build
```

## How to Build iRODS externals

The externals builder builds externals packages which are needed to build iRODS and its affiliated plugins.

Build the externals builder like this (use whatever image tag that you wish):
```bash
docker build -f externals_builder.<platform>.Dockerfile -t irods-externals-builder-m:<platform> .
```

Run the externals builder like this:
```bash
docker run --rm \
           -v /full/path/to/externals/packages/output/directory:/irods_externals_packages \
           irods-externals-builder-m:<platform>
```

Usage notes:
```bash
Builds iRODS externals and copies the packages to a volume mount (/irods_externals_packages)

Available options:

    --git-repository    URL or full path to the externals repository in the container (default: https://github.com/irods/externals)
    -b, --branch        Branch to build in git repository (default: main)
    -t, --make-target   The Make target to build (default: all)
    -h, --help          This message
```
The `server` make target is all that is required to build iRODS core, but plugins require other externals. See [https://github.com/irods/externals](https://github.com/irods/externals) for more information.

The `--git-repository` option allows for one of two options:
  1. A URL to a git repository which can be cloned into the container.
  2. A path to a directory inside the container which mounts an existing repository on the host machine.

Option 2 is useful for those who would like to keep a build cache on the host machine. Here is what that usage would look like:
```bash
docker run --rm \
           -v /full/path/to/externals/packages/output/directory:/irods_externals_packages \
           -v /full/path/to/externals/repository:/externals-mount \
           irods-externals-builder-m:<platform> --git-repository /externals-mount
```
The name of the mountpoint does not need to be "externals-mount". All that matters is that the name of the mountpoint is the same as what is used for the value of the `--git-repository` option.
