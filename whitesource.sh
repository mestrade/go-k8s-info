#!/usr/bin/env bash

# rebuild flag comment

set -e

export LC_ALL=C.UTF-8
export LANG=C.UTF-8

# setting jvm heap default to 1G
[[ -z "$JVM_XMS" ]] && JVM_XMS=2G
[[ -z "$JVM_XMX" ]] && JVM_XMX=8G

wss_cmd="java -Xms${JVM_XMS} -Xmx${JVM_XMX} -jar wss-unified-agent.jar"
xa_cmd="java -Xms${JVM_XMS} -Xmx${JVM_XMX} -jar xModuleAnalyzer.jar"
# defined by volumes
config_file="/app/wss-unified-agent.config"
code_dir="/workspace/source/"
apppath_file="/app/eua.txt"
log_path="/app/logs"

function generate_eua_apppath() {
    [[ -e $apppath_file ]] && unlink $apppath_file
    $wss_cmd -d $code_dir -analyzeMultiModule $apppath_file
    echo "DEBUG: The generated file is:"
    echo
    cat $apppath_file
    echo
    echo "End of generated file."
}

function run_eua() {
    generate_eua_apppath
    $xa_cmd -xModulePath $apppath_file -fsaJarPath wss-unified-agent.jar -c $config_file -logPath $log_path -statusDisplay threshold $args
}

function run_regular() {
    $wss_cmd $api_key_arg $user_key_arg -d $code_dir -c $config_file $args
}

function run_ws_help() {
    $wss_cmd -help
}

function usage() {
   cat <<EOF
    This command does not exist.

    Usage:
        docker run --rm -ti \\
            -v /some/code/to/analyse:/data \\
            -v /some/place/wss-unified-agent.config:/app/wss-unified-agent.config \\
            -v /some/place/to/store/logs:/app/logs \\
            [ -v \$HOME/.m2:/app/.m2 \\ ]
            [ -e JVM_XMS=n \\ ]
            [ -e JVM_XMX=n \\ ]
            docker.io/cloudbees/whitesource-agent:<version> [<whitesource args>] <COMMAND>

    The \`latest\` will point to whatever is considered the stable version to be used, and not necessarily the latest whitesource agent version.
    	
    - The \`/data\` volume will point to the code you want to analyse.
    - The bind volume should point to your whitesource agent config file, and correspond to the <COMMAND> you are calling.
    - If scanning a maven project, you need to bind mount your .m2 where built artifacts can be found. Symlinks on settings.xml will not work.
    - The logs directory will keep EUA logs on your host. It needs to be created prior to executing the \`eua\` run (and currently is only used for eua).

    <COMMAND> can be:
        - regular.               : If no parameter given (command is empty), it will run a regular analysis (e.g. no EUA)
        - eua                    : Launch a multi module EUA analysis (such as URR) You should build your project beforehand (maven and npm only). An eua.txt file will be generated for you. It should also work for regular projects.
        - help                   : Displays this usage information
        - ws-help                : Show the WhiteSource agent's help (i.e. <whitesource args>)
        -                        : If run without parameters, this help is displayed.

    The EUA is currently only supported for maven and JS projects.

    Environment variables:
        For EUA, if not given a limit, the JVM will likely crash your machine. A default of $JVM_XMX is given.
        There needs to be quite some RAM for EUA to work properly. 16G seems like a good number.
        The arbitrary default is 1G, but will likely not be enough to run properly.

    [<whitesource args]:

        Optional parameters to the WhiteSource Unified Agent, for example to override settings in your configuration file such as API & user keys.
        To see the full list of all the supported parameters, use 'ws-help' as the <COMMAND>.
EOF
}

while (( "$#" )); do
    case "$1" in
        "-c")
            shift
            export config_file=$1
            ;;
        "-d")
            shift
            export code_dir=$1
            ;;
        "eua")
            echo "In eua"
            run_eua
            exit 0
            ;;
        "regular")
            echo "In regular"
            run_regular
            exit 0
            ;;
        "ws-help")
            run_ws_help
            exit 0
            ;;
        "help")
            usage
            exit 0
            ;;
        *)
            args="$args $1"
            ;;

    esac

    shift
done

#Didn't end up finding any recognised commands.
usage