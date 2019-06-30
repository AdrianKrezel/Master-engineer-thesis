%% UART_rcv ---------------------------------------------------------------
%  Odebranie temperatur od uC
%
%--------------------------------------------------------------------------
    %odbiór danych
    clear t1 t2 t3 t4 t5 t6 t7 t8 t9 t10 txt 

    txt = fread(UART_port,123); %odbiór danych  
    txt = char(txt');

    eval(txt); %wy³uskanie wartoœci temperatur
    pom.temp1 = [pom.temp1;  t1];    
    pom.temp2 = [pom.temp2;  t2];       
    pom.temp3 = [pom.temp3;  t3];        
    pom.temp4 = [pom.temp4;  t4];        
    pom.temp5 = [pom.temp5;  t5];        
    pom.temp6 = [pom.temp6;  t6]; 
    pom.temp7 = [pom.temp7;  t7];
    pom.temp8 = [pom.temp8;  t8];
    pom.temp9 = [pom.temp9;  t9];
    pom.temp10 = [pom.temp10; t10];


