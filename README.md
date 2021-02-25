**mm** is a machinectl/systemd-nspawn manager

**mmbuild** is a container creator for nspawn using debootstrap (tested with debian and ubuntu, others may work too)

# install
install mm and mmbuild to /usr/local/bin
```bash
git clone https://github.com/badrelmers/mm
bash ./mm/install.sh
```

# help
```bash
mm help
mmuild help
```

# example 1:
```bash
# create a folder which will be used as the repository for nspawn containers and add it to /etc/_mm.conf so it can be controlled by mm (you can create multiple folders in diferent disks to be as repository)
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
# clone, rename and register a container
mm clone buster20210225124857
mm rename buster20210225124857-clone...  mybustercontainer
mm register mybustercontainer
mm run mybustercontainer
```

# note:
it works fine but need some cleaning. for example comments are a mix of spanish english :0
