#!/bin/bash

# --------------------------------------------------------------------------
# Arquivo de instalação do sistema RISO-RECOVERY EFI
# --------------------------------------------------------------------------

# Verifica parâmetros do disco (ex:/dev/sda) e arquivo de particionamento (ex: HD500.gpt)

if [ $# -ne 2 ]; then

# As configurações do "echo" utilizam códigos de cores e tabulação com quebra de linha são eles: 
# "\033[31m" e "\033[m" são responsáveis por colorir a letra em vermelho, "\n" é responsável por pular uma linha

    echo -e '\033[31m Exemplo de utilização do script: ./recovery.sh /dev/sda HD500.gpt\n\033[m';

   exit 1;
fi

# Define as variáveis DIRNAME, DEVICE e TABLE a partir dos parâmetros do disco e arquivo de particionamento.

DIRPATH=`dirname $0`

DEVICE=$1

TABLE=$2

VERSION=`cat $DIRPATH/riso.version`

atualiza_recovery() {

    carregar_variaveis;

    echo -e '\033[31m Formatando a partição RECOVERY...\n\033[m'
    
    # Formata a partição recovery, trocando a UUID

    mkfs.${SA_PARTRECOVERY} -Fq -O ^metadata_csum -U ${PARTRECOVERY,,} -L "RECOVERY" $RECOVERY

    echo -e '\033[31m A formatação da partição RECOVERY foi concluída com sucesso.\n\033[m'

    #Restaura a partição recovery a partir do arquivo recovey.tar.bz2 presente no pendrive na segunda partição (ex:sdb2)

    mount $RECOVERY /mnt

    echo -e '\033[31m Restaurando a partição RECOVERY...\n\033[m'

    tar -jxf recovery.tar.bz2 -C /mnt

    echo -e '\033[31m A restauração da partição RECOVERY foi concluída com sucesso.\n\033[m'

    echo -e '\033[31m Instalando e atualizando o GRUB...\n\033[m'
    
    #Instala o grub na partição montada no diretório /mnt

    mkdir -p /mnt/boot/efi

    mount $EFI /mnt/boot/efi

    for i in /sys /proc /dev; do mount --bind $i /mnt$i; done

    chroot /mnt grub-install $DEVICE

    chroot /mnt update-grub

    for i in /sys /proc /dev; do umount /mnt$i; done

    umount $EFI

    umount $RECOVERY
    
    echo -e '\033[31m O GRUB foi instalado e atualizado com sucesso...\n\033[m'

    sleep 5

}

# Carrega as variáveis do arquivo riso.cfg

carregar_variaveis() {
    
    source $DIRPATH/riso-EFI.cfg
    
    return 0
}

formatar_dados() {
    
    carregar_variaveis;
    
    echo -e '\033[31m Formatando a partição DADOS...\n\033[m'
    
    #Formata a partição dados, trocando a UUID e rótulo

    mkfs.${SA_PARTDADOS} -f -Fq -L "DADOS" $DADOS

    u=${PARTDADOS^^}

    echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2} | xxd -r -p | dd of=$DADOS bs=8 count=1 seek=9

    echo -e '\033[31m A Formatação da partição DADOS foi concluída com sucesso.\n\033[m'
    
    sleep 5

}

formatar_efi() {
    
    carregar_variaveis;
    
    echo -e '\033[31m Formatando a partição EFI...\n\033[m'
    
    # Formata a partição EFI, atribuindo a UUID e rótulo
    
    mkfs.${SA_PARTEFI} -F 32 -i `echo ${PARTEFI^^} | tr -d -` -n "EFI" $EFI
    
    echo -e '\033[31m A Formatação da partição EFI concluída com sucesso.\n\033[m'
    
    sleep 5

}

formatar_linux() {
    
    carregar_variaveis;
    
    echo -e '\033[31m Formatando a partição LINUX...\n\033[m'
    
    #Formata a partição linux, trocando a UUID e rótulo
    
    e2fsck -f $LINUX -y

    mkfs.${SA_PARTLINUX} -Fq -O ^metadata_csum -U ${PARTLINUX,,} -L "LINUX" $LINUX
    
    echo -e '\033[31m A Formatação da partição LINUX foi concluída com sucesso.\n\033[m'
    
    sleep 5

}

