%% UART_connect -----------------------------------------------------------
%  Nawi�zanie po��czenia pomi�dzy PC, a uC
%
%--------------------------------------------------------------------------

function UART_port = UART_connect(UART_settings)
    disp('2. TWORZENIE KANA�U KOMUNIKACYJNEGO');
    while(1)
        UART_port_list = instrfind;   %lista port�w szeregowych
        UART_port = instrfind('Type',UART_settings.Type,'Port',UART_settings.Port, 'Tag', ''); %port przez kt�ry si� ��czymy

        if isempty(UART_port) %wolny kana�, po��cz
            UART_port = serial(UART_settings.Port, 'BaudRate', UART_settings.BaudRate); %parametry transmisji
            set(UART_port,'Timeout',UART_settings.Timeout);
            fopen(UART_port);
            disp('   Ok. Port szeregowy otworzono poprawnie');
            break;
        else %kana� zaj�ty, zwolnij kana�
            fclose(UART_port);
            delete(UART_port);
            disp('   Nie otworzono portu poprawnie. Ponawiam pr�b�');
        end
    end
end