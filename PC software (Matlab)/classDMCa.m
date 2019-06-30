classdef classDMCa < handle
    %% DMC control alghoritm

    
    %% private atributes
    properties(GetAccess = 'public', SetAccess = 'private')
        ny = 1;     % inputs (PV) number
        nu = 1;     % control outputs (MV) number
        
        %y0 = [];    % free response matrix
        %du = [];    % delta control matrix
        
        M = [];     % dynamic matrix
        Mp = [];    % dynamic matrix corresponding with past
        
        K1 = [];    % gain vector
        Ke = [];    % Sum p=N1:N   K_1,p-N1+1
        Ku = [];    % Ku(j) = K1 * Mp(j), Mp = [Mp(1) Mp(2) ... Mp(D-1)]
        
        dUp = [];   % ManipulatedValues from past matrix
        
        % computed limit matrix for numerical alghoritm (dim: nu * Nu)
        dU_min = [];
        dU_max = [];
        U_min = [];
        U_max = [];
        
        % matrix for numerical alghoritm
        num_U_prev_k = []; % U(k-1)
        num_U_k = [];       % U(k)
       % num_dUk = [];       % dU(k)
        num_dUp = [];
        
        num_J = [];
        num_H = [];
        num_A = [];
        num_b = [];
        
    end
    
    %% public atributes
    properties(GetAccess = 'public', SetAccess = 'public')
        settings = struct('type','analytical','limitsOn',0,'userDefinedPsiAndLambda',0);
        
        D = 1;      % dynamic horizon
        N = 1;      % prediction horizon
        Nu = 1;     % control horizon
        
        N1 = 1;
                % prof. Tatjewski (s. 120):
                %
                % Przyjêcie wartoœci N 1 > 1 jest sensowne wówczas, gdy w obiekcie wystêpuje opóŸnienie
                % powoduj¹ce w chwilach k + 1,...,k + N 1 ? 1 brak reakcji wyjœæ na zmianê
                % sterowania w chwili k. Oczywiœcie, przyjêcie N 1 = 1 nie jest b³êdem równie¿
                % w sytuacji wystêpowania opóŸnienia – jedynie wówczas pierwszych N 1 ? 1
                % sk³adników pierwszej z sum funkcji (3.1) bêdzie w procesie optymalizacji
                % niepotrzebnie obliczanych, jako niezale¿nych od wyliczanych wartoœci ste-
                % rowañ. Czasem jednak przyjmuje siê w literaturze przedmiotu N 1 = 1,
                % 3.1. Zasada regulacji predykcyjnej 121
                % dla jednolitoœci zapisu, co jak wspomniano powy¿ej nie prowadzi do utraty
                % poprawnoœci sformu³owañ. D³ugoœæ horyzontu sterowania N u spe³nia ogra-
                % niczenia 0 < N u <= N. Z regu³y przyjmuje siê N u < N, a powodem takiego
                % postêpowania jest d¹¿enie do zmniejszenia wymiarowoœci zadania optyma-
                % lizacji, a st¹d nak³adu obliczeñ.
                %
                % (s. 138):
                % Dla standardowej wartoœci N 1 = ? + 1, gdy pierwsze ? = N 1 ? 1 wspó³-
                % czynników odpowiedzi skokowej jest zerami
                
        % ?
        PSI = []; 
                % % prof. Tatjewski (s. 121):
                %
                % jest macierz¹ wag umo¿liwiaj¹c¹ ró¿nicowa-
                % nie wp³ywu poszczególnych sk³adowych wektora wyjœæ wzglêdem siebie
                % w chwili k + p, zwykle jest to macierz diagonalna. Jeœli macierze ?(p)
                % s¹ ró¿ne dla ró¿nych wartoœci p, to nastêpuje te¿ ró¿nicowanie wp³ywu
                % prognozowanych w poszczególnych chwilach wartoœci uchybów regulacji
                % y zad (k + p|k) ? y(k + p|k) na wartoœæ funkcji kryterialnej. Jeœli ró¿nicowa-
                % nie zarówno sk³adowych wektora uchybów wzglêdem siebie w poszczegól-
                % nych chwilach, jak i w ró¿nych chwilach w zakresie horyzontu predykcji nie
                % jest potrzebne, to uzyskujemy najprostszy przypadek ?(p) = I, gdzie I
                % oznacza macierz jednostkow¹ o wymiarze n y ×n y 
                
        % ? - ma³a lambda        
        lambda = 0;        
        % ? - du¿a lambda      
        LAMBDA = []; 
                % % prof. Tatjewski (s. 121):
                %
                % Rol¹ macierzy ?(p) ? 0
                % jest, z kolei, nie tylko ró¿nicowanie wzajemnego wp³ywu poszczególnych
                % sk³adowych wektora przyrostów sterowania na rezultaty optymalizacji, ale
                % przede wszystkim okreœlanie wagi wp³ywu sk³adników drugiej sumy w funk-
                % cji (3.1) w stosunku do sumy pierwszej, tzn. wagi sk³adników zwi¹zanych
                % z t³umieniem zmiennoœci sterowañ wobec sk³adników odpowiadaj¹cych pro-
                % gnozowanym uchybom regulacji. W najprostszym przypadku braku ró¿ni-
                % cowania wp³ywu wektorów przyrostów sterowañ w zale¿noœci od chwili ho-
                % ryzontu predykcji, jak i poszczególnych sk³adowych wektora przyrostów ste-
                % rowañ wzglêdem siebie w tych samych chwilach, dostajemy ?(p) = ?I, gdzie
                % I jest macierz¹ jednostkow¹ o wymiarze n u × n u .
        
        S = [];     % step response matrix
                    % (S_size(1) == obj.ny) && (S_size(2) == obj.nu) && (S_size(3) == obj.D)
        
        u_start = []; % startup values of manipulated values
        u_k = [];   % current manupulated velues

        Ypv = [];   % ProcessValues matrix
                    % Ypv = [y1_pv
                    %        y2_pv
                    %        y3_pv
                    %        ...
                    %        ny_pv];
                    %
        Ysp = [];   % SetPoint matrix
                    % Ysp = [y1_sp
                    %        y2_sp
                    %        y3_sp
                    %        ...
                    %        ny_sp];
                    
        % limits
        du_min = [] % du min:
                    % dUmin = [du1_min
                    %          du2_min
                    %          du3_min
                    %          ...
                    %          dnu_min];
        du_max = [] % dU max:
                    % dUmax = [du1_max
                    %          du2_max
                    %          du3_max
                    %          ...
                    %          dnu_max];
         u_min = [] % U min:
                    %  Umin = [u1_min
                    %          u2_min
                    %          u3_min
                    %          ...
                    %          nu_min];    
         u_max = [] % U max:
                    %  Umax = [u1_max
                    %          u2_max
                    %          u3_max
                    %          ...
                    %          nu_max]; 
    end
    
    %% public methotd
    methods(Access = 'public')
        %% constructor
        function obj = classDMCa(ny, nu)
            obj.ny = ny;
            obj.nu = nu;
            
            obj.u_start = zeros(1, nu);
            
            %disp('created DMC regulator using classDMCa -- mciok@mion.elka.pw.edu.pl');
        end
        %% initialize structure
        function init(obj)
            % settings = struct('type','analytical','limitsOn',0,'userDefinedPsiAndLambda',0);
            switch (obj.settings.type)
                case 'analytical'
                    obj.init_anal();
                case 'numerical'
                    obj.init_num();
                otherwise
                    error('Type must be: analytical or numerical');
            end
            
            switch (obj.settings.limitsOn)
                case 0
                case 1
                otherwise
                    error('limitsOn must be 0 or 1');
            end
            
            switch (obj.settings.userDefinedPsiAndLambda)
                case 0
                case 1
                otherwise
                    error('limitsOn must be 0 or 1');
            end
        end
        
        %% calculate
        function ret_u = calc(obj)
            switch (obj.settings.type)
                case 'analytical'
                    ret_u = obj.calc_anal();
                case 'numerical'
                    ret_u = obj.calc_num();
                otherwise
                    error('Type must be: analytical or numerical');
            end
        end
    end
    
    %% internal methods
    methods(Access='private')
        %% initialize analytical
        function init_anal(obj)
            S_size = size(obj.S);
            if ~( (S_size(1) == obj.ny) && (S_size(2) == obj.nu) && (S_size(3) == obj.D) )
               error('Wrong step response matrix dimmension. Interrupting');
            end
            
            if (obj.N1 < 0) || (obj.N1 > obj.N) || (obj.Nu > obj.N) || (obj.N < 0) || (obj.Nu < 0) || (obj.D < 0)
                error('Invalid parameters values');    
            end
            
            if obj.settings.limitsOn == 1
                if(~(size(obj.u_max,1)==obj.nu && size(obj.u_max,2)==1))
                    error('u_max dimmension error');
                end
                if(~(size(obj.u_min,1)==obj.nu && size(obj.u_min,2)==1))
                    error('u_min dimmension error');
                end
            end
            
            if obj.settings.userDefinedPsiAndLambda == 0
                % --- weight matrix
                obj.PSI = eye(obj.ny * (obj.N-obj.N1+1));
                % --- cost matrix
                obj.LAMBDA = obj.lambda * eye(obj.nu*obj.Nu);
                %warning('PSI and LAMBDA matrix are forced to default');
            end
            