formatar_recovery() {
    
    carregar_variaveis;
    
    echo -e '\033[31m Formatando a partição RECOVERY...\n\033[m'
    
    # Formata a partição recovery, atribuindo a UUID e rótulo
    
    e2fsck -f $RECOVERY -y
    
    mkfs.${SA_PARTRECOVERY} -Fq -O ^metadata_csum -U ${PARTRECOVERY,,} -L "RECOVERY" $RECOVERY
    
    echo -e '\033[31m A Formatação da partição RECOVERY foi concluída com sucesso.\n\033[m'
    
    sleep 5

}

formatar_swap() {

    # Desliga a swap
    
    swapoff -a    
    
    carregar_variaveis;
    
    echo -e '\033[31m Formatando a partição SWAP...\n\033[m'
    
    #Formata a partição swap, trocando a UUID e rótulo
    
    mk${SA_PARTSWAP} -U ${PARTSWAP,,} -L "SWAP" $SWAP    

    echo -e '\033[31m A Formatação da partição SWAP foi concluída com sucesso.\n\033[m'
    
    sleep 5

}

formatar_windows() {

    carregar_variaveis;
    
    echo -e '\033[31m Formatando a partição WINDOWS...\n\033[m'
    
    #Formata a partição windows, atribuindo a UUID e rótulo
    
    mkfs.${SA_PARTWINDOWS} -f -Fq  -L "WINDOWS" $WINDOWS

    u=${PARTWINDOWS^^}

    echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2} | xxd -r -p | dd of=$WINDOWS bs=8 count=1 seek=9
    
    echo -e '\033[31m A Formatação da partição WINDOWS foi concluída com sucesso.\n\033[m'
    
    sleep 5

}

instalar_recovery(){

    carregar_variaveis;

    echo -e '\033[31m Instalando o RISO RECOVERY UEFI...\n\033[m'

    # Desliga a swap
    
    swapoff -a

    # Aplica a tabela de particionamento ao disco, "sgdisk" comando de atribuição de partição do padrão gpt,"-g" força a mudança da tabela de partição para gpt, 
    
    # "--load-backup=" aponta para o arquivo com as partições $TABLE (ex: HD500.gpt) e aplica no disco $DEVICE (ex: /dev/sda)

    sgdisk -g --load-backup=$TABLE $DEVICE

    # Formata a partição EFI, trocando a UUID

    mkfs.${SA_PARTEFI} -F 32 -i `echo ${PARTEFI^^} | tr -d -` -n "EFI" $EFI

    # Formata a partição recovery, trocando a UUID

    mkfs.${SA_PARTRECOVERY} -Fq -O ^metadata_csum -U ${PARTRECOVERY,,} -L "RECOVERY" $RECOVERY

    #Formata a partição windows, trocando a UUID.

    mkfs.${SA_PARTWINDOWS} -f -Fq  -L "WINDOWS" $WINDOWS

    u=${PARTWINDOWS^^}

    echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2}| xxd -r -p | dd of=$WINDOWS bs=8 count=1 seek=9

    #Formata a partição linux, trocando a UUID

    mkfs.${SA_PARTLINUX} -Fq -O ^metadata_csum -U ${PARTLINUX,,} -L "LINUX" $LINUX

    # Formata a partição Dados

    mkfs.${SA_PARTDADOS} -f -Fq -L "DADOS" $DADOS

    u=${PARTDADOS^^}

    echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2}| xxd -r -p | dd of=$DADOS bs=8 count=1 seek=9

    # Formata a partição swap, trocando a UUID

    mk${SA_PARTSWAP} -U ${PARTSWAP,,} -L "SWAP" $SWAP

    #Restaura a partição recovery a partir do arquivo recovey.tar.bz2 presente no pendrive na segunda partição (ex:sdb2)

    mount $RECOVERY /mnt

    echo -e '\033[31m Restaurando a partição RECOVERY...\n\033[m'

    tar -jxf recovery.tar.bz2 -C /mnt

    echo -e '\033[31m A Partição RECOVERY foi restaurada com sucesso.\n\033[m'

    #Instala o grub na partição montada no diretório /mnt

    mkdir -p /mnt/boot/efi

    mount $EFI /mnt/boot/efi

    #alterando para uma forma mais inteligente de montar as pastas

    for i in /sys /proc /dev; do mount --bind $i /mnt$i; done

    chroot /mnt grub-install $DEVICE

    chroot /mnt update-grub

    #alterando para uma forma mais inteligente de desmontar as pastas

    for i in /sys /proc /dev; do umount /mnt$i; done

    umount $EFI

    umount $RECOVERY

    echo -e '\033[31m A instalação do RISO RECOVERY UEFI foi concluída com sucesso.\n\033[m'

    sleep 5
    
    reboot

}

