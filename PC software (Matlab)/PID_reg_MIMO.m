%% TEST PID MIMO

%aktualna temperatura
model.ymod(1,iter) = pom.temp1(iter,1);
model.ymod(2,iter) = pom.temp2(iter,1);
model.ymod(3,iter) = pom.temp3(iter,1);
model.ymod(4,iter) = pom.temp4(iter,1); 
model.ymod(5,iter) = pom.temp5(iter,1);
    
if(iter>=2)%model.kp)

    %uchyb regulacji
    pid.e(1:5,iter) = model.yzad(1:5,iter) - model.ymod(1:5,iter); %uchyb dla ka¿dego pomieszczenia osobno

    %PID: wzory 2.114, 2.115, 2.116
    for(i=1:5)
        pid.up(i,iter) = pid.Ke(i,1)*pid.e(i,iter);  
        pid.ui(i,iter) = pid.ui(i,iter-1) + (model.Tp/(2*pid.Ti(i,1)))*(pid.e(i,iter)+pid.e(i,iter-1));
        pid.ud(i,iter) = ((2*pid.Td(i,1)-model.Tp)/(model.Tp+2*pid.Td(i,1)))*pid.ud(i,iter-1) + ...
                         (2*pid.Kd(i,1)/(model.Tp+2*pid.Td(i,1)))*(pid.e(i,iter)-pid.e(i,iter-1));
    end

    %sterowanie pokoi
    pid.u(1:5,iter) = pid.up(1:5,iter) + pid.ui(1:5,iter) + pid.ud(1:5,iter);

    %ciêcie sterowania
    for(i=1:5)
        if(pid.u(i,iter)>200) %to jest 100% mocy dla mikrokontrolera (je¿eli wyœlemy mu wiêcej, to mo¿e sypaæ dziwnymi wartoœciami (kwestia konfiguracji timerów sprzêtowych)
            pid.u(i,iter)=200;
			pid.ui(i,iter)=0; %antiwindup
        elseif(pid.u(i,iter)<=0)
            pid.u(i,iter)=0;  
            pid.ui(i,iter)=0; %antiwindup
%         elseif(pid.u(i,iter)>0 && pid.u(i,iter)<20)
%             pid.u(i,iter)=20;
%         end
        end
    end

%     %model
%     for(i=1:5)
%         model.ymod(i,iter) = a(i,1)*model.ymod(i,iter-1) + b(i,1)*pid.u(i,iter);
%     end
end

          
