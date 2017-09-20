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

DIRNAME=`dirname $0`

DEVICE=$1

TABLE=$2

atualiza_recovery() {

    carregar_variaveis;

    echo -e '\033[31m Atualizando e Formatando a partição RECOVERY e atribuindo a UUID padrão...\n\033[m'
    
    # Formata a partição recovery, trocando a UUID

    mkfs.${sa_partrecovery} -Fq -O ^metadata_csum -U ${partrecovery,,} -L "RECOVERY" $RECOVERY

    echo -e '\033[31m A Formatação da partição RECOVERY foi realizada com sucesso.\n\033[m'

    #Restaura a partição recovery a partir do arquivo recovey.tar.bz2 presente no pendrive na segunda partição (ex:sdb2)

    mount $RECOVERY /mnt

    echo -e '\033[31m Restaurando a partição RECOVERY...\n\033[m'

    tar -jxf recovery.tar.bz2 -C /mnt

    echo -e '\033[31m A Partição RECOVERY foi restaurada com sucesso.\n\033[m'

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

    echo -e '\033[31m A Atualização da partição RECOVERY foi finalizada com sucesso.\n\033[m'

    echo -e '\033[31m Retornando ao menu principal...\n\033[m'   

    sleep 5

    menu

}

# Carrega as variáveis do arquivo riso.cfg

carregar_variaveis() {
    
    source $DIRNAME/riso-EFI.cfg
    
    return 0
}

formatar_efi() {
    
    carregar_variaveis;
    
    echo -e '\033[31m Formatando a partição EFI e atribuindo a UUID padrão...\n\033[m'
    
    # Formata a partição EFI, atribuindo a UUID e rótulo
    
    mkfs.${sa_partefi} -F 32 -i `echo ${partefi^^} | tr -d -` -n "EFI" $EFI
    
    echo -e '\033[31m A Formatação da partição EFI concluída com sucesso.\n\033[m'
    
    echo -e '\033[31m Retornando ao menu principal...\n\033[m'   

    sleep 5

    menu
}

formatar_recovery() {
    
    carregar_variaveis;
    
    echo -e '\033[31m Formatando a partição RECOVERY e atribuindo a UUID padrão...\n\033[m'
    
    # Formata a partição recovery, atribuindo a UUID e rótulo
    
    e2fsck -f $RECOVERY -y
    
    mkfs.${sa_partrecovery} -Fq -O ^metadata_csum -U ${partrecovery,,} -L "RECOVERY" $RECOVERY
    
    echo -e '\033[31m A Formatação da partição RECOVERY concluída com sucesso.\n\033[m'
    
    return 0
}

formatar_windows() {

    carregar_variaveis;
    
    echo -e '\033[31m Formatando a partição WINDOWS e atribuindo a UUID padrão...\n\033[m'
    
    #Formata a partição windows, atribuindo a UUID e rótulo
    
    mkfs.${sa_partwindows} -f -Fq  -L "WINDOWS" $WINDOWS

    u=${partwindows^^}

    echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2} | xxd -r -p | dd of=$WINDOWS bs=8 count=1 seek=9
    
    echo -e '\033[31m A Formatação da partição WINDOWS foi concluída com sucesso.\n\033[m'
    
    echo -e '\033[31m Retornando ao menu principal...\n\033[m'    

    sleep 5

    menu
}

formatar_linux() {
    
    carregar_variaveis;
    
    echo -e '\033[31m Formatando a partição LINUX e atribuindo a UUID padrão...\n\033[m'
    
    #Formata a partição linux, trocando a UUID e rótulo
    
    e2fsck -f $LINUX -y

    mkfs.${sa_partlinux} -Fq -O ^metadata_csum -U ${partlinux,,} -L "LINUX" $LINUX
    
    echo -e '\033[31m A Formatação da partição LINUX foi concluída com sucesso.\n\033[m'
    
    return 0
}