instalar_UUID() {

    carregar_variaveis;
    
    echo -e '\033[31m Atribuindo a UUID padrão nas partições...\n\033[m'

    # Atribuindo a UUID na partição EFI

    # Atribuindo a UUID a partição recovery

    e2fsck -f $RECOVERY -y
    
    tune2fs -U ${PARTRECOVERY,,} $RECOVERY

    # Atribui a UUID na partição windows

    u=${PARTWINDOWS^^}

    echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2} | xxd -r -p | dd of=$WINDOWS bs=8 count=1 seek=9

    # Atribui a UUID na partição linux

    e2fsck -f $LINUX -y
    
    tune2fs -U ${PARTLINUX,,} $LINUX

    # Atribui a UUID na partição dados

    u=${PARTDADOS^^}

    echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2}| xxd -r -p | dd of=$DADOS bs=8 count=1 seek=9

    # Atribui a UUID na partição swap

    mk${SA_PARTSWAP} -U ${PARTSWAP,,} -L "SWAP" $SWAP

    echo -e '\033[31m A atribuição da UUID padrão nas partições foi concluída com sucesso.\n\033[m'

    echo -e '\033[31m Montando as partições recovery, /dev, /proc, /sys e /efi  no diretorio /mnt...\n\033[m'

    #Monta a partição recovery presente no disco.(ex:sda1)

    mount $RECOVERY /mnt
    
    mount $EFI /mnt/boot/efi
    
    for i in /sys /proc /dev; do mount --bind $i /mnt$i; done

    echo -e '\033[31m As Partições foram montadas com sucesso.\n\033[m'

    echo -e '\033[31m Instalando e atualizando o GRUB...\n\033[m'

    #Instala e atualiza o grub na partição montada no diretório /mnt

    chroot /mnt grub-install $DEVICE
    
    chroot /mnt update-grub
 
    echo -e '\033[31m O GRUB foi instalado e atualizado com sucesso.\n\033[m'

    echo -e '\033[31m Desmontando as partições montadas no diretório /mnt...\n\033[m'

    # Desmonta as partições montadas no diretório /mnt
    
    for i in /sys /proc /dev; do umount /mnt$i; done
    
    umount $EFI
    
    umount $RECOVERY

    echo -e '\033[31m As Partições foram desmontadas com sucesso.\n\033[m'

    echo -e '\033[31m A atribuição da UUID padrão nas partições foi concluída com sucesso.\n\033[m'

    sleep 5

}

menu() {  

    while : ; do

    opcao=$(dialog --stdout\
    --ok-label 'Confirmar'\
    --cancel-label 'Sair'\
    --title "Instalação do RISO RECOVERY UEFI - ${VERSION}"\
    --menu 'Selecione uma opção:'\
    0 60 0\
    1 'Atualizar a partição RECOVERY'\
    2 'Formatar a partição EFI'\
    3 'Formatar a partição RECOVERY'\
    4 'Formatar a partição WINDOWS'\
    5 'Formatar a partição LINUX'\
    6 'Formatar a partição DADOS'\
    7 'Instalar o RISO RECOVERY UEFI'\
    8 'Instalar a UUID nas partições')

    [ $? -ne 0 ] && break
   
    case $opcao in

    1) atualiza_recovery;;

    2) formatar_efi;;
                                        
    3) formatar_recovery && formatar_swap;;
                                            
    4) formatar_windows;;
                                        
    5) formatar_linux && formatar_swap;;
                                        
    6) formatar_dados;;
                                
    7) instalar_recovery;;
                                
    8) instalar_UUID;;                            

    esac
    
    done
}
          
#Verifica se o usuário é o root antes de executar o menu e caso o usuário não seja root termina a execução.

    if [ $(id -u) -ne "0" ]; then

    echo -e '\033[31m Este script deve ser executado pelo usuário root. Execute o script novamente\n\033[m'

    exit 1

    else

    menu

    fi