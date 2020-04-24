/* Zawartość: Moduł analityczny */
/* Autor: Magdalena Zych */

libname Lab8 "/folders/myfolders/lab8_folder";

/* ----------------tworzenie potrzebnych zbiorow------------------------------------- */
data Lab8.dataCopy;
	set Lab6.dataStore;
run;

 /* zmienna przedPol=1 gdy towar został sprzedany przed poludniem lub 0 gdy zostal sprzedany popoludniu */
/* dodanie do zbioru Lab8.dataCopy zmiennej najpozniejszaData */
data Lab8.dataCopy;
	set Lab8.dataCopy;
	if godzina < 43200 then pora = 'przed poludniem';
	else pora = 'po poludniu';
	najpozniejszaData = Data;
run;

/* zapisanie w zbiorze Lab8.najpozniejsza najpozniejszej daty znajdujacej sie w zbiorze Lab8.dataCopy */
proc means data = Lab8.dataCopy max noprint;
	var data;
	output out = Lab8.najpozniejsza(drop=_type_ _freq_) max= ;
run;

/* nadanie wartosci zmiennej najpozniejszaData */
proc sql;
	update Lab8.dataCopy
	set najpozniejszaData = (select Data from Lab8.najpozniejsza);
quit;

/* stworzenie zbioru w ktorym beda przechowywane informacje tylko z ostatniego dnia - najpozniejsza data w zbiorze Lab8.dataCopy */
data Lab8.lastDay;
	set Lab8.dataCopy;
	if data ne najpozniejszaData then delete;
run;

/* --------------------generowanie statystyk------------------------------- */
/* Liczba produktów sprzedanych w poszczególne dni */
/* statystyka zapisana w zbiorze Lab8.analiza1*/
proc means data = Lab8.dataCopy sum noprint;
	var ilosc;	
	output out = Lab8.analiza1(drop=_type_ _freq_) sum= ;
	class data;
run;

data Lab8.analiza1;
	set Lab8.analiza1;
	if data = '.' then delete;
run;

/* Liczba produktów sprzedanych w ostatnim dniu (bierzemy pod uwagę najpóźniejszą datę znajdującą się 
   w zbiorze Lab6.dataStore) w zależności od sklepu */
/* statystyka zapisana w zbiorze Lab8.analiza2*/
proc means data = Lab8.lastDay sum noprint;
	var ilosc;	
	output out = Lab8.analiza2(drop=_type_ _freq_) sum= ;
	class sklep_id;
run;

data Lab8.analiza2;
	set Lab8.analiza2;
	if sklep_id = '.' then delete;
run;

/* Liczba produktów sprzedanych w poszczególne dni w poszczególnych sklepach */
/* statystyka zapisana w zbiorze Lab8.analiza3*/
proc means data = Lab8.dataCopy sum noprint;
	var ilosc;	
	output out = Lab8.analiza3(drop=_type_ _freq_) sum= ;
	class Data sklep_id;
run;

data Lab8.analiza3;
	set Lab8.analiza3;
	if data = '.' or sklep_id = '.' then delete;
run;

/* Liczba produktów sprzedanych przed południem i po południu */
/* statystyka zapisana w zbiorze Lab8.analiza4*/
proc means data = Lab8.dataCopy sum noprint;
	var ilosc;	
	output out = Lab8.analiza4(drop=_type_ _freq_) sum= ;
	class pora;
run;

data Lab8.analiza4;
	set Lab8.analiza4;
	if pora = '' then delete;
run;

/* Liczba produktów sprzedanych przed południem i po południu w zależności od sklepu */
/* statystyka zapisana w zbiorze Lab8.analiza5*/
proc means data = Lab8.dataCopy sum noprint;
	var ilosc;	
	output out = Lab8.analiza5(drop=_type_ _freq_) sum= ;
	class sklep_id pora;
run;

data Lab8.analiza5;
	set Lab8.analiza5;
	if sklep_id = '.' or pora = '' then delete;
run;

/* Liczba produktów sprzedanych przed południem i po południu w ostatnim dniu */
/* statystyka zapisana w zbiorze Lab8.analiza6*/
proc means data = Lab8.lastDay sum noprint;
	var ilosc;	
	output out = Lab8.analiza6(drop=_type_ _freq_) sum= ;
	class pora;
run;

data Lab8.analiza6;
	set Lab8.analiza6;
	if pora = '' then delete;
run;

/* Liczba sprzedanych produktów o danym id */
/* statystyka zapisana w zbiorze Lab8.analiza7*/
proc means data = Lab8.dataCopy sum noprint;
	var ilosc;	
	output out = Lab8.analiza7(drop=_type_ _freq_) sum= ;
	class produkt_id;
