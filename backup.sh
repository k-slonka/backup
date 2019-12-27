#!/bin/bash
ADD=false
REMOVE=false
BACKUP_NOW=false
UPDATE=false
INF=false
touch backup.lst 

function pytania_przy_kopiowaniu(){
  DATE=`date '+%Y-%m-%d-%H-%M-%S'`
  serwer=$(tail -n +2 pomoc)
  echo Czy chcesz dokonać kopii na ten serwer:$serwer?yes/no
  read odpowiedz
  if [[ $odpowiedz == no ]]
     then
     echo Podaj nazwe serwera.
     read serwer
fi
  echo wprowadź hasło:
  read haslo
  echo $DATE> pomoc
  echo $serwer>> pomoc
  ilosc_lini=$(grep -c '.' backup.lst)
}

function kopia_zaktualizowana(){
if [ -d $1 ] #sprawdza czy jest folderem
  then
  for j in `ls $1`
     do
     cala_sciezka=$1/$j #tworzy ścieżkę	
     kopia_zaktualizowana $cala_sciezka		
  done		
else
  data_modyfikacji_pliku=$(ls -l $1 | awk '{print $6, $7}')
  pomoc=$(ls -l pomoc | awk '{print $6, $7}')
  if [[ $data_modyfikacji_pliku > $pomoc ]]
     then
     echo Podaj lokalizaje pliku
     read OPTARG
     do_kopiowania=$1
     pytania_przy_kopiowaniu $OPTARG
sshpass -p $haslo rsync -a --rsync-path="mkdir -p $OPTARG/$DATE/$1 && rsync" $1 $serwer:$OPTARG/$DATE/$1
  fi
fi	
}

while getopts ":a:r:b:uh" OPT; do
case $OPT in
a) ADD=$OPTARG
BEZWZG=$(echo $OPTARG | grep -c '^/.*')
if [[ $BEZWZG == 0 ]]
  then
  WZG=$(pwd)/$OPTARG		
else
  WZG=$OPTARG
fi
katalog_nadrzedny=$( dirname $WZG )
sprawdzanie_listy=$(grep -c ^"$katalog_nadrzedny"$ backup.lst) #sprawdza czy w pliku backup.lst znajduje się ścieżka z katalogiem nadrzędnym
sprawdzanie_listy2=$(grep -c ^"$WZG"$ backup.lst) #sprawdza czy w pliku backup.lst znajduje się podana ścieżka
if [[ $sprawdzanie_listy == 0 && $sprawdzanie_listy2 == 0 ]]
then
echo $WZG>> backup.lst
fi ;;

r) REMOVE=$OPTARG
BEZWZG=$(echo $OPTARG | grep -c '^/.*')
if [[ $BEZWZG == 0 ]]
  then
  WZG=$(pwd)/$OPTARG		
  else
  WZG=$OPTARG
fi
grep -v ^"$WZG"$ backup.lst> pomoclista.lst 
rm backup.lst
cat pomoclista.lst> backup.lst
rm pomoclista.lst
pusty=$(grep -c '.' backup.lst)
if [[ $pusty == 0 ]]
  then 
  rm backup.lst
fi;;

b)BACKUP_NOW=$OPTARG
pytania_przy_kopiowaniu $OPTARG
for ((i=1; i<=$ilosc_lini; i++))
  do
  a=$i-1 
  do_kopiowania=$(head -n $i backup.lst | tail -n +$i)
  echo $DATE> pomoc
  echo $serwer>> pomoc
  sshpass -p $haslo rsync -a --rsync-path="mkdir -p $OPTARG/$DATE/$do_kopiowania && rsync" $do_kopiowania $serwer:$OPTARG/$DATE/$do_kopiowania
done
;;

u)UPDATE=$OPTARG
serwer=$(head -n -1 pomoc)
ilosc_lini=$(grep -c '.' backup.lst)
for ((i=1; i<=$ilosc_lini; i++))
  do 
  do_kopiowania=$(head -n $i backup.lst | tail -n +$i)
  data_modyfikacji_pliku=$(ls -l $do_kopiowania | awk '{print $6, $7}')
  kopia_zaktualizowana $do_kopiowania
done;;

h)INF=true
echo -e "Autorem skryptu jest Karolina Słonka.\n""Skrypt ma na celu wykonanie kopii zpasowych plików oraz folderów, kopiując je na zdalny serwer za pomocą protokołu ssh.\n OPCJE\n-a   argument występujący bezpośrednio po tej opcji to element, który zostanie dopisany do listy w  pliku backup.lst\n-r   argument występujący bezpośrednio po tej opcji to element, który zostanie usunięty z listy w pliku backup.lst\n-b    argument występujący bezpośrednio po tej opcji to lokalizacja(ścieżka pliku) w której zostanie zapisana kopia. W pliku pomoc zapisywany jest serwer, na który ostatanio była wysyłana kopia\n-u   wykonanie kopi zapasowej jedynie tych elementów objętych ścieżkami w pliku .backup.lst, które zostały utworzone lub zmodyfikowane od czasu wykonania ostatniej kopii zapasowej\n-h   wyświetlanie informacji o autorze oraz krótkiej instrukcji użycia skryptu"
;;
\?) 
echo "źle: - $OPTARG" >&2
exit 1 ;;
:) 
echo "opcja -$OPTARG wymaga argumentu.">&2
shift;;
esac
done
