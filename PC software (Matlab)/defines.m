%% DEFINES ----------------------------------------------------------------
%  Plik zawierajπcy deklaracje wszystkich uøywanych zmiennych
%
%  Struktury:
%   model - model
%   pom - pomiary
%   pid - regulator pid
%   dmc - regulator dmc
%   ster - nastawy sterowania PWM
%   skok - skok jednostkowy przeskalowany
%--------------------------------------------------------------------------

disp('1. INICJALIZACJA ZMIENNYCH');
global model pom pid ster uart time   %globalna deklaracja zmiennych    

%% model (model)
%   Parametry modelelu
    %Skalowanie mocy grzejnika w zaleønoúci od powierzchni pomieszczenia
    %Pomieszczenie | Powierzchnia            | wsp. skali
    %  kuchnia     |  14,4 x 18,0 = 338,4cm2 |  0,520
    %  sypialnia   |  14,4 x 20,5 = 295,2cm2 |  0,454
    %  ≥azienka    |  10,0 x 11,5 = 115,0cm2 |  0,177
    %  gabinet     |  13,6 x 11,5 = 156,4cm2 |  0,240
    %  salon       |  24,1 x 27,0 = 650,7cm2 |  1,000
    
    model.Tp = 10;                     %okres prÛbkowania pomiarÛw uC
    model.kp0=1; %rozbiegÛwka DMC i PID MIMO
    model.kp = round(7200/model.Tp);                     %I  skok (2h)
    model.kp2 = round(model.kp+3600/model.Tp);        %II skok (1h)
    model.kp3 = round(model.kp2+3600/model.Tp);       %III skok (1h)
    model.kk =  round(model.kp3+3600/model.Tp);        %d≥ugoúÊ symulacji
%     model.wsp = [0.520;  0.454;  0.177;  0.240;  1.000];  %wspÛ≥czynniki skali powierzchni pomieszczeÒ w stosunku do salonu
    model.wsp2 = [0.5*0.88; 0.5*0.91*1.1;  0.3*1*0.95*0.9;  0.3*0.75*1.25*0.95;  1];  %wspÛ≥czynniki skali temperatur poszczegÛlnych pomieszczeÒ
%     model.wsp3 = [0.8972; 0.8879; 0.7665; 0.7864; 1]; 
    model.ymod(1:5,1:model.kk) = 0;                %temp. pomieszczeÒ zmierzona
    model.yzad(1:5,1:model.kk) = 0; %deklaracja yzad
    model.yzad(1:5,model.kp0:model.kp-1) = 40;     %temp. pomieszczeÒ zadana 0 setpoint
    model.yzad(1:5,model.kp:model.kp2-1) = 42;     %temp. pomieszczeÒ zadana I setpoint
    model.yzad(1:5,model.kp2:model.kp3-1) = 39;       %temp. pomieszczeÒ zadana II setpoint
    model.yzad(1:5,model.kp3:model.kk) = 42;       %temp. pomieszczeÒ zadana III setpoint    
    
    %% skok jednostkowy (do zebrania odpowiedzi i wykonania modelu w postaci transmitancji)
    if(regulator==0)% ODPOWIEDè SKOKOWA UK£ADU
        skok.kp=1; %chwila wykonania I skoku sterowania
        skok.u(1:5,1:model.kk ) = 0; %wyzerowanie sterowaÒ
%         skok.u(4,skok.kp:model.kp-1) = 80;
        skok.u(5,skok.kp:model.kk) = 80; %25%mocy max (bez skalowania)
%         skok.u(1,skok.kp:model.kk) = round(0.4*model.wsp2(1,1)*200); %kuchnia
%         skok.u(2,skok.kp:model.kk) = round(0.4*model.wsp2(2,1)*200); %sypialnia
%         skok.u(3,skok.kp:model.kk) = round(0.4*model.wsp2(3,1)*200); %≥azienka
%         skok.u(4,skok.kp:model.kk) = round(0.4*model.wsp2(4,1)*200); %gabinet
%         skok.u(5,skok.kp:model.kk) = round(0.5*model.wsp2(5,1)*200); %salon
%         skok.u(5,skok.kp:model.kp-1) = round(model.wsp2(5,1)*50);
        for(i=1:4) %skalowanie sterowania
            skok.u(i,1:model.kk)=round(model.wsp2(i,1)*skok.u(5,skok.kp:model.kk));
        end
    end
    