formatar_dados() {
    
    carregar_variaveis;
    
    echo -e '\033[31m Formatando a partição DADOS e atribuindo a UUID padrão...\n\033[m'
    
    #Formata a partição dados, trocando a UUID e rótulo

    mkfs.${sa_partdados} -f -Fq -L "DADOS" $DADOS

    u=${partdados^^}

    echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2} | xxd -r -p | dd of=$DADOS bs=8 count=1 seek=9

    echo -e '\033[31m A Formatação da partição DADOS foi concluída com sucesso.\n\033[m'
    
    echo -e '\033[31m Retornando ao menu principal...\n\033[m'    

    sleep 5

    menu
}

formatar_swap() {

    # Desliga a swap
    
    swapoff -a    
    
    carregar_variaveis;
    
    echo -e '\033[31m Formatando a partição SWAP e atribuindo a UUID padrão...\n\033[m'
    
    #Formata a partição swap, trocando a UUID e rótulo
    
    mk${sa_partswap} -U ${partswap,,} -L "SWAP" $SWAP    

    echo -e '\033[31m A Formatação da partição SWAP foi concluída com sucesso.\n\033[m'
    
    echo -e '\033[31m Retornando ao menu principal...\n\033[m'   

    sleep 5

    menu
}

instalar_UUID() {

    carregar_variaveis;
    
    echo -e '\033[31m Atribuindo a UUID padrão nas partições...\n\033[m'

    # Atribuindo a UUID na partição EFI

    # Atribuindo a UUID a partição recovery

    e2fsck -f $RECOVERY -y
    
    tune2fs -U ${partrecovery,,} $RECOVERY

    # Atribui a UUID na partição windows

    u=${partwindows^^}

    echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2} | xxd -r -p | dd of=$WINDOWS bs=8 count=1 seek=9

    # Atribui a UUID na partição linux

    e2fsck -f $LINUX -y
    
    tune2fs -U ${partlinux,,} $LINUX

    # Atribui a UUID na partição dados

    u=${partdados^^}

    echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2}| xxd -r -p | dd of=$DADOS bs=8 count=1 seek=9

    # Atribui a UUID na partição swap

    mk${sa_partswap} -U ${partswap,,} -L "SWAP" $SWAP

    echo -e '\033[31m Atribuição da UUID padrão nas partições realizada com sucesso.\n\033[m'

    sleep 5

    echo -e '\033[31m Montando as partições recovery, /dev, /proc, /sys e /efi  no diretorio /mnt...\n\033[m'

    #Monta a partição recovery presente no disco.(ex:sda1)

    mount $RECOVERY /mnt
    
    mount $EFI /mnt/boot/efi
    
    for i in /sys /proc /dev; do mount --bind $i /mnt$i; done

    echo -e '\033[31m As Partições foram montadas com sucesso.\n\033[m'

    sleep 5

    echo -e '\033[31m Instalando e atualizando o GRUB...\n\033[m'

    #Instala e atualiza o grub na partição montada no diretório /mnt

    chroot /mnt grub-install $DEVICE
    
    chroot /mnt update-grub
 
    echo -e '\033[31m O GRUB foi instalado e atualizado com sucesso.\n\033[m'

    sleep 5

    echo -e '\033[31m Desmontando as partições montadas no diretório /mnt...\n\033[m'

    # Desmonta as partições montadas no diretório /mnt
    
    for i in /sys /proc /dev; do umount /mnt$i; done
    
    umount $EFI
    
    umount $RECOVERY

    echo -e '\033[31m As Partições foram desmontadas com sucesso.\n\033[m'

    sleep 5

    echo -e '\033[31m A atribuição da UUID padrão nas partições foi finalizada com sucesso.\n\033[m'

    echo -e '\033[31m Retornando ao menu principal...\n\033[m'   

    sleep 5

    menu    
        
}

