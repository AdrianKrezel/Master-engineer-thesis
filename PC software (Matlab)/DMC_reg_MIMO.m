%% TEST DMC MIMO

%setpointy
for(k=1:5)
    dmc.Ysp(k,1) = model.yzad(k,iter); 
end

%% Oblicznie sterowania
U = dmc.calc();

DMC.u(1,iter) = U(1);
DMC.u(2,iter) = U(2);
DMC.u(3,iter) = U(3);
DMC.u(4,iter) = U(4);
DMC.u(5,iter) = U(5);
    
%aktualna temperatura
Y1 = pom.temp1(iter,1);
Y2 = pom.temp2(iter,1);
Y3 = pom.temp3(iter,1);
Y4 = pom.temp4(iter,1);
Y5 = pom.temp5(iter,1);

dmc.Ypv = [Y1; Y2; Y3; Y4; Y5]; % wpisanie odpowiedzi uk³adu na wejscie regulatora