%             % --- M  ( dim: ny * (N - N1 + 1 )  x  nu * Nu  )
%             obj.M = zeros(obj.ny*(obj.N-obj.N1+1), obj.nu*obj.Nu);
%             
%             for i=1:(obj.N - (obj.N1 - 1))
%                for j=1:obj.Nu
%                   if (((i+obj.N1-1) - j +1) > 0)
%                      obj.M(obj.ny*(i-1)+1:obj.ny*(i-1)+obj.ny, obj.nu*(j-1)+1:obj.nu*(j-1)+obj.nu) = obj.S(:,:,(i+obj.N1-1) - j +1);
%                   end
%                end
%             end

            % --- M - nowa wersja
            M_cell = cell(obj.N-(obj.N1-1), obj.Nu);
            for i=1:obj.N-(obj.N1-1)
               for j=1:obj.Nu
                   if i >= j                
                      M_cell{i,j} = obj.S(:,:,i-j+1); %(obj.N1+i-1) - (j-1) ); 
                   else
                      M_cell{i,j} = zeros(obj.ny,obj.nu);
                   end
               end
            end
            obj.M = cell2mat(M_cell);
             
% %            --- Mp ( dim: ny * (N - N1 + 1)  x  nu * (D - 1)  )
%             obj.Mp = zeros(obj.ny*(obj.N-obj.N1+1), obj.nu*(obj.D-1));
%             for i=1:(obj.N - (obj.N1 - 1))
%                for j=1:(obj.D-1)
%                   if (i+j+obj.N1-1 <= obj.D)
%                      obj.Mp(obj.ny*(i-1)+1:obj.ny*(i-1)+obj.ny, obj.nu*(j-1)+1:obj.nu*(j-1)+obj.nu) = obj.S(:,:,(i+j+obj.N1-1)) - obj.S(:,:,j);
%                   else
%                      obj.Mp(obj.ny*(i-1)+1:obj.ny*(i-1)+obj.ny, obj.nu*(j-1)+1:obj.nu*(j-1)+obj.nu) = obj.S(:,:,obj.D) - obj.S(:,:,j);
%                   end      
%                end
%             end

            % --- Mp - nowa wersja
            Mp_cell = cell(obj.N-(obj.N1-1), obj.D-1);
            for i=1:obj.N-(obj.N1-1)
               for j=1:obj.D-1
                   if (i+j+(obj.N1-1) <= obj.D)
                       Mp_cell{i,j} = obj.S(:,:,i+j+obj.N1-1) - obj.S(:,:,j);
                   else
                       Mp_cell{i,j} = obj.S(:,:,obj.D) - obj.S(:,:,j);
                   end
               end
            end
            obj.Mp = cell2mat(Mp_cell);
             
            % --- K
            K = inv(obj.M' * obj.PSI * obj.M + obj.LAMBDA) * obj.M' * obj.PSI;
            %K = inv(obj.M' * obj.M + obj.LAMBDA) * obj.M';
            obj.K1 = K(1:obj.nu,:);
            % --- Ke
            obj.Ke = zeros(obj.nu, obj.ny);
            for p=obj.N1:obj.N
               r = p-obj.N1+1;
               obj.Ke(:,:) = obj.Ke(:,:) + obj.K1(:,obj.ny*(r-1)+1:obj.ny*r);
            end
            % --- Ku
            obj.Ku = [];
            for p=1:(obj.D-1)
               obj.Ku(:,:,p) = obj.K1 * obj.Mp(:, obj.nu*(p-1)+1:obj.nu*p);
            end
            
            % --- dU
            obj.dUp = zeros((obj.D-1)*obj.nu,1);
            obj.u_k = obj.u_start;
        end
        
        %% calculation
        function ret_u = calc_anal(obj)
            
            suma = zeros(obj.nu,1);
            for j=1:obj.D-1
               suma = suma + obj.Ku(:,:,j)*obj.dUp(obj.nu*(j-1)+1:obj.nu*j);
            end
            e = obj.Ysp - obj.Ypv;
            du = (obj.Ke * e) - suma;

            % reorganize past manipulated values matrix v2
            temp = zeros((obj.D-1)*obj.nu,1);
            temp(obj.nu+1:end) = obj.dUp(1:end-obj.nu);
            obj.dUp = temp;

            % U limit
            if obj.settings.limitsOn == 1
                for j=1:obj.nu
                    if(du(j)+obj.u_k(j) > obj.u_max(j)) 
                        du(j) = obj.u_max(j)-obj.u_k(j);
                    end
                    if(du(j)+obj.u_k(j) < obj.u_min(j)) 
                        du(j) = obj.u_min(j)-obj.u_k(j);
                    end
                end  
            end
            
            obj.dUp(1:obj.nu) = du;
            
            % compute U(k)
            %disp(du); 
            obj.u_k = obj.u_k + du;
            
            
            % return value
            ret_u = obj.u_k;
        end
        
        %% initialize numeric alghoritm with limits on Manipulated Values:
        %
        %   -dUmax <= dU(k) <= dUmax
        %   Umin <= U(k-1) + JdU(k) <= Umax
        %
        function init_num(obj)
           % check limits matrix dimmension
           if(~(size(obj.du_max,1)==obj.nu && size(obj.du_max,2)==1))
               error('du_max dimmension error');
           end
           if(~(size(obj.u_max,1)==obj.nu && size(obj.u_max,2)==1))
               error('u_max dimmension error');
           end
           if(~(size(obj.u_min,1)==obj.nu && size(obj.u_min,2)==1))
               error('u_min dimmension error');
           end
           % initialize matrix
           obj.init_anal();
           
           % compute limits matrix
           obj.dU_max = zeros(obj.nu*obj.Nu,1);
           %obj.dU_min = zeros(obj.nu*obj.Nu,1);
           obj.U_max = zeros(obj.nu*obj.Nu,1);
           obj.U_min = zeros(obj.nu*obj.Nu,1);
           for j=1:obj.Nu
               obj.dU_max(obj.nu*(j-1)+1:obj.nu*j, 1) = obj.du_max;
               %obj.dU_min(obj.nu*(j-1)+1:obj.nu*j, 1) = obj.du_min;
               obj.U_max(obj.nu*(j-1)+1:obj.nu*j, 1) = obj.u_max;
               obj.U_min(obj.nu*(j-1)+1:obj.nu*j, 1) = obj.u_min;
           end
           
           disp('dU_max =');
           disp(obj.dU_max);
           disp('U_max =');
           disp(obj.U_max);
           disp('dU_min =');
           disp(obj.U_min);
           
           
           % --- dU(k), dUp, U(k-1) default initialization
           %obj.num_dUk = zeros(obj.nu*obj.Nu, 1);
           obj.num_dUp = zeros((obj.D-1)*obj.nu, 1);
           obj.num_U_prev_k = zeros(obj.nu*obj.Nu, 1);
           
           obj.num_U_k = zeros(obj.nu*obj.Nu, 1);
           
           % --- J ( dim:  Nu*nu  x  Nu*nu )
           I = eye(obj.nu);
           obj.num_J = zeros(obj.Nu*obj.nu); % dim ?
           for i=1:obj.Nu
               for j=1:obj.Nu
                   if j<=i
                        obj.num_J(obj.nu*(i-1)+1:obj.nu*i, obj.nu*(j-1)+1:obj.nu*j) = I;
                   end
               end
           end
           
           % --- H
           obj.num_H = 2*(obj.M' * obj.PSI * obj.M + obj.LAMBDA);
           
           % --- A
           obj.num_A = [-obj.num_J; obj.num_J;];

        end
        
        %% calculate numeric algorithm
        function ret_u = calc_num(obj)
            % prepare vectors of Y_sp and Y_pv
            Y_sp = zeros(obj.ny*(obj.N-obj.N1+1), 1);
            Y_pv = zeros(obj.ny*(obj.N-obj.N1+1), 1);
            
            for j=1:(obj.N-obj.N1+1)
                Y_sp(obj.ny*(j-1)+1:obj.ny*j) = obj.Ysp;
                Y_pv(obj.ny*(j-1)+1:obj.ny*j) = obj.Ypv;
            end
            e = Y_sp - Y_pv;

            % limits:
            x_min = -obj.dU_max; % lb for quadprog
            x_max = obj.dU_max;  % ub for quadprog
            %x_0 = ... ?
            
            % --- f
            f = -2*obj.M'*obj.PSI*(e - obj.Mp*obj.num_dUp);
            
            % --- b
            b = [-obj.U_min + obj.num_U_prev_k;
                 obj.U_max - obj.num_U_prev_k;];
            
            % solver execution
            dUk = quadprog(obj.num_H, f, obj.num_A, b, [], [], x_min, x_max);
            
            % reorganize past manipulated values matrix
            for j=(obj.D-1)*obj.nu:-1:obj.nu+1
               obj.num_dUp(j,:) = obj.num_dUp(j-obj.nu,:); 
            end
            %disp('begin');
            %disp(dUk);
            %disp('end');
            obj.num_dUp(1:obj.nu,:) = dUk(1:obj.nu,:);
            
            % current control vector ( U(k) )
            for j=1:obj.Nu
                obj.num_U_k(obj.nu*(j-1)+1:obj.nu*j,:) = obj.num_U_k(obj.nu*(j-1)+1:obj.nu*j,:) + dUk(1:obj.nu,:);
            end
            
            % past control vector ( U(k-1) ) for next iteration
            obj.num_U_prev_k = obj.num_U_k;
            
            % return value
            ret_u = obj.num_U_k(1:obj.nu,:)';
        end
    end
    
end

