%% WYPISYWANIE WYNIKÓW W KA¯DEJ ITERACJI
%sterowania
fprintf('Iter= %d/%d.  PWM1=%d;  PWM2=%d;  PWM3=%d;  PWM4=%d;  PWM5=%d;  PWM6=%d;\n\r',iter,model.kk,ster.PWM1(iter,1),ster.PWM2(iter,1),ster.PWM3(iter,1),ster.PWM4(iter,1),ster.PWM5(iter,1),ster.PWM6(iter,1));
%temperatury pomieszczeñ
fprintf('              t1=%f;  t2=%f;  t3=%f;  t4=%f;  t5=%f;\n\r',pom.temp1(iter,1),pom.temp2(iter,1),pom.temp3(iter,1),pom.temp4(iter,1),pom.temp5(iter,1));
%temperatury grzejników
fprintf('              t6=%f;  t7=%f;  t8=%f;  t9=%f;  t10=%f;\n\r',pom.temp6(iter,1),pom.temp7(iter,1),pom.temp8(iter,1),pom.temp9(iter,1),pom.temp10(iter,1));

%informacje zwrotne z danego regulatora
if(regulator==1)
    fprintf('              PID SISO:   e=%f;   u=%f;\n\r',pid.e(5,iter),pid.u(5,iter));   
elseif(regulator==2)
    fprintf('              PID MIMO:   e1=%f;  e2=%f;  e3=%f;  e4=%f;  e5=%f;\n\r',pid.e(1,iter),pid.e(2,iter),pid.e(3,iter),pid.e(4,iter),pid.e(5,iter));   
    fprintf('                          u1=%f;  u2=%f;  u3=%f;  u4=%f;  u5=%f;\n\r',pid.u(1,iter),pid.u(2,iter),pid.u(3,iter),pid.u(4,iter),pid.u(5,iter));   
elseif(regulator==3)
%     fprintf('              DMC SISO:   e=%f;   u=%f;\n\r',dmc.e(iter),dmc.u(5,iter));   
end
