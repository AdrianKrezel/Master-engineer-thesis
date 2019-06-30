%% MAIN -------------------------------------------------------------------
%% PID SISO dla salonu, reszta pomieszczeñ przeskalowana
%  Plik g³ówny programu
% 0 - skok sterowania o okreœlonej wartoœci
% 1 - PID siso
% 2 - PID mimo 
% 3 - DMC siso
% 4 - DMC mimo
%  ------------------------------------------------------------------------
 
clear all; clc; disp('START');
regulator = 3; %<-- wybór regulatora
shutdown = 0; % 1 wy³¹cza komputer po wykonaniu pomiarów
filename = 'pomiary.mat';     
% zaklocenie='otwarte drzwi wewnetrzne';
% zaklocenie='otwarte okno w salonie';
zaklocenie='wlaczony wentylator wywiewny w dachu';


%% DEKLARACJA ZMIENNYCH 
defines;
dyskretyzacja;

%% UTWORZENIE KANA£U KOMUNIKACYJNEGO
UART_port = UART_connect(uart);
  
%% PÊTLA    G£ÓWNA         
disp('3. PÊTLA G£ÓWNA');
global iter;
t_sim = model.kk;
for(iter=1:t_sim)
    tic;
    
    %% POMIAR TEMPERATUR
      UART_rcv;

    %% WYBÓR REGULATORA
    if(regulator==1),     PID_reg_SISO;
    elseif(regulator==2), PID_reg_MIMO;
    elseif(regulator==3), DMC_reg_SISO;
    elseif(regulator==4), DMC_reg_MIMO;
    end
  
    %% WYS£ANIE OBLICZONEGO STEROWANIA DO URZ¥DZEÑ WYKONAWCZYCH
    %skok jednostkowy przeskalowany
    if(regulator==0)      
        [ster skok]=PWM_set(UART_port,ster,pom,model,skok,iter);
    %PID SISO
    elseif(regulator==1) 
        [ster pid]=PWM_set(UART_port,ster,pom,model,pid,iter);
    %PID MIMO   
    elseif(regulator==2)  
        [ster pid]=PWM_set(UART_port,ster,pom,model,pid,iter);
    %DMC SISO   
    elseif(regulator==3) 
        [ster DMC]=PWM_set(UART_port,ster,pom,model,DMC,iter);
    %DMC MIMO
    elseif(regulator==4) 
        [ster DMC]=PWM_set(UART_port,ster,pom,model,DMC,iter); 
    end
    
    %Wypisywanie aktualnych wyników
    wypisz_wyniki;
    time.loop(iter) = toc; %zapis czasu wykonania pêtli w danej iteracji
    fprintf('              czas pêtli = %f\n\r',time.loop(iter));
end
disp('KONIEC PÊTLI G£ÓWNEJ');

%wyzerowanie sterowañ
fwrite(UART_port,'PWM1=0;PWM2=0;PWM3=0;PWM4=0;PWM5=0;PWM6=0;');
disp('Wyzerowano sterowania');

%% ZAPIS POMIARÓW DO PLIKU
save(filename);
disp('Zapisano pomiary'); 

%% WYKRESY
wykresy_offline;
disp('Wykonano wykresy dyskretne');

%% WY£¥CZENIE KOMPUTERA (je¿eli shutdown=='ON')
if(shutdown==1), system('shutdown/h'), end;

%% KONIEC 

%zabezpieczenie wylaczajace grzejniki
str = strcat('PWM1=0;PWM2=0;PWM3=0;PWM4=0;PWM5=0;PWM6=0;');
for (i=length(str)+1:80) 
    str=strcat(str,'0');
end

%usuniêcie zbêdnych zmiennych
clear str i t1 t2 t3 t4 t5 t6 t7 t8 t9 t10 

disp('KONIEC');
disp('Zakoñcz naciskaj¹c Ctrl+Break');
while(1)
    beep;
    pause(1);
end
