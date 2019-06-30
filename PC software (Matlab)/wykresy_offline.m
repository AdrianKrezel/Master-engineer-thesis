%% WYKRESY danych z workspace ---------------------------------------------
%
%--------------------------------------------------------------------------
close all;clc;  
%% NOWE WYKRESY
todn(1:iter-1)=40;
figure;
    subplot(2,3,1); %kuchnia
        stairs(1:iter-1,pom.temp1(1:iter-1,1),'b');  hold on; grid on;
        stairs(1:iter-1,pom.temp6(1:iter-1,1),'r');  hold on; grid on;
%         stairs(1:iter-1,skok.u(1,1:iter-1),'k');  hold on; grid on;
%         stairs(1:iter-1,todn(1:iter-1),'g');  hold on; grid on;
        stairs(1:iter-1,model.yzad(1,1:iter-1),'g'); hold on; grid on;
%         stairs(1:iter-1,pid.u(1,1:iter-1),'k');   hold on; grid on; 
        stairs(1:iter-1,ster.PWM1(1:iter-1,1),'k');   hold on; grid on;  %DMC
        axis([0 inf 0 100]);
        title('Kuchnia'); 
        xlabel('nr próbki'); ylabel('temperatura');
%         legend('pomieszcz.','grzejnik','zadana');
    subplot(2,3,2); %sypialnia
        stairs(1:iter-1,pom.temp2(1:iter-1,1),'b');  hold on; grid on;
        stairs(1:iter-1,pom.temp7(1:iter-1,1),'r');  hold on; grid on;
%         stairs(1:iter-1,skok.u(2,1:iter-1),'k');  hold on; grid on;
%         stairs(1:iter-1,todn(1:iter-1),'g');  hold on; grid on;
        stairs(1:iter-1,model.yzad(2,1:iter-1),'g'); hold on; grid on; 
%         stairs(1:iter-1,pid.u(2,1:iter-1),'k');   hold on; grid on; 
        stairs(1:iter-1,ster.PWM2(1:iter-1,1),'k');   hold on; grid on;  %DMC
        title('Sypialnia');
        axis([0 inf 0 100]);
        xlabel('nr próbki'); ylabel('temperatura');
%         legend('pomieszcz.','grzejnik','zadana');
    subplot(2,3,3); %³azienka
        stairs(1:iter-1,pom.temp3(1:iter-1,1),'b');  hold on; grid on;
        stairs(1:iter-1,pom.temp8(1:iter-1,1),'r');  hold on; grid on;
%         stairs(1:iter-1,skok.u(3,1:iter-1),'k');  hold on; grid on;
%         stairs(1:iter-1,todn(1:iter-1),'g');  hold on; grid on;
        stairs(1:iter-1,model.yzad(3,1:iter-1),'g'); hold on; grid on;
%         stairs(1:iter-1,pid.u(3,1:iter-1),'k');   hold on; grid on; 
        stairs(1:iter-1,ster.PWM3(1:iter-1,1),'k');   hold on; grid on;  %DMC
        title('£azienka');
        axis([0 inf 0 100]);
        xlabel('nr próbki'); ylabel('temperatura');
%         legend('pomieszcz.','grzejnik','zadana');
    subplot(2,3,4); %gabinet
        stairs(1:iter-1,pom.temp4(1:iter-1,1),'b');  hold on; grid on;
        stairs(1:iter-1,pom.temp9(1:iter-1,1),'r');  hold on; grid on;
%         stairs(1:iter-1,skok.u(4,1:iter-1),'k');  hold on; grid on;
%         stairs(1:iter-1,todn(1:iter-1),'g');  hold on; grid on;
        stairs(1:iter-1,model.yzad(4,1:iter-1),'g'); hold on; grid on; 
%         stairs(1:iter-1,pid.u(4,1:iter-1),'k');   hold on; grid on; 
        stairs(1:iter-1,ster.PWM4(1:iter-1,1),'k');   hold on; grid on;  %DMC
        title('Gabinet');
        axis([0 inf 0 100]);
        xlabel('nr próbki'); ylabel('temperatura');
