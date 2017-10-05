#!/bin/bash

# --------------------------------------------------------------------------
# Arquivo de instalação do sistema RISO EFI
# --------------------------------------------------------------------------

# Verifica parâmetros do disco (ex:/dev/sda) e arquivo de particionamento (ex: HD500.gpt)

if [ $# -ne 2 ]; then

    dialog --sleep 5  --infobox " Exemplo de utilização do script: ./riso-EFI.sh /dev/sda HD500.gpt" 10 50

   exit 1;
fi

# Define as variáveis DIRNAME, DEVICE e TABLE a partir dos parâmetros do disco e arquivo de particionamento.

DIRPATH=`dirname $0`

DEVICE=$1

TABLE=$2

VERSION=`cat ${DIRPATH}/riso-EFI.version`


    
aplica_tabela_particionamento(){    
    
    carregar_variaveis;
    
    dialog --sleep 5  --infobox " Aplicando a tabela de particionamento." 10 50
    
    # Aplica a tabela de particionamento ao disco, "sgdisk" comando de atribuição de partição do padrão gpt,"-g" força a mudança da tabela de partição para gpt, 
    
    # "--load-backup=" aponta para o arquivo com as partições ${TABLE} (ex: HD500.gpt) e aplica no disco ${DEVICE} (ex: /dev/sda)

    sgdisk -g --load-backup=${TABLE} ${DEVICE}
    
    dialog --sleep 5  --infobox " A tabela de particionamento foi aplicada com sucesso." 10 50
    
}    
atualiza_riso() {

    carregar_variaveis;

    dialog --sleep 5  --infobox " Formatando a partição RISO." 10 50
    
    # Formata a partição riso, trocando a UUID

    mkfs.${SA_PARTRISO} -Fq -O ^metadata_csum -U ${PARTRISO,,} -L "RISO" ${RISO}

    dialog --sleep 5  --infobox " A formatação da partição RISO foi concluída com sucesso." 10 50

    #Restaura a partição riso a partir do arquivo riso.tar.bz2 presente no pendrive na segunda partição (ex:sdb2)

    mount ${RISO} /mnt

    dialog --sleep 5  --infobox " Restaurando a partição RISO." 10 50

    tar -jxf riso.tar.bz2 -C /mnt

    dialog --sleep 5  --infobox " A restauração da partição RISO foi concluída com sucesso." 10 50

    dialog --sleep 5  --infobox " Instalando e atualizando o GRUB..." 10 50
    
    #Instala o grub na partição montada no diretório /mnt

    mkdir -p /mnt/boot/efi

    mount ${EFI} /mnt/boot/efi

    for i in /sys /proc /dev; do mount --bind ${i} /mnt${i}; done

    chroot /mnt grub-install ${DEVICE}

    chroot /mnt update-grub

    for i in /sys /proc /dev; do umount /mnt${i}; done

    umount ${EFI}

    umount ${RISO}
    
    dialog --sleep 5  --infobox " O GRUB foi instalado e atualizado com sucesso." 10 50

}

# Carrega as variáveis do arquivo riso-EFI.cfg

carregar_variaveis() {
    
    source ${DIRPATH}/riso-EFI.cfg
    
    return 0
}

formatar_dados() {
    
    carregar_variaveis;
    
    dialog --sleep 5  --infobox " Formatando a partição DADOS." 10 50
    
    #Formata a partição dados, trocando a UUID e rótulo

    mkfs.${SA_PARTDADOS} -f -Fq -L "DADOS" ${DADOS}

    u=${PARTDADOS^^}

    echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2} | xxd -r -p | dd of=${DADOS} bs=8 count=1 seek=9

    dialog --sleep 5  --infobox " A formatação da partição DADOS foi concluída com sucesso." 10 50
    
}

formatar_efi() {
    
    carregar_variaveis;
    
    dialog --sleep 5  --infobox " Formatando a partição EFI." 10 50
    
    # Formata a partição EFI, atribuindo a UUID e rótulo
    
    mkfs.${SA_PARTEFI} -F 32 -i `echo ${PARTEFI^^} | tr -d -` -n "EFI" ${EFI}
    
    dialog --sleep 5  --infobox " A formatação da partição EFI foi concluída com sucesso." 10 50
    
}

formatar_linux() {
    
    carregar_variaveis;
    
    dialog --sleep 5  --infobox " Formatando a partição LINUX." 10 50
    
    #Formata a partição linux, trocando a UUID e rótulo
    
    e2fsck -f ${LINUX} -y

    mkfs.${SA_PARTLINUX} -Fq -O ^metadata_csum -U ${PARTLINUX,,} -L "LINUX" ${LINUX}
    
    dialog --sleep 5  --infobox " A formatação da partição LINUX foi concluída com sucesso." 10 50
    
}

