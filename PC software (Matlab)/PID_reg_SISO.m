%% PID SISO

%aktualna temperatura
model.ymodel(5,iter) = pom.temp5(iter);    %<-- aktualna temperatura w salonie

if(iter>=2) %uruchomienie PIDa po wygrzaniu makiety 
    %uchyb regulacji
    pid.e(5,iter) = model.yzad(5,iter) - model.ymodel(5,iter); %salon (opóŸnienie o 30s)

    %PID: (wzory 2.114, 2.115, 2.116) 
    pid.up(5,iter) = pid.Ke(5,1)*pid.e(5,iter);  
    pid.ui(5,iter) = pid.ui(5,iter-1) + (model.Tp/(2*pid.Ti(5,1)))*(pid.e(5,iter)+pid.e(5,iter-1));
    pid.ud(5,iter) = ((2*pid.Td(5,1)-model.Tp)/(model.Tp+2*pid.Td(5,1)))*pid.ud(5,iter-1) + ...
                     (2*pid.Kd(5,1)/(model.Tp+2*pid.Td(5,1)))*(pid.e(5,iter)-pid.e(5,iter-1));

    pid.u(5,iter) = round(pid.up(5,iter) + pid.ui(5,iter) + pid.ud(5,iter)); %<-- sterowanie dla salonu  
    
    if(pid.u(5,iter)>200)
        pid.u(5,iter)=200;
        pid.ui(5,iter)=0; %antiwindup
    elseif(pid.u(5,iter)<=0)
        pid.u(5,iter)=0;
        pid.ui(5,iter)=0; %antiwindup
    end
    for (i=1:4)
       pid.u(i,iter) = round( model.wsp2(i,1)*pid.u(5,iter) );
    end
end




