/* Zawartość: Moduł zasilania hurtowni */
/* Autor: Magdalena Zych */

/* Dane do zarchiwizowania powinny znajdować się w folderze: "/folders/myfolders/dane_lab6/" */
/* Dane dla jednego sklepu i jednego dnia znajdują się w pliku: <rok><miesiąc><dzien>s<numer_sklepu>.xlsx */
/* W pliku tabele z następującymi atrybutami: data, godzina, product_it, ilosc i sklep_id */
/* Plik ze spisem produktow: "/folders/myfolders/produkty/spisProduktow.xlsx" w postaci: id, nazwa */

/* tworzenie biblioteki */
libname Lab6 "/folders/myfolders/lab6_folder";

/* Makro do wczytywania nazw (wszytskich) plikow z zadanego katalogu */
%macro fileList(directory=, out=);
 data &out;

  keep fileName fullDirectory;
  length fileName $256 fullDirectory $256 fileref $8;

  fileref = '        '; /* must be explicitly set to blank to have the filename function generate a fileref */
  rc = filename(fileref,"&directory"); /*  sets fileref */ 
  did = dopen(fileref); /*opens a directory and returns a directory identifier value (a number greater than 0) 
  					that is used to identify the open directory in other SAS external file access functions*/

  do i = 1 to dnum(did); /* dnum determines the highest possible member number that can be passed to DREAD - number of files in the directory */
    fileName = dread(did,i); /* Returns the name of a directory member */
    fullDirectory = '"' || "&directory" || fileName;
    fullDirectory = cats(fullDirectory, '"');
	%str(output;);
  end;

  rc = dclose(did); /* Closes a directory that was opened by the DOPEN function */ 
  rc = filename(fileref);
 run;

%mend fileList;

/* Wczytanie nazw plików z folderu o podanej sciezce do zbioru Lab6.files */
%fileList(directory=/folders/myfolders/dane_lab6/, out=Lab6.files);

/* Dodanie nowych wierszy (nazw znalezionych plikow) do zbioru Lab6.archivedFiles */
proc append 
	base=Lab6.archivedFiles data=Lab6.files;
run;

/* dodanie nowych zmiennych-flag do zbioru Lab6.files */
data Lab6.files;
	set Lab6.files;
	alreadyArchived = 0;
	successfullyRead = 0;
	blad_data = 0;
	blad_produkt_id = 0;
	blad_ilosc = 0;
	blad_id_sklepu = 0;	
run;

/* Posortowanie obserwacji w zbiorze Lab6.archivedFiles wdg nazw plikow - jesli sa tam 2 takie same nazwy to sa obok siebie */
proc sort data=Lab6.archivedFiles out=Lab6.archivedFiles;
   by fileName;
run;

data Lab6.files;
	set Lab6.files;
	fullDirectory = compress(fullDirectory, '"');
run;

