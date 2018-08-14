#!/usr/bin/env bash
source /etc/profile
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"

VER=1.0

outputDir="${DIR}/outputs"
force=
exec=
runnablePattern=
while getopts ":ho:fe:i:" opt; do
    case ${opt} in
    h)
        echo -e "Android-Cracker-CLI v${VER}, fork me in https://github.com/DrkCore/Android-Cracker-CLI, star me if you like it!\n"
        echo -e "Decompile android bin file into readable source files. \n"
        echo "Usage:"
        echo "crack.sh [OPTIONS] [ARGS...] [TARGET]"
        echo "    -o OUTPUT_DIR     specify dir to store decompiled file, 'SCRIPTS_DIR/outputs' will be used if not specified."
        echo "    -f                force to re-decompile target file. Cached result will be presented if this option is not used, if there is any."
        echo "    -e EXEC           run '\$exec RESULT_DIR' after decompiling finished. You can use tools like VSCode or Atom to view the result."
        echo "    -i PATTERN        find files matched pattern and crack them if there are any runnable bin in your apk."
        echo -e "\nTARGET could be one of below:"
        echo -e "\n    apk, aar, jar, dex, directory\n"
        echo "If target file has other ext names or has no ext name, then it will be treated as an apk file."
        echo "If target is directory, then it will recursively process all files with accepted ext name, and ignore files which have no ext name."
        exit 0
        ;;
    o)
        outputDir=${OPTARG}
        ;;
    f)
        force="true"
        ;;
    e)
        exec=${OPTARG}
        ;;
    i)
        runnablePattern=${OPTARG}
        ;;
    \?)
        echo "Invalid option: -${OPTARG}"
        exit 1
        ;;
    esac
done

for last; do true; done
target=${last}

mkdir -p ${outputDir}
if [ ! -d "${outputDir}" ]; then
    echo "Output dir ${outputDir} is not avaiable"
    exit 1
fi

function processFile(){
    procfile=$1
    fileName=${procfile##*/}
    safeFileName=$(echo "$fileName" | tr ' ' '_')
    fileMd5=$(md5sum "${procfile}" | grep -E -o "^[0-9a-z]{32}")
    finalDir=${outputDir}/${safeFileName}/${fileMd5}
    workDir=${finalDir}_tmp

    echo ${force}
    if [ -n "${force}" ]; then
        rm -rf ${finalDir}
    fi

    if [ ! -d "${finalDir}" ]; then
        rm -rf ${workDir}
        mkdir -p ${workDir}
        echo "Work dir is ${workDir}"
        cp "${procfile}" "${workDir}"
        safeFile=${workDir}/${safeFileName}
        if [ ! "${workDir}/${fileName}" == "${safeFile}" ]; then
            mv "${workDir}/${fileName}" "${safeFile}"
        fi

        fileExt=${procfile##*.}
        echo "Target ext name is ${fileExt}"
        if [ ${fileExt} = "jar" ]; then
            processJar ${safeFile} ${workDir}

        elif [ ${fileExt} = "aar" ]; then
            processAar ${safeFile} ${workDir}

        elif [ ${fileExt} = "dex" ]; then
            processDex ${safeFile} ${workDir}

        elif [ ${fileExt} = "apk" ]; then
            processApk ${safeFile} ${workDir}

        else
            echo "Could not handle ${fileExt} file, treat it as apk file..."
            processApk ${safeFile} ${workDir}
        fi

        rm -rf ${finalDir}
        mv ${workDir} ${finalDir}
    fi

    echo "Decompiling ${procfile} is done, dest dir is ${finalDir}"
    logFile=${finalDir}/logs.txt
    touch ${logFile}
    echo "${procfile}" >> ${logFile}

    if [ -n "${exec}" ]; then
        ${exec} ${finalDir}
    fi
}

function processJar(){
    file="$1"
    workDir="$2"
    
    echo "Processing jar file ${file}"

    jarName=${file##*/}
    jarMd5=$(md5sum ${file} | grep -E -o "^[0-9a-z]{32}")
    jarExtractDir=${workDir}/jarExtract/${jarName}/${jarMd5}

    if [ -d ${jarExtractDir} ]; then
        echo "${file} has already been processed, skip..."
        return
    fi

    ${DIR}/libs/jd-cli-0.9.1.Final-dist/jd-cli -n -od ${jarExtractDir} -rn ${file}
}

function processDex(){
    file="$1"
    workDir="$2"

    echo "Processing dex file ${file}"

    dexName=${file##*/}
    dexMd5=$(md5sum ${file} | grep -E -o "^[0-9a-z]{32}")
    dexExtractDir=${workDir}/dexExtract/${dexName}/${dexMd5}

    if [ -d ${dexExtractDir} ]; then
        echo "${file} has already been processed, skip..."
        return
    fi

    mkdir -p ${dexExtractDir}
    
    jarFile=${dexExtractDir}/${dexName}.jar
    ${DIR}/libs/dex2jar-2.0/d2j-dex2jar.sh -o ${jarFile} ${file}

    processJar ${jarFile} ${workDir}
}

function processAar(){
    file="$1"
    workDir="$2"

    echo "Processing aar file ${file}"

    aarName=${file##*/}
    aarMd5=$(md5sum ${file} | grep -E -o "^[0-9a-z]{32}")
    aarExtractDir=${workDir}/aarExtract/${aarName}/${aarMd5}

    if [ -d ${aarExtractDir} ]; then
        echo "${file} has already been processed, skip..."
        return
    fi

    mkdir -p ${aarExtractDir}
    unzip ${file} -d ${aarExtractDir}

    find ${aarExtractDir} -name "*.jar" | while read line
    do
        processJar ${line} ${workDir}
    done
}

function processApk(){
    file="$1"
    workDir="$2"

    apkName=${file##*/}
    apkMd5=$(md5sum "${file}" | grep -E -o "^[0-9a-z]{32}")
    apkExtractDir=${workDir}/apkExtract/${apkName}/${apkMd5}

    if [ -d ${apkExtractDir} ]; then
        echo "${file} has already been processed, skip..."
        return
    fi

    ${DIR}/libs/apktool/apktool d -f -o ${apkExtractDir} -s ${file}

    find ${apkExtractDir} -name "*.dex" | while read line
    do
        processDex ${line} ${workDir}
    done

    if [ -n "$runnablePattern" ]; then
        find ${apkExtractDir} -name "${runnablePattern}" | while read line
        do
            processApk ${line} ${workDir}
        done
    fi
}

if [ ! -n "${target}" ]; then
    echo "Please specify target path!"
    exit 1
fi

if [ -d "${target}" ];then
    echo "Processing ${target} as dir..."
    find "${target}" -type f \( -name "*.apk" -o -name "*.aar" -o -name "*.jar" -o -name "*.dex" \) | while read line
    do
        processFile "${line}"
    done;

elif [ -f "${target}" ];then
    echo "Processing ${target} as file..."
    processFile "${target}"
    
else
    echo "Target file ${target} is not exist!"
    exit 1
fi