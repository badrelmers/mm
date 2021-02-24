

 _install(){
# mm machinectl manager
# author: badr in 2021


_common_functions(){
    # set -o xtrace ; set -xv ; set -o functrace
    # export LC_ALL=en_US.UTF-8 ; export LC_CTYPE=en_US.UTF-8 ; export LANG=en_US.UTF-8
    # export PYTHONIOENCODING=utf-8

    # Set magic variables for current file & dir
    # __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # __file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
    # __base="$(basename ${__file} .sh)"
    # __root="$(cd "$(dirname "${__dir}")" && pwd)" # <-- change this as it depends on your app

    # cd "${__dir}" || exit
    
    
    export datenow=$(date +%Y%m%d_%H%M%S)

    ###################################################
    echocolors(){
        INFOC()   { echo -e "\e[0;30m\e[42m" ; }      # black on green 
        WARNC()   { echo -e "\e[0;1;33;40;7m" ; }     # black on yellow ;usa invert 7; y light text 1 
        ERRORC()  { echo -e "\e[0;1;37m\e[41m" ; }    # bright white on red

        HIDEC()   { echo -e "\e[0;1;30m\e[47m" ; }    # hide color: white on grey (bright)
        #HIDEC()   { echo -e "\e[0;1;7;30m\e[47m" ; } # hide color: white on grey (darker)
        ENDC()    { echo -e "\e[0m" ; }               # reset colors

        INFO2C()  { echo -e "\e[0;1;37m\e[44m" ; }    # bright white on blue; 1  is needed sino 37 vuelve grey in mintty
        INFO3C()  { echo -e "\e[0;30m\e[46m" ; }      # black on white blue
    }
    export -f echocolors
    echocolors

    _trap_v2(){
        ###################################################
        # unofficial strict mode v2
        ###################################################
        set -o errexit   # -e: exit script on error
        set -o nounset   # -u: no unset variables
        set -o pipefail  # failure on any command errors
        set -o errtrace  # -E: shell functions inherit ERR trap
        set -o functrace # -T: shell functions inherit DEBUG trap

        error_handlerV2(){
        # error_handlerV2()(
            # print only last 3 lines of the command
            local ___bash_command=$( printf '%s\n' "${BASH_COMMAND:-unkownnn}" | head -3)
            # HIDEC ; echo "trap..._Func: ${FUNCNAME[1]:-unkownnn}" ; ENDC
            # [[ $1 -eq 0 ]] is to prevent running the trap because of trap EXIT when there is no error, i can use use trap ERR instead of trap ERR EXIT, but trap ERR do not trigger trap with undefined variables error; that s why i use trap ERR EXIT and [[ $1 -eq 0 ]]
            [[ $1 -eq 0 ]] && return 0
            ERRORC
            echo "_Exit:  $1   _Func: ${FUNCNAME[1]:-unkownnn}"
            echo "_line:  ${BASH_LINENO[*]:-unkownnn} in ${BASH_SOURCE[*]:-unkownnn}"
            echo "_comm:  $___bash_command"
            echo ''
            
            # echo caller="$(caller)"
            # echo FUNCNAMEall="${FUNCNAME[*]:-unkownnn}"
            # echo FUNCNAME="${FUNCNAME}"
            # echo LINENO=$2

            ENDC
            read -p 'Press enter to exit the trap'
            # read -p 'Press enter to exit the trap' < /dev/tty
            
            # tty=$(readlink /proc/$$/fd/2)
            # read -p 'Press enter to exit the trap' < $tty
            
            
            # exit 0 will prevent trigerring trap again in outside funcion after runing in an inner function
            # exit 0 do not seem to do anything, ERR ya hace ke el script exit , so i do no think i need to use exit here
            # exit 1 will trigger trap EXIT if trap ERR was trigered first, so the trap is run twice
            # exit 0
        # )
        }

        # trap - EXIT is needed to prevent runing the trap twice when ERR is trigered
        # why use ERR and EXIT? because undefined variables will not trigguer the trap
        trap 'error_handlerV2 $? ${LINENO}; trap - EXIT' EXIT ERR
        export -f error_handlerV2
    }
    _trap_v2

}
_common_functions
export -f _common_functions


___get_ct_repo(){
    # puesto ke uso multiple repositories , necesito saber en ke repo esta el container
    # usage: ___get_ct_repo VM
    # return the repository as $thisrepository
    local get_ct_repo_result=
    while read -r repository ; do
        if test -d "${repository}/_MyMM" ; then
            pushd "${repository}/_MyMM" >/dev/null
            if test -d "${1}" ; then
                thisrepository="${repository}"
                return
            else
                local get_ct_repo_result=no
            fi
            popd >/dev/null
        else
            WARNC ; echo "${repository}/_MyMM was not found. if you delete it then clean it from /etc/_mm.conf" ; ENDC
        fi
    done < <(grep "\S" /etc/_mm.conf) # grep "\S" Remove completely blank lines (including lines with spaces).
    [[ ${get_ct_repo_result} == no ]] && { WARNC ; echo "no container folder was found with this name: ${1}" ; ENDC ; exit 1 ; }
}

_print_container_repo_path(){
    ___get_ct_repo $1
    # [[ ${get_ct_repo_result} == no ]] && echo 
    if test -d "${repository}/_MyMM/$1" ; then
        echo "${repository}/_MyMM/$1"
    else
        echo cannot find container repo
        exit 1
    fi
}

_register_ct(){
    if [ $# -lt 1 ] ; then
        WARNC ; echo "usage: mm register Names..." 1>&2 ; ENDC
        return
    fi
    
    for i in $@ ; do
        ___get_ct_repo $i
        ln -s ${thisrepository}/_MyMM/$i /var/lib/machines/$i
        # add service override files
        mkdir /etc/systemd/system/systemd-nspawn@${i}.service.d
        cp ${thisrepository}/_MyMM/${i}/_MyMMfiles/nspawn_override_service.conf /etc/systemd/system/systemd-nspawn@${i}.service.d/nspawn_override_service.conf
        
        systemctl daemon-reload
    done
}

_unregister_ct(){
    if [ $# -lt 1 ] ; then
        WARNC ; echo "usage: mm unregister Names..." 1>&2 ; ENDC
        return
    fi
    
    for i in $@ ; do
        # remove symlink
        rm /var/lib/machines/$i
        # remove service override files and autorun
        test -d /etc/systemd/system/systemd-nspawn@${i}.service.d && rm -rf /etc/systemd/system/systemd-nspawn@${i}.service.d
        test -f /etc/systemd/system/machines.target.wants/systemd-nspawn@${i}.service && rm /etc/systemd/system/machines.target.wants/systemd-nspawn@${i}.service

        systemctl daemon-reload
    done
}


_list_all_containers(){
    # list all containers in all repositories of /etc/_mm.conf
    while read -r repository ; do
        if test -d "${repository}/_MyMM" ; then
            echo ''
            echo "====================================================" 
            echo "repository: ${repository}"
            echo "===================================================="
            cd "${repository}/_MyMM"
            echo 'Size    VM Name'
            echo ------------------------------
            du -chs *
        else
            WARNC ; echo "${repository}/_MyMM was not found. if you delete it then clean it from /etc/_mm.conf" ; ENDC
        fi
    done < <(grep "\S" /etc/_mm.conf) # grep "\S" Remove completely blank lines (including lines with spaces).
}

_list_all_containers_quicker(){
    # list all containers in all repositories of /etc/_mm.conf
    # this do not show container space so it s quicker, because if the container folder is big(ex 40g) then du -chs will take too much time
    while read -r repository ; do
        if test -d "${repository}/_MyMM" ; then
            echo ''
            echo "====================================================" 
            echo "repository: ${repository}"
            echo "===================================================="
            cd "${repository}/_MyMM"
            echo 'Size    VM Name'
            echo ------------------------------
            ls | tee
        else
            WARNC ; echo "${repository}/_MyMM was not found. if you delete it then clean it from /etc/_mm.conf" ; ENDC
        fi
    done < <(grep "\S" /etc/_mm.conf) # grep "\S" Remove completely blank lines (including lines with spaces).
}

_clone_ct(){
    # "machinectl clone" copia el folder desde el repository a /var/lib/machines y no copia the service override files,asi ke no sirve; por eso usare esto
    
    ___get_ct_repo $1
    # do not clone if CT is running
    machinectl | grep -q "^$1 " && { WARNC ; echo CT is running, stop it first ; ENDC ; return ; }
    export datenowForHostname=$(date +%Y%m%d%H%M%S)
    
    # clone and rename CT
    cp -a ${thisrepository}/_MyMM/${1} ${thisrepository}/_MyMM/${1}-clone${datenowForHostname}
    
    # create symlink only if $1 had symlink in /var/lib/machines too
    test -L /var/lib/machines/${1} && ln -s ${thisrepository}/_MyMM/${1}-clone${datenowForHostname} /var/lib/machines/${1}-clone${datenowForHostname}
    
    # clone and rename autorun service if exist
    # TODO: no se si kiero esto, pk generalmente hare clone para hacer tests asi ke no necesito hacer ke el CT bootea al reiniciar .y de todas formas tengo la opcion de ponerlo autorun facilmente con "mm enable" ... asi ke no copiare el autorun mejor
    
    # copy service override files
    test -d /etc/systemd/system/systemd-nspawn@${1}.service.d && cp -a /etc/systemd/system/systemd-nspawn@${1}.service.d /etc/systemd/system/systemd-nspawn@${1}-clone${datenowForHostname}.service.d

    # edit hostname and hosts
    sed -i "s/${1}/${1}-clone${datenowForHostname}/g" ${thisrepository}/_MyMM/${1}-clone${datenowForHostname}/etc/hostname
    sed -i "s/${1}/${1}-clone${datenowForHostname}/g" ${thisrepository}/_MyMM/${1}-clone${datenowForHostname}/etc/hosts

    # save new CT name
    echo "name:${1}-clone${datenowForHostname} ___ date:$(date)" >> ${thisrepository}/_MyMM/${1}-clone${datenowForHostname}/_MyMMfiles/_container_names.txt

    systemctl daemon-reload
    
    echo container created: ${1}-clone${datenowForHostname}
}

_rename_ct(){
    # "machinectl rename" renombra el symlink solo ke esta en /var/lib/machines y no renombra el contanner dir en el repository ,asi ke no sirve; por eso usare esto
    if [ $# -lt 2 ] ; then
        WARNC ; echo "usage: mm rename Name NewName" 1>&2 ; ENDC
        return
    fi
    
    ___get_ct_repo $1
    
    # do not clone if CT is running
    machinectl | grep -q "^$1 " && { WARNC ; echo 'CT is running, stop it first' ; ENDC ; return ; }
    
    # test if new name is not used
    test -L /var/lib/machines/${2} &&  { WARNC ; echo 'CT name exist, use another name' ; ENDC ; return ; }
    test -d ${thisrepository}/_MyMM/${2} &&  { WARNC ; echo 'CT name exist, use another name' ; ENDC ; return ; }
    
    # rename CT
    mv ${thisrepository}/_MyMM/${1} ${thisrepository}/_MyMM/${2}
    
    # rename symlink only if $1 had symlink in /var/lib/machines too 
    test -L /var/lib/machines/${1} && { rm /var/lib/machines/${1} ; ln -s ${thisrepository}/_MyMM/${2} /var/lib/machines/${2} ; }

    # and rename autorun service if exist
    test -f /etc/systemd/system/machines.target.wants/systemd-nspawn@${1}.service && mv /etc/systemd/system/machines.target.wants/systemd-nspawn@${1}.service /etc/systemd/system/machines.target.wants/systemd-nspawn@${2}.service
    
    # and rename service override files
    test -d /etc/systemd/system/systemd-nspawn@${1}.service.d && mv /etc/systemd/system/systemd-nspawn@${1}.service.d /etc/systemd/system/systemd-nspawn@${2}.service.d
    
    # edit hostname and hosts
    sed -i "s/${1}/${2}/g" ${thisrepository}/_MyMM/${2}/etc/hostname
    sed -i "s/${1}/${2}/g" ${thisrepository}/_MyMM/${2}/etc/hosts

    # save new CT name
    echo "name:${2} ___ date:$(date)" >> ${thisrepository}/_MyMM/${2}/_MyMMfiles/_container_names.txt
    
    systemctl daemon-reload
}

_delete_ct(){
    if [ $# -lt 1 ] ; then
        WARNC ; echo "usage: mm delete Name" 1>&2 ; ENDC
        return
    fi
    
    ___get_ct_repo $1
    
    # do not delete if CT is running
    machinectl | grep -q "^$1 " && { WARNC ; echo CT is running, stop it first ; ENDC ; return ; }

    WARNC ; echo "I will delete this folder:"
    echo "   => ${thisrepository}/_MyMM/${1} <="
    ENDC
    read -p "Continue (y/n)?" choice
    case "$choice" in 
        y|Y )
              # delete CT dir
              test -d ${thisrepository}/_MyMM/${1} && rm -rf ${thisrepository}/_MyMM/${1}
              # delete CT symlink
              test -L /var/lib/machines/${1} && rm /var/lib/machines/${1}
              # delete CT service override files
              test -d /etc/systemd/system/systemd-nspawn@${1}.service.d && rm -rf /etc/systemd/system/systemd-nspawn@${1}.service.d
              # delete CT autorun service
              test -f /etc/systemd/system/machines.target.wants/systemd-nspawn@${1}.service && rm /etc/systemd/system/machines.target.wants/systemd-nspawn@${1}.service
              ;;
        n|N ) return ;;
        * ) echo "invalid choice" ;;
    esac
    
    systemctl daemon-reload
}

_correct_ct(){
    # correct effect of -U
    # do this when I run a container as unprivileged (with -U) then I run it as privileged  (without -U) then I want to run it again as unprivileged (with -U) , so i need to do this before runing the container with -U again
    ###update: tb al ejecutar el container without -U after using -U I have to use this or i will get a message about sudo (sudo must be owned by uid 0 and have the setuid bit set) for example.
    ###asi ke cada vez ke cambio entre comandos ke usan -U y comandos ke no usan -U hay ke usar esto
    systemd-nspawn -M $1 --private-users=0 --private-users-chown echo finitooo
}

#debian 10 work without /bin/bash in machinectl shell.. but ubuntu 16 gave error without it and says: sh: 2: exec: : Permission denied , ubuntu 18 is fine

_help(){
    machinectl --help | tee
    echo '
===========================
additional commands by badr
config file: /etc/_mm.conf
===========================
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
'
}


########################################
### main 
########################################
RETVAL=0

cmd=${1:-}
shift || true # esta es importante para poder usar $@ sin ke contenga $1 ke se consume in case...


case "$cmd" in
    run)         machinectl start $@ ; sleep 1 ; machinectl shell ${1:-} /bin/bash -l ;;
    start)       machinectl start $@ ;;
        
    sh)          machinectl shell ${1:-} /bin/bash -l ;;
    exec)        machinectl shell ${1:-} /bin/bash -c "${2:-}" ;;
        
    reboot)      machinectl reboot $@ ;;
    stop)        machinectl poweroff $@ ;;
    kill)        machinectl terminate $@ ;;
    
    status)      machinectl status $@ -n 300 ;;
    info)        machinectl show $@ ;;
    
    edit)        nano /etc/systemd/system/systemd-nspawn@${1:-}.service.d/nspawn_override_service.conf ;;
    editrepo)    nano /etc/_mm.conf ;;
    
    enable)      machinectl enable $@ ;;
    disable)     machinectl disable $@ ;;
    listautorun) ls /etc/systemd/system/machines.target.wants 2>/dev/null | tee ;;
        
    ls)          machinectl list-images ;;
    lsa)         _list_all_containers ;;
    lsaq)        _list_all_containers_quicker ;;
    register)    _register_ct $@ ;;
    unregister)  _unregister_ct $@ ;;
    iinfo)       machinectl show-image $@ ;;
    istatus)     machinectl image-status $@ ;;
    
    clone)       _clone_ct ${1:-} ;;    
    # do not quote $2 sino no me funcionara el test con $# para saber cuantos parametros fueron pasados
    rename)      _rename_ct ${1:-} ${2:-} ;;
    # do not quote $1 sino no me funcionara el test con $# para saber cuantos parametros fueron pasados
    delete)      _delete_ct ${1:-} ;;
    
    getpath)     _print_container_repo_path ${1:-} ;;
    correct)     _correct_ct ${1:-} ;;

    help|h)      _help ;;
    "")          machinectl ;;
    *)           WARNC ; echo "Unknown command: "$cmd. >&2 ; ENDC ; _help ;;
esac

# no hagas esto pk va a sobrescribir el exit code de los commandos ke fallan y no pasaran so return exit correcto con $?
# exit $RETVAL
 }

 # _____________________________________________________



 # install the script 
 echo '#!/bin/bash' > /usr/local/bin/mm
 declare -f _install >> /usr/local/bin/mm

 # declare will put the function as function in the file so let s solve it;so it will not run if it s not called 
 prepare_script(){
    met1_prepare(){
        # met1:this will remove the function parts
        # delet first two lines
        sed -i '1,2d' /usr/local/bin/mm
        # delete last line
        sed -i '$d' /usr/local/bin/mm
    }
    # met1_prepare
    
    met2_prepare(){
        # met2:call the function
        echo '_install "$@"' >> /usr/local/bin/mm
    }
    met2_prepare
 }
 prepare_script
 
chmod +x /usr/local/bin/mm

