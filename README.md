**mm** is a machinectl/systemd-nspawn manager

**mmbuild** is a container creator for nspawn using debootstrap (tested with debian and ubuntu, others may work too)

# install
install mm and mmbuild to /usr/local/bin
```bash
git clone https://github.com/badrelmers/mm
bash ./mm/install.sh
```

# How it works
all containers need to be saved somewhere, so I choosed to create a config file `/etc/_mm.conf` where we will save the path to the folders we want to use as a repository for the containers, I could have used the default machinectl folder `/var/lib/machines` but I prefer my method because like this I can format any time without problems, because `mm` will create a symlink from my defined repository to `/var/lib/machines`, like this you do not have to take care of moving the containers before formating the disks. another benefit is that we can use diferent disks to save the containers.
that is why I created the command `mm register ContainerName` which will create a symlink of the container inside `/var/lib/machines`

by default the created container will run with full privileges using the host networking. to run the container unprivileged or with more privilges or with a diferent network mode, then you have to read the content of `mm edit ContainerName` , understand it and edit it as needed. you can choose between priviliged (default), unprivileged or super privileged mode, and between bridged, NAT or host network (default).

TODO: add commands to change between privileged/unprivilged, and to change between host/nat/bridge network

# example 1:
```bash
# create a folder which will be used as the repository for nspawn containers and 
# add it to /etc/_mm.conf so it can be controlled by mm (you can create multiple
# folders in diferent disks to be as repository)
repository=/media/ssd2/_MyNspawnStore
grep -Fq "${repository}" /etc/_mm.conf || { echo "${repository}" | sudo tee -a /etc/_mm.conf ; }

# build an nspawn container
mmbuild   buster20210225124857     buster20210225124857     debian   buster       bbbbbbnn

# run the container and open a shell inside it
mm run buster20210225124857
# to exit do
ctrl-c

# list running containers
mm
# list registred containers with machinectl
mm ls
# list all containers (registred and not registred with machinectl)
mm lsa
```

# example 2:
```bash
# clone, rename, register a container,  then delete it
mm clone buster20210225124857
mm rename buster20210225124857-clone...  mybustercontainer
mm register mybustercontainer
mm run mybustercontainer

# delete it
mm stop mybustercontainer
mm delete mybustercontainer
```

# help
```bash
mm help
mmbuild help
```

## mm help
```
    run NAME                Start container as a service and connect to it
    start NAMEs...          Start container as a service (start)
    sh NAME                 Invoke a shell in a container (shell)
    exec NAME "command"     Run a command inside container
    reboot NAMEs...         Reboot one or more containers (reboot)
    stop NAMEs...           Power off one or more containers (poweroff)
    kill NAMEs...           Terminate one or more VMs/containers (terminate)
  
    status NAMEs...         Show VM/container details (status)
    info [NAMEs...]         Show properties of one or more VMs/containers (show)
    edit NAME               Edit my container service override file
    editrepo                Edit /etc/_mm.conf repositories
    
    enable NAMEs...         Enable automatic container start at boot (enable)
    disable NAMEs...        Disable automatic container start at boot (disable)
    listautorun             List all autorun services of containers
    
  Image Commands:
    ls                      List registred containers in /var/lib/machines (list-images)
    lsa                     list all containers in all repositories of /etc/_mm.conf
    lsaq                    list all containers in all repositories of /etc/_mm.conf (quicker, no dir space is showen)
    register NAMEs...       Create a symlink of the container in /var/lib/machines & a clean service override
    unregister NAMEs...     delete symlink of the container in /var/lib/machines & DELETE its service override/autorun too
    iinfo [NAMEs...]        Show properties of image (show-image)
    istatus [NAMEs...]      Show image details (image-status)
    
    clone NAME              Clone a CT (CT dir & symlink, service override if they exist , but not autorun file; & hostname)
    rename NAME NewName     Rename a CT (CT dir & symlink, service override and autorun files if they exist; & hostname)
    
    delete NAME             Delete CT completly (CT dir, symlink, service override and autorun files)
    
    getpath NAME            print container path
    correct NAME            Correct effect of -U (uses --private-users=0 --private-users-chown)
    
    help,h                  Show help
```

## mmbuild help
```
mmbuild   imagename    Hostname(aZ09-)    OS    OS release    pass    [optional debootstrap args]

examples:
mmbuild   buster20210225175246     buster20210225175246     debian   buster       bbbbbbnn
mmbuild   bullseye20210225175246   bullseye20210225175246   debian   bullseye     bbbbbbnn
mmbuild   testing20210225175246    testing20210225175246    debian   testing      bbbbbbnn
mmbuild   unstable20210225175246   unstable20210225175246   debian   unstable     bbbbbbnn

mmbuild   xenial20210225175246     xenial20210225175246     ubuntu   xenial       bbbbbbnn
mmbuild   bionic20210225175246     bionic20210225175246     ubuntu   bionic       bbbbbbnn
mmbuild   focal20210225175246      focal20210225175246      ubuntu   focal        bbbbbbnn
```

# note:
it works fine and I use it for my daily use, but need some cleaning. for example comments inside code are a mix of spanish english.