formatar_riso() {
    
    carregar_variaveis;
    
    dialog --sleep 5  --infobox " Formatando a partição RISO." 10 50
    
    # Formata a partição riso, atribuindo a UUID e rótulo
    
    e2fsck -f ${RISO} -y
    
    mkfs.${SA_PARTRISO} -Fq -O ^metadata_csum -U ${PARTRISO,,} -L "RISO" ${RISO}
    
    dialog --sleep 5  --infobox " A formatação da partição RISO foi concluída com sucesso." 10 50
    
}

formatar_swap() {

    # Desliga a swap
    
    swapoff -a    
    
    carregar_variaveis;
    
    dialog --sleep 5  --infobox " Formatando a partição SWAP." 10 50
    
    #Formata a partição swap, trocando a UUID e rótulo
    
    mk${SA_PARTSWAP} -U ${PARTSWAP,,} -L "SWAP" ${SWAP}    

    dialog --sleep 5  --infobox " A formatação da partição SWAP foi concluída com sucesso." 10 50
    
}

formatar_windows() {

    carregar_variaveis;
    
    dialog --sleep 5  --infobox " Formatando a partição WINDOWS." 10 50
    
    #Formata a partição windows, atribuindo a UUID e rótulo
    
    mkfs.${SA_PARTWINDOWS} -f -Fq  -L "WINDOWS" ${WINDOWS}

    u=${PARTWINDOWS^^}

    echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2} | xxd -r -p | dd of=${WINDOWS} bs=8 count=1 seek=9
    
    dialog --sleep 5  --infobox " A formatação da partição WINDOWS foi concluída com sucesso." 10 50
    
}

instalar_riso(){

    carregar_variaveis;

    dialog --sleep 5  --infobox " Instalando o RISO UEFI ${VERSION}." 10 50

    # Desliga a swap
    
    swapoff -a

    # Aplica a tabela de particionamento ao disco, "sgdisk" comando de atribuição de partição do padrão gpt,"-g" força a mudança da tabela de partição para gpt, 

    # "--load-backup=" aponta para o arquivo com as partições ${TABLE} (ex: HD500.gpt) e aplica no disco ${DEVICE} (ex: /dev/sda)

    sgdisk -g --load-backup=${TABLE} ${DEVICE}

    dialog --sleep 5  --infobox " Formatando as partições." 10 50

    # Formata a partição EFI, trocando a UUID

    mkfs.${SA_PARTEFI} -F 32 -i `echo ${PARTEFI^^} | tr -d -` -n "EFI" ${EFI}

    # Formata a partição riso, trocando a UUID

    mkfs.${SA_PARTRISO} -Fq -O ^metadata_csum -U ${PARTRISO,,} -L "RISO" ${RISO}

    #Formata a partição windows, trocando a UUID.

    mkfs.${SA_PARTWINDOWS} -f -Fq  -L "WINDOWS" ${WINDOWS}

    u=${PARTWINDOWS^^}

    echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2}| xxd -r -p | dd of=${WINDOWS} bs=8 count=1 seek=9

    #Formata a partição linux, trocando a UUID

    mkfs.${SA_PARTLINUX} -Fq -O ^metadata_csum -U ${PARTLINUX,,} -L "LINUX" ${LINUX}

    # Formata a partição Dados

    mkfs.${SA_PARTDADOS} -f -Fq -L "DADOS" ${DADOS}

    u=${PARTDADOS^^}

    echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2}| xxd -r -p | dd of=${DADOS} bs=8 count=1 seek=9

    # Formata a partição swap, trocando a UUID

    mk${SA_PARTSWAP} -U ${PARTSWAP,,} -L "SWAP" ${SWAP}

    dialog --sleep 5  --infobox " A formatação das partições foi concluída com sucesso." 10 50

    dialog --sleep 5  --infobox " Restaurando a partição RISO." 10 50

    #Restaura a partição riso a partir do arquivo riso.tar.bz2 presente no pendrive na segunda partição (ex:sdb2)

    mount ${RISO} /mnt

    tar -jxf riso.tar.bz2 -C /mnt

    #Instala o grub na partição montada no diretório /mnt

    mkdir -p /mnt/boot/efi

    mount ${EFI} /mnt/boot/efi

    for i in /sys /proc /dev; do mount --bind ${i} /mnt${i}; done

    chroot /mnt grub-install ${DEVICE}

    chroot /mnt update-grub

    for i in /sys /proc /dev; do umount /mnt${i}; done

    umount ${EFI}

    umount ${RISO}

    dialog --sleep 5  --infobox " A partição RISO foi restaurada com sucesso." 10 50

    dialog --sleep 5  --infobox " A instalação do RISO UEFI ${VERSION} foi concluída com sucesso." 10 50

    reboot

}