%% Konfiguracja UART (uart)
%  Parametry transmisji
    uart.Type = 'serial';
    uart.Port = 'COM7';
    uart.BaudRate = 115200;
    uart.Timeout = 60; %sec.
    
%% Konfiguracja DMC (dmc) SISO
    if(regulator==3)
        disp('REGULATOR DMC SISO');
        dyskretyzacja3;
        hd=model.Gz;
                
        % macierz pojedynczych odpowiedzi skokowych (wg konwencji Matlaba: Y[time,ny,nu])
        figure(1);
        step(hd); grid on;
        [Y,T] = step(hd); % odp. skokowa, pierwsze elementy Y(1,i,j) dla czasu k=0

    % odpowiedz macierzowa wg konwencji DMC:
        [nt,ny,nu] = size(Y);
        S = zeros(ny,nu,nt-1); % pierwsze elementy odpowiedzi skokowej S dla czasu k=1
        for i=1:ny
            for j=1:nu
                S(i,j,:) = Y(2:nt,i,j);
            end
        end
        dmc = classDMCa(1,1); % DMC 1x1
        dmc.D=nt-1;                   %horyzont dynamiki
        dmc.N=1500/model.Tp;                           %horyzont predykcji
        dmc.Nu=200/model.Tp;                           %horyzont sterowania
        dmc.lambda=2;                       %wsp. t≥umienia
        dmc.u_start = 0;
        dmc.Ysp = 40; %bÍdzie dalej zmieniany 
        dmc.settings.limitsOn = 1;
        dmc.settings.type = 'analytical';
        dmc.du_min = 0;
        dmc.du_max = 200; %bo ograniczam salon do 95% z 200
        dmc.u_min = 0;    %bo ograniczam salon do 95% z 200
        dmc.u_max = 200;    
        
        dmc.S = S;
        dmc.Ypv = 0;
        dmc.u_k = 0;
        dmc.init();

        Y5=[];      
        
%% Konfiguracja DMC (dmc) MIMO
    elseif(regulator==4)
        dyskretyzacja3;
        hd=model.Gz;

        % macierz pojedynczych odpowiedzi skokowych (wg konwencji Matlaba: Y[time,ny,nu])
        figure(1);
        step(hd); grid on;
        [Y,T] = step(hd); % odp. skokowa, pierwsze elementy Y(1,i,j) dla czasu k=0

    % odpowiedz macierzowa wg konwencji DMC:
        [nt,ny,nu] = size(Y);
        S = zeros(ny,nu,nt-1); % pierwsze elementy odpowiedzi skokowej S dla czasu k=1
        for i=1:ny
            for j=1:nu
                S(i,j,:) = Y(2:nt,i,j);
            end
        end
        dmc = classDMCa(5,5); % DMC 5x5
        dmc.D = nt-1; %d?ugosc dynamiki obiektu - liczba krokÛw po ktorej wyjscie sie stabilizuje model.kk/model.Tp
        dmc.N = 1500/model.Tp; % horyzont predykcji definiowany w liczbie krokow UWAGA N < D
        dmc.Nu = 200/model.Tp; % horyzont sterowania definiowany w liczbie krokow
        dmc.lambda = 2;
        dmc.u_start = [0; 0; 0; 0; 0];
        dmc.Ysp = [1; 1; 1; 1; 1]; %jest pÛüniej nadpisywany w model.yzad(1:model.kk)
        dmc.settings.limitsOn = 1;
        % wersja numeryczna - do analitycznej naleøy zakomentowaÊ liniÍ 43
        dmc.settings.type = 'analytical';
                dmc.du_min = [0; 0; 0; 0; 0];
                dmc.du_max = [200; 200; 200; 200; 200];
                dmc.u_min = [0; 0; 0; 0; 0];
                dmc.u_max = [200; 200; 200; 200; 200];

        % przekazanie modelu odp. skokowej do regulatora
        dmc.S = S;
        dmc.Ypv = [0;0;0;0;0];
        dmc.u_k = [0;0;0;0;0];
        dmc.init();

        Y1=[];
        Y2=[];
        Y3=[];
        Y4=[];
        Y5=[];

