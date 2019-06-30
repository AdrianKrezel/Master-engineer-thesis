%% MAIN -------------------------------------------------------------------
%% PID SISO dla salonu, reszta pomieszcze� przeskalowana
%  Plik g��wny programu
% 0 - skok sterowania o okre�lonej warto�ci
% 1 - PID siso
% 2 - PID mimo 
% 3 - DMC siso
% 4 - DMC mimo
%  ------------------------------------------------------------------------
 
clear all; clc; disp('START');
regulator = 3; %<-- wyb�r regulatora
shutdown = 0; % 1 wy��cza komputer po wykonaniu pomiar�w
filename = 'pomiary.mat';     
% zaklocenie='otwarte drzwi wewnetrzne';
% zaklocenie='otwarte okno w salonie';
zaklocenie='wlaczony wentylator wywiewny w dachu';


%% DEKLARACJA ZMIENNYCH 
defines;
dyskretyzacja;

%% UTWORZENIE KANA�U KOMUNIKACYJNEGO
UART_port = UART_connect(uart);
  
%% P�TLA    G��WNA         
disp('3. P�TLA G��WNA');
global iter;
t_sim = model.kk;
for(iter=1:t_sim)
    tic;
    
    %% POMIAR TEMPERATUR
      UART_rcv;

    %% WYB�R REGULATORA
    if(regulator==1),     PID_reg_SISO;
    elseif(regulator==2), PID_reg_MIMO;
    elseif(regulator==3), DMC_reg_SISO;
    elseif(regulator==4), DMC_reg_MIMO;
    end
  
    %% WYS�ANIE OBLICZONEGO STEROWANIA DO URZ�DZE� WYKONAWCZYCH
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
    
    %Wypisywanie aktualnych wynik�w
    wypisz_wyniki;
    time.loop(iter) = toc; %zapis czasu wykonania p�tli w danej iteracji
    fprintf('              czas p�tli = %f\n\r',time.loop(iter));
end
disp('KONIEC P�TLI G��WNEJ');

%wyzerowanie sterowa�
fwrite(UART_port,'PWM1=0;PWM2=0;PWM3=0;PWM4=0;PWM5=0;PWM6=0;');
disp('Wyzerowano sterowania');

%% ZAPIS POMIAR�W DO PLIKU
save(filename);
disp('Zapisano pomiary'); 

%% WYKRESY
wykresy_offline;
disp('Wykonano wykresy dyskretne');

%% WY��CZENIE KOMPUTERA (je�eli shutdown=='ON')
if(shutdown==1), system('shutdown/h'), end;

%% KONIEC 

%zabezpieczenie wylaczajace grzejniki
str = strcat('PWM1=0;PWM2=0;PWM3=0;PWM4=0;PWM5=0;PWM6=0;');
for (i=length(str)+1:80) 
    str=strcat(str,'0');
end

%usuni�cie zb�dnych zmiennych
clear str i t1 t2 t3 t4 t5 t6 t7 t8 t9 t10 

disp('KONIEC');
disp('Zako�cz naciskaj�c Ctrl+Break');
while(1)
    beep;
    pause(1);
end
