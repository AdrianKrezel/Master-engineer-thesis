%B£¥D ŒREDNIOKWADRATOWY
%Tp_wartosc:
%   1: Tp=1 (dla PIDów)
%   2: Tp=10 (dla DMC)

disp('B£¥D ŒREDNIOKWADRATOWY');
if(regulator==1 || regulator==2) %PID Tp=1
    disp('Tp=1'); pocz = 3601; %skok po 1h
elseif(regulator==3)%DMC Tp=10
    disp('Tp=10'); pocz = 721; %skok po 2h
elseif(regulator==4) %DMC Tp=10 
    disp('Tp=10'); pocz = 361; %skok po 1h
end

s1=0; s2=0; s3=0; s4=0; s5=0;
for(i=pocz:iter)
   s1 = s1 + (model.yzad(1,iter)-pom.temp1(iter,1))^2;
   s2 = s2 + (model.yzad(2,iter)-pom.temp2(iter,1))^2;
   s3 = s3 + (model.yzad(3,iter)-pom.temp3(iter,1))^2;
   s4 = s4 + (model.yzad(4,iter)-pom.temp4(iter,1))^2;
   s5 = s5 + (model.yzad(5,iter)-pom.temp5(iter,1))^2;
   
   %b³¹d œredniokwadratowy
   if(i==iter)
      MSE1 = s1/(iter-pocz); 
      MSE2 = s2/(iter-pocz); 
      MSE3 = s3/(iter-pocz); 
      MSE4 = s4/(iter-pocz); 
      MSE5 = s5/(iter-pocz); 
      
      %pierwiastek z b³êdu œredniokwadratowego
      RMSE1 = sqrt(MSE1);
      RMSE2 = sqrt(MSE2);
      RMSE3 = sqrt(MSE3);
      RMSE4 = sqrt(MSE4);
      RMSE5 = sqrt(MSE5);
      
      clear s1 s2 s3 s4 s5
   end


end

