%% WARIANCJA SYGNA£U STERUJ¥CEGO
clc;disp('WARIANCJA');
if(regulator==1 || regulator==2) %PID Tp=1
    disp('Tp=1'); pocz = 3601; %skok po 1h
elseif(regulator==3) %DMC Tp=10
    disp('Tp=10'); pocz = 721; %skok po 2h
elseif(regulator==4) %DMC Tp=10 
    disp('Tp=10'); pocz = 361; %skok po 1h
end

%suma wartoœci sygna³u PWM do œredniej
suma1=0;suma2=0;suma3=0;suma4=0;suma5=0;
for(i=pocz:model.kk) %od momentu ustalenia sygna³u wyjœciowego
    suma1 = suma1 + ster.PWM1(i,1);
    suma2 = suma2 + ster.PWM2(i,1);
    suma3 = suma3 + ster.PWM3(i,1);
    suma4 = suma4 + ster.PWM4(i,1);
    suma5 = suma5 + ster.PWM5(i,1);
end

%wartoœæ œrednia sygna³u w przedziale
disp('Wartoœci œrednie sygna³u:');
x_1sr = suma1/(model.kk-pocz) %kuchnia
x_2sr = suma2/(model.kk-pocz) %sypialnia
x_3sr = suma3/(model.kk-pocz) %³azienka
x_4sr = suma4/(model.kk-pocz) %gabinet
x_5sr = suma5/(model.kk-pocz) %salon

%kwadraty odchyleñ
for(i=pocz:model.kk)
    x1nx1sr(i) = (ster.PWM1(i,1)-x_1sr)^2;  %(x_1(i)-x_1sr)^2
    x2nx2sr(i) = (ster.PWM2(i,1)-x_2sr)^2;  % .
    x3nx3sr(i) = (ster.PWM3(i,1)-x_3sr)^2;  % .
    x4nx4sr(i) = (ster.PWM4(i,1)-x_4sr)^2;  % .
    x5nx5sr(i) = (ster.PWM5(i,1)-x_5sr)^2;  %(x_5(i)-x_5sr)^2
end

%wariancja sygna³ów steruj¹cych
disp('Wariancje sygna³ów:');
sigma2x_1 = sum(x1nx1sr)/(model.kk-pocz); %kuchnia
sigma2x_2 = sum(x2nx2sr)/(model.kk-pocz); %sypialnia
sigma2x_3 = sum(x3nx3sr)/(model.kk-pocz); %³azienka
sigma2x_4 = sum(x4nx4sr)/(model.kk-pocz); %gabinet
sigma2x_5 = sum(x5nx5sr)/(model.kk-pocz); %salon

%zaokr¹glenie do 2 miejsc po przecinku
sigma2x_1 = round(sigma2x_1,2)
sigma2x_2 = round(sigma2x_2,2)
sigma2x_3 = round(sigma2x_3,2)
sigma2x_4 = round(sigma2x_4,2)
sigma2x_5 = round(sigma2x_5,2)

sigma2x=[sigma2x_1,sigma2x_2,sigma2x_3,sigma2x_4,sigma2x_5];
%sprz¹tanie
clear x1nx1sr x2nx2sr x3nx3sr x4nx4sr x5nx5sr...
      suma1 suma2 suma3 suma4 suma5