%% Konfiguracja pid (pid)
    elseif(regulator==1 || regulator==2)
    %   Zmienne regulatora pid 
        pid.up(1:5,model.kk) = 0;          %sterowania cz≥onu proporcjonalnego
        pid.ui(1:5,model.kk) = 0;          %sterowania cz≥onu ca≥kujπcego
        pid.ud(1:5,model.kk) = 0;          %sterowania cz≥onu rÛøniczkujπcego
        pid.u(1:5,model.kk) = 0;           %sterowania (up+ui+ud)
        pid.e(1:5,model.kk) = 0;           %uchyby
        
        if(regulator==1)%PID SISO
            %parametry strojπce (niegasnπce oscylacje) <-- WARTOåCI Kkr i Tkr tymczasowe
            pid.Ke = [0; 0; 0; 0; 15];       %wzmocnienie cz≥onu proporcjonalnego
            pid.Kd = [0; 0; 0; 0; 0];        %wzmocnienie cz≥onu rÛøniczkujπcego
            pid.Ti(1:5,1) = 100;             %czas zdwojenia
            pid.Td(1:5,1) = 0;               %czas wyprzedzenia

            %nastawy metodπ inøynierskπ
            pid.Ti(1:5,1) = 100; %doúwiadczalnie
            pid.Td(1:5,1) = 0;   %doúwiadczalnie
        elseif(regulator==2)
            %ograniczenia sterowania PID MIMO
            %parametry strojπce (niegasnπce oscylacje) <-- WARTOåCI Kkr i Tkr tymczasowe
            pid.Ke = [15; 15; 15; 15; 15];       %wzmocnienie cz≥onu proporcjonalnego
            pid.Kd = [0; 0; 0; 0; 0];        %wzmocnienie cz≥onu rÛøniczkujπcego
            pid.Ti = [110; 110; 100; 100; 120];             %czas zdwojenia
            pid.Td(1:5,1) = 0;               %czas wyprzedzenia

            %nastawy metodπ inøynierskπ
%             pid.Ti(1:5,1) = 100; %doúwiadczalnie
            pid.Td(1:5,1) = 0;   %doúwiadczalnie
        end
    end

%% STEROWANIE (ster)
%  Nastawy sterowania grzejnikÛw i wentylatora wysy≥ane do uC 
    ster.wsp_mocy = 20;        %wsp. skali mocy grzejnikÛw w stosunku do sterowania
    ster.PWM1(1:model.kk,1) = 0; %grzejnik kuchnia
    ster.PWM2(1:model.kk,1) = 0; %grzejnik sypialnia
    ster.PWM3(1:model.kk,1) = 0; %grzejnik ≥azienka
    ster.PWM4(1:model.kk,1) = 0; %grzejnik gabinet
    ster.PWM5(1:model.kk,1) = 0; %grzejnik salon
    ster.PWM6(1:model.kk,1) = 0; %wentylator
    
    if(regulator==1 || regulator==2)
        ster.PWM6(3601:model.kk,1) = 40; %wentylator 20%
    elseif(regulator==4)
        ster.PWM6(361:model.kk,1) = 40; %wentylator 20%
    elseif(regulator==3)        
        ster.PWM6(721:model.kk,1) = 40; %wentylator 20%
    end
    
%% POMIARY (pom)
%  Pomiary temperatury
    %temp. pomieszczeÒ        
    pom.temp1=[];              %temperatura kuchni                               
    pom.temp2=[];              %temperatura sypialni
    pom.temp3=[];              %temperatura ≥azienki
    pom.temp4=[];              %temperatura gabinetu
    pom.temp5=[];              %temperatura salonu
    %temp. grzejnikÛw
    pom.temp6=[];              %temperatura grzejnika w kuchni 
    pom.temp7=[];              %temperatura grzejnika w sypialni
    pom.temp8=[];              %temperatura grzejnika w ≥azienki
    pom.temp9=[];              %temperatura grzejnika w gabinet
    pom.temp10=[];             %temperatura grzejnika w salon
    
    
%% KONTROLKI
    time.loop(1:model.kk) = 0;         %czas wykonywania pÍtli
    time.elapsed(1:model.kk) = 0;     %czas wykonywania wszystkich pÍtli
    disp('   Ok');