%         legend('pomieszcz.','grzejnik','zadana');
    subplot(2,3,5); %salon
        stairs(1:iter-1,pom.temp5(1:iter-1,1),'b');  hold on; grid on;
        stairs(1:iter-1,pom.temp10(1:iter-1,1),'r'); hold on; grid on;
%         stairs(1:iter-1,skok.u(5,1:iter-1),'k');  hold on; grid on;
%         stairs(1:iter-1,todn(1:iter-1),'g');  hold on; grid on;
        stairs(1:iter-1,model.yzad(5,1:iter-1),'g'); hold on; grid on; 
%         stairs(1:iter-1,pid.u(5,1:iter-1),'k');   hold on; grid on; 
        stairs(1:iter-1,ster.PWM5(1:iter-1,1),'k');   hold on; grid on;  %DMC
        title('Salon');
        axis([0 inf 0 100]);
        xlabel('nr próbki'); ylabel('temperatura');
        legend('Temperatura pomieszczenia','Tepmeratura grzejnika','Temperatura zadana','Wartoœæ sygna³u steruj¹cego');%,'Sygna³ steruj¹cy','Temperatura odniesienia 40C');%,'Temperatura odniesienia 40C');

        
%% ZAPIS POMIARÓW OBIEKTU MIMO
filename = 'dane.xlsx';
sheet = 1;
xlRange = 'A1';
u_pocz = pom.temp6(1);
u_konc = pom.temp6(end);

%WZMOCNIENIA
K = [(pom.temp1(end)-pom.temp1(1))/(u_konc-u_pocz);...  % dy1/dux
     (pom.temp2(end)-pom.temp2(1))/(u_konc-u_pocz);...  % dy2/dux
     (pom.temp3(end)-pom.temp3(1))/(u_konc-u_pocz);...  % dy3/dux
     (pom.temp4(end)-pom.temp4(1))/(u_konc-u_pocz);...  % dy4/dux
     (pom.temp5(end)-pom.temp5(1))/(u_konc-u_pocz)];    % dy5/dux
% 63% WZMOCNIENIA
K63 = 0.63*K; % 0.63K
%TEMPERATURY DLA KTÓRYCH ODCZYTYWANE JEST Ts DO MODELU
y_K63 =  [pom.temp1(1) + 0.63*(pom.temp1(end) - pom.temp1(1));... % y1 + 0.63*dyx
         pom.temp2(1) + 0.63*(pom.temp2(end) - pom.temp2(1));... % y2 + 0.63*dyx
         pom.temp3(1) + 0.63*(pom.temp3(end) - pom.temp3(1));... % y3 + 0.63*dyx
         pom.temp4(1) + 0.63*(pom.temp4(end) - pom.temp4(1));... % y4 + 0.63*dyx
         pom.temp5(1) + 0.63*(pom.temp5(end) - pom.temp5(1))];   % y5 + 0.63*dyx
    
%ZAPIS POMIARÓW
data = {'pomieszczenie','y_pocz','y_konc','u_pocz','u_konc','K','63%K';...
    'kuchnia',  pom.temp1(1),pom.temp1(end),u_pocz,u_konc,K(1,1),K63(1,1);...
    'sypialnia',pom.temp2(1),pom.temp2(end),u_pocz,u_konc,K(2,1),K63(2,1);...
    '³azienka', pom.temp3(1),pom.temp3(end),u_pocz,u_konc,K(3,1),K63(3,1);...
    'gabinet',  pom.temp4(1),pom.temp4(end),u_pocz,u_konc,K(4,1),K63(4,1);...
    'salon',    pom.temp5(1),pom.temp5(end),u_pocz,u_konc,K(5,1),K63(5,1)};
xlswrite(filename,data,sheet,xlRange);
open(filename)
        