instalar_recovery(){

    carregar_variaveis;

    echo -e '\033[31m Instalando o Riso Recovery e atribuindo a UUID padrão...\n\033[m'

    # Desliga a swap
    
    swapoff -a

    # Aplica a tabela de particionamento ao disco, "sgdisk" comando de atribuição de partição do padrão gpt,"-g" força a mudança da tabela de partição para gpt, 
    
    # "--load-backup=" aponta para o arquivo com as partições $TABLE (ex: HD500.gpt) e aplica no disco $DEVICE (ex: /dev/sda)

    sgdisk -g --load-backup=$TABLE $DEVICE

    # Formata a partição EFI, trocando a UUID

    mkfs.${sa_partefi} -F 32 -i `echo ${partefi^^} | tr -d -` -n "EFI" $EFI

    # Formata a partição recovery, trocando a UUID

    mkfs.${sa_partrecovery} -Fq -O ^metadata_csum -U ${partrecovery,,} -L "RECOVERY" $RECOVERY

    #Formata a partição windows, trocando a UUID.

    mkfs.${sa_partwindows} -f -Fq  -L "WINDOWS" $WINDOWS

    u=${partwindows^^}

    echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2}| xxd -r -p | dd of=$WINDOWS bs=8 count=1 seek=9

    #Formata a partição linux, trocando a UUID

    mkfs.${sa_partlinux} -Fq -O ^metadata_csum -U ${partlinux,,} -L "LINUX" $LINUX

    # Formata a partição Dados

    mkfs.${sa_partdados} -f -Fq -L "DADOS" $DADOS

    u=${partdados^^}

    echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2}| xxd -r -p | dd of=$DADOS bs=8 count=1 seek=9

    # Formata a partição swap, trocando a UUID

    mk${sa_partswap} -U ${partswap,,} -L "SWAP" $SWAP

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

    echo -e '\033[31m A instalação do Riso Recovery foi finalizada com sucesso.\n\033[m'

    echo -e '\033[31m Retornando ao menu principal...\n\033[m'    

    sleep 5

    menu
}

menu() {  

clear

echo -e '\033[33m ===========================================\n\033[m'

echo -e '\033[33m Instalação do RISO-RECOVERY...\n\033[m'

echo -e '\033[33m ===========================================\n\033[m'

echo -e '\033[33m 1) Atualizar a partição RECOVERY\n\033[m'

echo -e '\033[33m 2) Formatar Partição EFI\n\033[m'

echo -e '\033[33m 3) Formatar Partição RECOVERY\n\033[m'

echo -e '\033[33m 4) Formatar Partição WINDOWS\n\033[m'

echo -e '\033[33m 5) Formatar Partição LINUX\n\033[m'

echo -e '\033[33m 6) Formatar Partição DADOS\n\033[m'

echo -e '\033[33m 7) Instalar RISO RECOVERY\n\033[m'

echo -e '\033[33m 8) Instalar UUID nas partições\n\033[m'

echo -e '\033[33m 9) Sair\n\033[m'

echo -e '\033[33m ===========================================\n\033[m'

echo -e '\033[33m Escolha uma das opções acima\n\033[m'

read opcao

case $opcao in

1)
    atualiza_recovery;;

2) 
    formatar_efi;;
                                    
3)
    formatar_recovery && formatar_swap;;
                                        
4)
    formatar_windows;;
                                    
5)
    formatar_linux && formatar_swap;;
                                    
6)
    formatar_dados;;
                            
7)
    instalar_recovery;;
                            
8)
    instalar_UUID;;                            

9)

echo -e '\033[33m Saindo...!\n\033[m'

exit ;;

*) echo -e '\033[33m Opção desconhecida... Abortando o programa!!!\n\033[m' 

exit;;

esac

}
          
#Verifica se o usuário é o root antes de executar o menu e caso o usuário não seja root termina a execução.

if [ $(id -u) -ne "0" ];

then

	echo -e '\033[31m Este script deve ser executado com o usuário root.\n\033[m'
	
	exit 1

else

    menu

fi