/* Oznaczenie nazw plikow ktore juz wczesniej sie pojawily => isArchived=1, dla plikow ktore pojawiaja sie po raz 1 isArchived=2 */
data Lab6.archivedFiles;
        set Lab6.archivedFiles;
        if fileName = lag1(fileName)  then do;
        	isArchived = 1; 
        	call execute('
						proc sql;
						UPDATE Lab6.files t
   						SET alreadyArchived = 1
 						where t.fullDirectory = '||fullDirectory||';
						quit;
			');
        end; 
        else do;
        	isArchived = 2;
        end;  	
run;

/* Posortowanie obserwacji w zbiorze Lab6.archivedFiles */
proc sort data=Lab6.archivedFiles out=Lab6.archivedFiles;
   by fileName isArchived;
run;

/* Usunięcie nazw plików które pojawiły się podwójnie */
/* Dla pozostalych po usuwaniu plikow => jesli isArchived=1 to plik byl juz archiwizowany i nalezy go ignorowac */
/* Nalezy pobrac dane z plikow dla ktorych isArchived=2 */
data Lab6.archivedFiles;
        set Lab6.archivedFiles;
        if fileName = lag1(fileName) then delete;   	
run;

/* dodanie cudzyslowia do fileName w zbiorze Lab6.archivedFiles*/
data Lab6.archivedFiles;
	set Lab6.archivedFiles;
	fileName = cats('"', fileName);
	fileName = cats(fileName, '"');
run;

/* wczytywanie danych z plikow ktore nalezy zarchiwizowac */
/* Wczytuje dane i dopisuje z jakiego pliku pochodza, jeszcze nie sprawdzam ich poprawności */
data Lab6.archivedfiles;
set Lab6.archivedfiles; 
if isArchived=2 then do;
	/* importowanie pliku xlsx */
	call execute('
	proc import datafile= '||fullDirectory||' replace
		dbms=xlsx
		out=Lab6.wczytaneDane replace;
	run;
	');
	/* dodanie kolumny informujacej z ktorego pliku pochodza dane */
	call execute('
	proc sql;
		ALTER TABLE Lab6.wczytaneDane
   		ADD file varchar(256);

		UPDATE Lab6.wczytaneDane 
		SET file = '||fileName||';
	quit;
	');
	/* dodanie danych do zbioru w ktorym sprawdzana bedzie poprawnosc danych i ew. dane beda odrzucane */
	call execute('
	proc append 
		base=Lab6.content data=Lab6.wczytaneDane;
	run;
	');
end;

/* usuniecie ze zbioru content pustych obserwacji */
data Lab6.content;
	set Lab6.content;
	if Data = "." then delete;
	error = 0;
	existingProductId = 0;
run;

/* wczytanie id_produktow z pliku spisProduktow.xlsx do zbioru Lab6.produkty */
proc import datafile= "/folders/myfolders/produkty/spisProduktow.xlsx" replace
	dbms=xlsx
	out=Lab6.produkty replace;
run;

/* oznaczenie w zbiorze Lab6.content produktow ktorych id znajduje sie w zbiorze dostepnych produktow Lab6.produkty */
/* jesli id produktu istnieje to existingProductId=1, w p.p. existingProductId=0 */
data Lab6.produkty;
	set Lab6.produkty;
	call execute('
		proc sql;
			UPDATE Lab6.content tab  
   			SET existingProductId = 1
			where tab.produkt_id = '||id||';
		quit;
		');
run;

/* dodanie cudzyslowia dla zmiennej file w zbiorze Lab6.content */
data Lab6.content;
	set Lab6.content;
	file = cats('"', file);
	file = cats(file, '"');
run;

/* sprawdzanie poprawnosci wczytanych danych- zbior content, jesli dane sa bledne to wypisuje komunikat */
/* i oznaczam to w zmiennej error=1, gdy dane poprawne to error=0 */
data Lab6.content;
	set Lab6.content;
	
	/* data niezgodna z nazwa pliku */
	if Data NE  substr(file, 2, 8) then do;
		put 'BLAD (plik: ' file ') - data niezgodna z nazwa pliku: " ' Data '"';
		error = 1;
		call execute('
						proc sql;
						UPDATE Lab6.files t
   						SET blad_data = 1
 						where t.fileName = '||file||';
						quit;
			');
	end;
	
	/* nieistniejace id_produktu*/
	if existingProductId = 0 then do;
		put 'BLAD (plik: ' file ') - nieistniejace id produktu: " 'produkt_id'"';
		error = 1;
		call execute('
						proc sql;
						UPDATE Lab6.files t
   						SET blad_produkt_id = 1
 						where t.fileName = '||file||';
						quit;
			');
	end;
	
	/* niepoprawna (niedodatnia) ilosc */
	if ilosc < 1 then do;
		put 'BLAD (plik: ' file ') - niepoprawna (niedodatnia) ilosc: " 'Ilosc'"';
		error = 1;
		call execute('
						proc sql;
						UPDATE Lab6.files t
   						SET blad_ilosc = 1
 						where t.fileName = '||file||';
						quit;
			');
	end;
	
	/* podejrzanie duza ilosc */
	if ilosc > 1000000 then do;
		put 'BLAD (plik: ' file ') - podejrzanie duza ilosc: " 'Ilosc'"';
		error = 1;
		call execute('
						proc sql;
						UPDATE Lab6.files t
   						SET blad_ilosc = 1
 						where t.fileName = '||file||';
						quit;
			');
	end;
	
	/* id sklepu niezgodne z nazwa pliku */
	if Sklep_id NE  substr(file, 11, length(file)-16 ) then do;
		put 'BLAD (plik: ' file ') - id sklepu niezgodne z nazwa pliku: " 'Sklep_id'"';
		error = 1;
		call execute('
						proc sql;
						UPDATE Lab6.files t
   						SET blad_id_sklepu = 1
 						where t.fileName = '||file||';
						quit;
			');
	end;
run;

/* usuniecie cudzyslowia ze zmiennej file w zbiorze Lab6.content */
data Lab6.content;
	set Lab6.content;
	file = compress(file, '"');
run;

/* dodanie w zbiorze Lab6.archivedFiles zmiennej invalidData oraz filename2 - nazwa pliku bez znakow "" */
data Lab6.archivedFiles;
	set Lab6.archivedFiles;
	invalidData = 0;
	filename2 = compress(filename, '"');
run;

/* oznaczenie plikow czekajacych na archiwizacje ktore nie maja blednych danych przez invalidData=0, w p.p. invalidData > 0 */
data Lab6.archivedFiles;
	set Lab6.archivedFiles;
	if isArchived = 2 then do;
	call execute('
		proc sql;
			UPDATE Lab6.archivedFiles t
   			SET invalidData = (
								select count(*)
								from Lab6.content
								where file = '||fileName||' and error > 0
 					  			)
 			where t.fileName2 = '||fileName||';
		quit;
		');	
	end;
run;

/* usuwanie danych ktore sa w plikach z blednymi danymi */
data Lab6.archivedFiles;
	set Lab6.archivedFiles;
	if isArchived = 2 and invalidData > 0 then do;
	call execute('
		proc sql;
			delete from Lab6.content 
			where file = '||fileName||';
		quit;
		');	
	end;
run;


/* usuniecie ze zbioru Lab6.archivedFiles plikow w ktorych byly bledne dane i nie zostana one zarchiwizowane */
/* usuniecie znakow "" z fileName */
data Lab6.archivedFiles;
	set Lab6.archivedFiles;
	if invalidData > 0 then delete;
	fileName = compress(fileName, '"');
run;

/* usuniecie pomocniczych zmiennych ze zbiory Lab6.content */
data Lab6.content;
	set Lab6.content;
	drop file error existingProductId;
run;

/* dodanie danych z plikow bez bledow do pliku ze wszytkimi zarchiwizowanymi danymi */
proc append 
	base=Lab6.dataStore data=Lab6.content;
run;

/* wypisanie informacji o tym ktore pliki zostaly zarchiwizowane */	
data Lab6.archivedFiles;
	set Lab6.archivedFiles;
	if isArchived = 2 then do;
		put 'Zarchiwizowano plik ' fileName;
		call execute('
						proc sql;
						UPDATE Lab6.files t
   						SET successfullyRead = 1
 						where t.fullDirectory = '||fullDirectory||';
						quit;
			');
	end;
run;
		
/* usuniecie pomocniczych zmiennych ze zbioru Lab6.archivdFiles */
data Lab6.archivedFiles;
	set Lab6.archivedFiles;
	drop isArchived invalidData filename2;
run;

/* usuniecie pomocniczych zbiorow */
proc delete data = Lab6.content;
run;
proc delete data = Lab6.wczytaneDane;
run;