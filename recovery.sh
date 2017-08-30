#!/bin/bash

# Verifica parâmetros do disco (ex:/dev/sda) e arquivo de particionamento (ex: HD500.gpt)
if [ $# -ne 2 ]; then
   echo "Utilização: $0 [Disco] [Arquivo de Particionamento]";
   exit 1;
fi

# Define as variáveis DIRNAME, DEVICE e TABLE a partir dos parâmetros do disco e arquivo de particionamento.
DIRNAME=`dirname $0`
DEVICE=$1
TABLE=$2

# Define as partições para o padrão utilizado no riso (Partição 1 - Recovery, Partição 4 - Dados, Partição 5 - SWAP, Partição 6 - EFI)
RECOVERY=$DEVICE"1"
WINDOWS=$DEVICE"2"
LINUX=$DEVICE"3"
DADOS=$DEVICE"4"
SWAP=$DEVICE"5"
EFI=$DEVICE"6"

# Carrega as variáveis do arquivo riso.cfg
source $DIRNAME/riso.cfg

# Desliga a swap
swapoff -a

# Aplica a tabela de particionamento ao disco, "sgdisk" comando de atribuição de partição do padrão gpt,"-g" força a mudança da tabela de partição para gpt, 
# "--load-backup=" aponta para o arquivo com as partições $TABLE (ex: HD500.gpt) e aplica no disco $DEVICE (ex: /dev/sda)
sgdisk -g --load-backup=$TABLE $DEVICE

# Formata a partição recovery, trocando a UUID
mkfs.${sa_partrecovery} -Fq -O ^metadata_csum -U ${partrecovery,,} $RECOVERY

#Formata a partição windows, trocando a UUID.
mkfs.${sa_partwindows} -f -Fq  $WINDOWS
u=${partwindows^^}
echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2}| xxd -r -p | dd of=$WINDOWS bs=8 count=1 seek=9

#Formata a partição linux, trocando a UUID
mkfs.${sa_partlinux} -Fq -O ^metadata_csum -U ${partlinux,,} $LINUX

# Formata a partição Dados
mkfs.${sa_partdados} -f -Fq -L Dados $DADOS
u=${partdados^^}
echo ${u:14:2}${u:12:2}${u:10:2}${u:8:2}${u:6:2}${u:4:2}${u:2:2}${u:0:2}| xxd -r -p | dd of=$DADOS bs=8 count=1 seek=9

# Formata a partição swap, trocando a UUID
mk${sa_partswap} -U ${partswap,,} $SWAP

# Formata a partição EFI, trocando a UUID
mkfs.${sa_partefi} -F 32 -i `echo ${partefi^^} | tr -d -` $EFI

#Restaura a partição recovery a partir do arquivo recovey.tar.bz2 presente no pendrive na segunda partição (ex:sdb2)
mount $RECOVERY /mnt
echo "Restaurando partição RECOVERY..."
tar -jxf recovery.tar.bz2 -C /mnt
echo "Partição RECOVERY restaurada."

#Instala o grub na partição montada no diretório /mnt
mkdir -p /mnt/boot/efi
mount $EFI /mnt/boot/efi
#alterando para uma forma mais inteligente de montar as pastas
for i in /sys /proc /dev; do mount --bind $i /mnt$i; done
#mount --bind /dev/ /mnt/dev/
#mount --bind /proc/ /mnt/proc/
#mount --bind /sys/ /mnt/sys/

chroot /mnt grub-install $DEVICE
chroot /mnt update-grub
#alterando para uma forma mais inteligente de desmontar as pastas
for i in /sys /proc /dev; do umount /mnt$i; done
#umount /mnt/dev
#umount /mnt/proc
#umount /mnt/sys
umount $EFI
umount $RECOVERY

echo "Script finalizado."
