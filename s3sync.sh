#!/bin/bash
#
# scriptname.sh
# Escrito por \\ Author  : Douglas Bussoli Mugnos 
# e-mail : douglasmugnos@gmail.com
#
# [PT-BR]                                   | [EN-US]
# Esse script é responsável de fazer backup | This script is responsable for making backups
# e sincronizar os dados de uma lista de    | and sync data based on a list of 
# diretórios para um bucket S3              | directories to a S3 Bucket
#
# 2018-08-14 [PT-BR] - DOUGLAS MUGNOS - Versão  1: Faz sync full de diretórios locais para Bucket s3
# 2018-08-14 [EN-US] - DOUGLAS MUGNOS - Version 1: Do full sync from local directories to S3 Bucket
#
#

############
# Variáveis dinamicas | Dynamic variables 
# [PT-BR] Preencha todas váriaveis de acordo com o seu cenário 
# [EN-US] Fill all the variables according to your scenario 

#S3 Access and Secret Key
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_KEY"

#S3 Bucket name 
S3BUCKET="YOUR_BUCKET_NAME"

############
# Variáveis estáticas | Static variables 
# [PT-BR] Não altere variáveis estáticas se não tem certeza do que esta fazendo.
# [EN-US] Do not change static variables if you are not sure what you are doing.
TSTAMPHM=$(date +'%Y%m%d%H%M')
CLIENTHOSTNAME=$(hostname)
SCRIPTNAME=$(basename $0)
SCRIPTPATH=$(dirname $0)
SCRIPTLOGPATH="$SCRIPTPATH/logs"
SCRIPTLOGFILE="${SCRIPTLOGPATH}/s3sync-${TSTAMPHM}.log"

#[PT-BR] Lista de diretórios/arquivos para fazer backup
#[EN-US] List of directories/files to do backups
LISTOFDIRSTOBACKUP="$SCRIPTPATH/backup_list.txt"

#Path para backup dentro do S3 | Backup path inside S3
S3_BACKUP_PATH="${CLIENTHOSTNAME}-backups"

############
# Funções | Funcions
S3_BUCKET_CHECK(){
    local S3BUCKET=$1
    aws s3 ls s3://${S3BUCKET} > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        OutputMessages ERROR "Bucker does not exist"
    else
        OutputMessages INFO  "Bucker exist"
    fi
}

MOVE_TO_S3(){

    local S3BUCKET=$1
    local CLIENTHOSTNAME=$2
    
    IFS2=$IFS
    IFS=$'\n'
    for object_to_sync in $(cat $LISTOFDIRSTOBACKUP )
    do
        OutputMessages INFO  "Starting sync from $object_to_sync to bucket $S3BUCKET"
        aws s3 sync $object_to_sync s3://${S3BUCKET}/${CLIENTHOSTNAME}/${object_to_sync}/ 
        OutputMessages INFO  "Files in $object_to_sync synced to bucket $S3BUCKET "
    done

    IFS=${IFS2}

}

OutputMessages(){
    local hostname=$(hostname)
    local tstamphm=$(date +'%Y%m%d%H%M')
    local msg_code=$1
    local msg_data=$2 

    echo ${tstamphm},${hostname},${msg_code},\"${msg_data}\"

    if [ "$msg_code" == "ERROR" ] ;then
        echo ${tstamphm},${hostname},${msg_code},\"exiting script. RC=${3}\" 
        exit $msg_rc
    fi

}

CHECK_PRE_REQS(){
    [[ -d "${SCRIPTLOGPATH}" ]] || mkdir ${SCRIPTLOGPATH} && OutputMessages "INFO" "Log directory created - ${SCRIPTLOGPATH}"
    [[ -f "${LISTOFDIRSTOBACKUP}"  ]] || OutputMessages "ERROR" "${LISTOFDIRSTOBACKUP} not found" "1"
}


############
# Corpo principal | Main body
MAIN_BODY(){
    S3_BUCKET_CHECK ${S3BUCKET}
    MOVE_TO_S3 ${S3BUCKET} ${CLIENTHOSTNAME} 
}

CHECK_PRE_REQS

MAIN_BODY 2>/dev/null | tee ${SCRIPTLOGFILE} 