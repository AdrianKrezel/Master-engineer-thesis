suma1=0;suma2=0;suma3=0;suma4=0;suma5=0;
%Tp
if(regulator==1 || regulator==2)
    pocz=3601;
elseif(regulator==3)
    pocz=721;
elseif(regulator==4)
    pocz=361;
end

for(i=pocz:iter)
    suma1=suma1+ster.PWM1(i,1); %od 1 grzejnika
    suma2=suma2+ster.PWM2(i,1); %od 2 grzejnika
    suma3=suma3+ster.PWM3(i,1); %od 3 grzejnika
    suma4=suma4+ster.PWM4(i,1); %od 4 grzejnika
    suma5=suma5+ster.PWM5(i,1); %od 5 grzejnika
end

if(regulator==3 || regulator==4) %Tp=10
    suma1 = model.Tp*suma1;
    suma2 = model.Tp*suma2;
    suma3 = model.Tp*suma3;
    suma4 = model.Tp*suma4;
    suma5 = model.Tp*suma5;
end

SUMA=suma1+suma2+suma3+suma4+suma5; %suma energii

