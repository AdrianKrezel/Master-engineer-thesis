%% PWM_set ----------------------------------------------------------------
%  Wys³anie sterowañ z PC do uC
%
%--------------------------------------------------------------------------

function [ster reg]=PWM_set(UART_port,ster,pom,model,reg,iter)
    %przeskalowanie wartoœci sterowania na odpowiadaj¹cy mu PWM
    ster.PWM1(iter,1) = round(reg.u(1,iter));
    ster.PWM2(iter,1) = round(reg.u(2,iter));
    ster.PWM3(iter,1) = round(reg.u(3,iter));
    ster.PWM4(iter,1) = round(reg.u(4,iter));
    ster.PWM5(iter,1) = round(reg.u(5,iter));
    
    %W sytuacji, w której sterowanie jest ujemne (przekroczenie wart
    %zadanej przez pomieszczenie) wystawienie zerowego sterowania.
    %Grzejniki przecie¿ nie ch³odz¹ :)
    if (ster.PWM1(iter)<0), ster.PWM1(iter,1) = 0;   end;
    if (ster.PWM2(iter)<0), ster.PWM2(iter,1) = 0;   end;
    if (ster.PWM3(iter)<0), ster.PWM3(iter,1) = 0;   end;
    if (ster.PWM4(iter)<0), ster.PWM4(iter,1) = 0;   end;
    if (ster.PWM5(iter)<0), ster.PWM5(iter,1) = 0;   end;
    
    
    %Ograniczenie zwi¹zane z konfiguracj¹ timerów uC (0<=PWM<=200)
    if (ster.PWM1(iter)>200), ster.PWM1(iter,1) = 200;   end;
    if (ster.PWM2(iter)>200), ster.PWM2(iter,1) = 200;   end;
    if (ster.PWM3(iter)>200), ster.PWM3(iter,1) = 200;   end;
    if (ster.PWM4(iter)>200), ster.PWM4(iter,1) = 200;   end;
    if (ster.PWM5(iter)>200), ster.PWM5(iter,1) = 200;   end;

    %Zabezpieczenie programowe przed przegrzaniem i uszkodzeniem grzejników
    %oraz makiety z pleksi
    if (pom.temp6(iter,1)>=100),  ster.PWM1(iter,1) = 0;   end;
    if (pom.temp7(iter,1)>=100),  ster.PWM2(iter,1) = 0;   end;
    if (pom.temp8(iter,1)>=100),  ster.PWM3(iter,1) = 0;   end;
    if (pom.temp9(iter,1)>=100),  ster.PWM4(iter,1) = 0;   end;
    if (pom.temp10(iter,1)>=100), ster.PWM5(iter,1) = 0;   end;

    %konwersja danych na string do wys³ania
    str1 = sprintf('PWM1=%d;',ster.PWM1(iter,1));
    str2 = sprintf('PWM2=%d;',ster.PWM2(iter,1));
    str3 = sprintf('PWM3=%d;',ster.PWM3(iter,1));
    str4 = sprintf('PWM4=%d;',ster.PWM4(iter,1));
    str5 = sprintf('PWM5=%d;',ster.PWM5(iter,1));
    str6 = sprintf('PWM6=%d;',ster.PWM6(iter,1));
    str = strcat(str1,str2,str3,str4,str5,str6);
 
%     %wype³nienie reszty pustych miejsc wysy³anej ramki danych zerami
    for (i=length(str)+1:80) 
        str=strcat(str,'0');
    end
    
    %wys³anie nastaw PWM
    fwrite(UART_port,str); 
end