run;

data Lab8.analiza7;
	set Lab8.analiza7;
	if produkt_id = '.' then delete;
run;

/* Liczba sprzedanych produktów o danym id w zależności od sklepu */
/* statystyka zapisana w zbiorze Lab8.analiza8*/
proc means data = Lab8.dataCopy sum noprint;
	var ilosc;	
	output out = Lab8.analiza8(drop=_type_ _freq_) sum= ;
	class produkt_id sklep_id;
run;

data Lab8.analiza8;
	set Lab8.analiza8;
	if produkt_id = '.' or sklep_id = '.' then delete;
run;

/* Liczba produktów o danym id sprzedanych w ostatnim dniu */
/* statystyka zapisana w zbiorze Lab8.analiza9*/
proc means data = Lab8.lastDay sum noprint;
	var ilosc;	
	output out = Lab8.analiza9(drop=_type_ _freq_) sum= ;
	class produkt_id;
run;

data Lab8.analiza9;
	set Lab8.analiza9;
	if produkt_id = '.' then delete;
run;

/* Liczba produktów o danym id sprzedanych w ostatnim dniu w zależności od sklepu */
/* statystyka zapisana w zbiorze Lab8.analiza10*/
proc means data = Lab8.lastDay sum noprint;
	var ilosc;	
	output out = Lab8.analiza10(drop=_type_ _freq_) sum= ;
	class produkt_id sklep_id;
run;

data Lab8.analiza10;
	set Lab8.analiza10;
	if produkt_id = '.' or sklep_id = '.' then delete;
run;

/* Liczba sprzedanych produktów w zależności od sklepu */
/* statystyka zapisana w zbiorze Lab8.analiza11*/
proc means data = Lab8.dataCopy sum noprint;
	var ilosc;	
	output out = Lab8.analiza11(drop=_type_ _freq_) sum= ;
	class sklep_id;
run;

data Lab8.analiza11;
	set Lab8.analiza11;
	if sklep_id = '.' then delete;
run;

/* --------------------generowanie histogramów i wykresow------------------------------- */

title 'Liczba produktów sprzedanych w poszczególne dni';
proc sgplot data = Lab8.analiza1; 
	vbar Data/response=Ilosc dataskin=pressed;                                                                                              
run;

title 'Liczba produktów sprzedanych w ostatnim dniu w zależności od sklepu';
proc sgplot data = Lab8.analiza2; 
	vbar Sklep_id/response=Ilosc dataskin=pressed;                                                                                              
run;

title 'Liczba sprzedanych produktów w poszczególnych sklepach w zależności od daty';
proc sgplot data = Lab8.analiza3; 
	vbar Data/response=Ilosc group=Sklep_id groupdisplay=cluster dataskin=pressed;                                                                                              
run;

title 'Liczba produktów sprzedanych po południu i przed południem';
proc sgplot data = Lab8.analiza4; 
	vbar pora/response=Ilosc dataskin=pressed;                                                                                              
run;

title 'Liczba produktów sprzedanych po południu i przed południem w zależności od sklepu';
proc sgplot data = Lab8.analiza5; 
	vbar Sklep_id/response=Ilosc group=pora groupdisplay=cluster dataskin=pressed;                                                                                               
run;

title 'Liczba produktów sprzedanych po południu i przed południem w ostatnim dniu';
proc sgplot data = Lab8.analiza6; 
	vbar pora/response=Ilosc dataskin=pressed;                                                                                               
run;

title 'Liczba sprzedanych produktów w zależności od id';
proc sgplot data = Lab8.analiza7; 
	vbar produkt_id/response=Ilosc dataskin=pressed;                                                                                               
run;

title 'Liczba produktów sprzedanych w danym sklepie zależności od id produktu';
proc sgplot data = Lab8.analiza8; 
	vbar produkt_id/response=Ilosc group=sklep_id groupdisplay=cluster dataskin=pressed;                                                                                               
run;

title 'Liczba produktów sprzedanych w ostatnim dniu w zależności od id';
proc sgplot data = Lab8.analiza9; 
	vbar produkt_id/response=Ilosc dataskin=pressed;                                                                                               
run;

title 'Liczba produktów sprzedanych w ostatnim dniu w danym sklepie w zależności od id produktu';
proc sgplot data = Lab8.analiza10; 
	vbar produkt_id/response=Ilosc group=sklep_id groupdisplay=cluster dataskin=pressed;                                                                                               
run;

title 'Liczba sprzedanych produktów w zależności od sklepu';
proc sgplot data = Lab8.analiza11; 
	vbar sklep_id/response=Ilosc dataskin=pressed;                                                                                               
run;