figure; %kuchnia
    stairs(1:iter-1,pom.temp1(1:iter-1,1),'b');  hold on; grid on;
    stairs(1:iter-1,pom.temp6(1:iter-1,1),'r');  hold on; grid on;
%     stairs(1:iter-1,model.yzad(1,1:iter-1),'g'); hold on; grid on; 
%     stairs(1:iter-1,pid.u(2,1:iter-1),'g');   hold on; grid on; 
    y63(1:iter-1) = y_K63(1,1);
    plot(1:iter-1,y63,'k'); hold on; grid on;
    y63(1:iter-1) = pom.temp1(1);
    plot(1:iter-1,y63,'k'); hold on; grid on;
    title('Kuchnia');
    xlabel('nr próbki'); ylabel('temperatura');
    axis([0 inf 0 100]);
%         legend('pomieszcz.','grzejnik','zadana');
figure; %sypialnia
    stairs(1:iter-1,pom.temp2(1:iter-1,1),'b');  hold on; grid on;
    stairs(1:iter-1,pom.temp7(1:iter-1,1),'r');  hold on; grid on;
%     stairs(1:iter-1,model.yzad(2,1:iter-1),'g');   hold on; grid on; 
    y63(1:iter-1) = y_K63(2,1);
    plot(1:iter-1,y63,'k'); hold on; grid on;
    y63(1:iter-1) = pom.temp2(1);
    plot(1:iter-1,y63,'k'); hold on; grid on;
    title('Sypialnia');
    xlabel('nr próbki'); ylabel('temperatura');
    axis([0 inf 0 100]);
%         legend('pomieszcz.','grzejnik','zadana');
figure; %³azienka
    stairs(1:iter-1,pom.temp3(1:iter-1,1),'b');  hold on; grid on;
    stairs(1:iter-1,pom.temp8(1:iter-1,1),'r');  hold on; grid on;
%     stairs(1:iter-1,model.yzad(3,1:iter-1),'g');   hold on; grid on;
    y63(1:iter-1) = y_K63(3,1);
    plot(1:iter-1,y63,'k'); hold on; grid on;
    y63(1:iter-1) = pom.temp3(1);
    plot(1:iter-1,y63,'k'); hold on; grid on;
    title('£azienka');
    xlabel('nr próbki'); ylabel('temperatura');
    axis([0 inf 0 100]);
%         legend('pomieszcz.','grzejnik','zadana');
figure; %gabinet
    stairs(1:iter-1,pom.temp4(1:iter-1,1),'b');  hold on; grid on;
    stairs(1:iter-1,pom.temp9(1:iter-1,1),'r');  hold on; grid on;
%     stairs(1:iter-1,model.yzad(4,1:iter-1),'g');   hold on; grid on;
    y63(1:iter-1) = y_K63(4,1);
    plot(1:iter-1,y63,'k'); hold on; grid on;
    y63(1:iter-1) = pom.temp4(1);
    plot(1:iter-1,y63,'k'); hold on; grid on;
    title('Gabinet');
    xlabel('nr próbki'); ylabel('temperatura');
    axis([0 inf 0 100]);
%         legend('pomieszcz.','grzejnik','zadana');
figure; %salon
    stairs(1:iter-1,pom.temp5(1:iter-1,1),'b');  hold on; grid on;
    stairs(1:iter-1,pom.temp10(1:iter-1,1),'r'); hold on; grid on;
%     stairs(1:iter-1,model.yzad(5,1:iter-1),'g');   hold on; grid on; 
    y63(1:iter-1) = y_K63(5,1);
    plot(1:iter-1,y63,'k'); hold on; grid on;
    y63(1:iter-1) = pom.temp5(1);
    plot(1:iter-1,y63,'k'); hold on; grid on;
    title('Salon');
    xlabel('nr próbki'); ylabel('temperatura');
    legend('pomieszcz.','grzejnik','zadana');
    axis([0 inf 0 100]);
        
   K63        

