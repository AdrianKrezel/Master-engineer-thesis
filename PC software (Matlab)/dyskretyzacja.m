%NOWE TFy 
    %Brak skalowania wzgl�dem wielko�ci pomieszcze�. Regulator z modelem 
    %MIMO nie musi mie� ogranicze� (skalowania) mocy grzejnik�w, tak jak to jest w SISO
    %gdzie przyrosty temperatury innych pomieszcze� musia�y by� proporcjonalne
    %do przyrostu temperatury salonu wzgl�dem kt�rego by�o sterowane.
    %W poprzednich tfach by�o dodatkowo skalowanie, kt�re zaburza�o model w
    %stosunku do tego jak odbywa�o si� sterowanie na makiecie

    format long
s=tf('s'); 

if(regulator==1 || regulator==3)
    model.L1 = 0.4286;
    model.T = 1000;
    
    model.delay = 20;
    
    %model ci�g�y
    model.Gs = model.L1*exp(-model.delay*s)/(model.T*s+1);
    
    %dyskretyzacja
    model.Gz = c2d(model.Gs,model.Tp,'zoh');
    Ld = cell2mat(model.Gz.num);
    Md = cell2mat(model.Gz.den);
    model.a = -Md(2); %mianowniki poszczeg�lnych transmitancji (do r�wnania r�nicowego)
    model.b = Ld(2);  %liczniki poszczeg�lnych transmitancji (do r�wniania r�nicowego)
        
elseif(regulator==4 || regulator==2)   
    model.L1 = [0.4198 0.0982 0.0415 0.0305 0.0835;...
                0.0870 0.4411 0.0841 0.0444 0.0744;...
                0.0626 0.1224 0.5159 0.1371 0.1325;...
                0.0534 0.0619 0.1390 0.5228 0.1379;...
                0.0962 0.0680 0.0671 0.0533 0.3321];
    %T 
    model.T = [1210 2356 3215 3177 2504;...
               3030 1116 2600 3076 3057;...
               3385 2854 981  2362 3068;...
               2820 3592 2862 925  3540;...
               2758 2863 3820 2923 1490];
%     model.T = round(model.T/model.Tp);

    model.delay = [ 59  678 385 323 50;...
                    70   64 300 200 50;...
                   115  250  50 156 48;...
                   130  220  79  51 60;...
                   216 1000 356 465 37];
    model.delayK = round(model.delay/model.Tp); %op�nienie w krokach dla macierzy transmitancji 5x5

    for(i=1:5)
        for(j=1:5)
            model.Gs(i,j) = model.L1(i,j)*exp(-model.delay(i,j)*s)/(model.T(i,j)*s+1);
        end
    end
    %dyskretyzacja
    model.Gz = c2d(model.Gs,model.Tp,'zoh');
    model.a = zeros(5,5);
    model.b = zeros(5,5);    
    for(i=1:5)
        for(j=1:5)
            Ld = cell2mat(model.Gz(i,j).num);
            Md = cell2mat(model.Gz(i,j).den);
            model.a(i,j) = -Md(2); %mianowniki poszczeg�lnych transmitancji (do r�wnania r�nicowego)
            model.b(i,j) = Ld(2);  %liczniki poszczeg�lnych transmitancji (do r�wniania r�nicowego)
        end
    end
end