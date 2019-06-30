%% UART_connect -----------------------------------------------------------
%  Nawi¹zanie po³¹czenia pomiêdzy PC, a uC
%
%--------------------------------------------------------------------------

function UART_port = UART_connect(UART_settings)
    disp('2. TWORZENIE KANA£U KOMUNIKACYJNEGO');
    while(1)
        UART_port_list = instrfind;   %lista portów szeregowych
        UART_port = instrfind('Type',UART_settings.Type,'Port',UART_settings.Port, 'Tag', ''); %port przez który siê ³¹czymy

        if isempty(UART_port) %wolny kana³, po³¹cz
            UART_port = serial(UART_settings.Port, 'BaudRate', UART_settings.BaudRate); %parametry transmisji
            set(UART_port,'Timeout',UART_settings.Timeout);
            fopen(UART_port);
            disp('   Ok. Port szeregowy otworzono poprawnie');
            break;
        else %kana³ zajêty, zwolnij kana³
            fclose(UART_port);
            delete(UART_port);
            disp('   Nie otworzono portu poprawnie. Ponawiam próbê');
        end
    end
end