instalar_UUID() {

    carregar_variaveis;

    dialog --sleep 5  --infobox " Atribuindo a UUID padrão nas partições." 10 50

    # Atribuindo a UUID na partição EFI

    mkfs.${SA_PARTEFI} -i `echo ${PARTEFI^^} | tr -d -` -n "EFI" ${EFI}

    # Atribuindo a UUID a partição riso

    e2fsck -f ${RISO} -y

    tune2fs -U ${PARTRISO,,} -L "RISO" ${RISO}

    # Atribui a UUID na partição windows

    u=${PARTWINDOWS^^}

    echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2} | xxd -r -p | dd of=${WINDOWS} bs=8 count=1 seek=9

    # Atribui a UUID na partição linux

    e2fsck -f ${LINUX} -y

    tune2fs -U ${PARTLINUX,,} -L "LINUX" ${LINUX}

    # Atribui a UUID na partição dados

    u=${PARTDADOS^^}

    echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2}| xxd -r -p | dd of=${DADOS} bs=8 count=1 seek=9

    # Atribui a UUID na partição swap

    mk${SA_PARTSWAP} -L "SWAP" ${SWAP}

    dialog --sleep 5  --infobox " A atribuição da UUID padrão nas partições foi concluída com sucesso." 10 50

    dialog --sleep 5  --infobox " Montando as partições riso, /dev, /proc, /sys e /efi  no diretorio /mnt." 10 50

    #Monta a partição riso presente no disco.(ex:sda1)

    mount ${RISO} /mnt

    mount ${EFI} /mnt/boot/efi

    for i in /sys /proc /dev; do mount --bind ${i} /mnt${i}; done

    dialog --sleep 5  --infobox " As partições foram montadas com sucesso." 10 50

    dialog --sleep 5  --infobox " Instalando e atualizando o GRUB." 10 50

    #Instala e atualiza o grub na partição montada no diretório /mnt

    chroot /mnt grub-install ${DEVICE}

    chroot /mnt update-grub

    dialog --sleep 5  --infobox " O GRUB foi instalado e atualizado com sucesso." 10 50

    dialog --sleep 5  --infobox " Desmontando as partições do diretório /mnt..." 10 50

    # Desmonta as partições montadas no diretório /mnt

    for i in /sys /proc /dev; do umount /mnt${i}; done

    umount ${EFI}

    umount ${RISO}

    dialog --sleep 5  --infobox " As partições foram desmontadas com sucesso." 10 50

    dialog --sleep 5  --infobox " A atribuição da UUID padrão nas partições foi concluída com sucesso." 10 50

}

trocar_rotulos(){

    carregar_variaveis;

    dialog --sleep 5  --infobox " Trocando o rótulo das partições." 10 50

    mkfs.${SA_PARTEFI} -n "EFI" ${EFI}

    e2label ${RISO} "RISO"

    ntfslabel ${WINDOWS} "WINDOWS"

    e2label ${LINUX} "LINUX"

    ntfslabel ${DADOS} "DADOS"

    mk${SA_PARTSWAP} -L "SWAP" ${SWAP}


    dialog --sleep 5  --infobox " O rótulo das partições foram trocados com sucesso." 10 50
}

menu() {

    while : ; do

    OPCAO=$(dialog --stdout\
    --ok-label 'Confirmar'\
    --cancel-label 'Sair'\
    --title "INSTALAÇÃO DO RISO UEFI ${VERSION}"\
    --menu 'Selecione uma opção:'\
    0 0 0\
    1 'Aplicar tabela de particionamento'\
    2 'Atualizar a partição RISO'\
    3 'Formatar a partição EFI'\
    4 'Formatar a partição RISO'\
    5 'Formatar a partição WINDOWS'\
    6 'Formatar a partição LINUX'\
    7 'Formatar a partição DADOS'\
    8 'Instalar a UUID nas partições'\
    9 "Instalar o RISO UEFI ${VERSION}"\
    10 'Trocar o rótulo das partições')

    [ $? -ne 0 ] && break

    case ${OPCAO} in

    1) aplica_tabela_particionamento;;

    2) atualiza_riso;;

    3) formatar_efi;;

    4) formatar_riso && formatar_swap;;

    5) formatar_windows;;

    6) formatar_linux && formatar_swap;;

    7) formatar_dados;;

    8) instalar_UUID;;

    9) instalar_riso;;

    10) trocar_rotulos;;


    esac

    done
}

#Verifica se o usuário é o root antes de executar o menu e caso o usuário não seja o root termina a execução.

    if [ $(id -u) -ne "0" ]; then

    dialog --sleep 5  --infobox " Este script deve ser executado pelo usuário root. Execute-o novamente" 10 50

    exit 1

    else

    menu

    fi
