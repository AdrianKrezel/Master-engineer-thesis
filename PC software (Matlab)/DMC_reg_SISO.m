%% DMC SISO

%setpoint
dmc.Ysp = model.yzad(5,iter); 

%obliczenie DMC
U = dmc.calc();

%sterowanie salonu
DMC.u(5,iter) = U(1);

%przeskalowanie sterowania dla innych pomieszczeñ
for (i=1:4)
   DMC.u(i,iter) = round( model.wsp2(i,1)*DMC.u(5,iter) );
end

%aktualna temperatura
Y5 = pom.temp5(iter,1);


dmc.Ypv = [Y5]; % wpisanie odpowiedzi uk³adu na wejscie regulatora



