%% DEFINIÇÃO DO CARACTERES DO ALFABETO E NUMÉRICOS
clear all
pkg load io

%% DEFINIÇÃO DAS VARIÁVEIS DE ENTRADA

% Placa reconhecida no vestígio (a ser analisada)
% Cada elemento do cell array representa possíveis caracteres da placa
% Deixe em branco aqueles caracteres não reconhecidos
QST{1}={[""];[""];[""];["132"];["J"];["320"];["4"]};
% Subconjunto para pesquisa
QST{2}={["KRS"];["QRVYWNM"];["VYWNM"];["13"];["J"];["32"];["4"]};
%SE NÃO CONTEMPLAR TODOS OS CARACTERES DO SUSPEITO,  NÃO FUNCIONARÁ
%% Ano limite do modelo que aparece nas imagens
ano=2011;


% Padrão MERCOSUL?
% 1 para sim, 0 para não
MS = 1; %NÃO CONFIGURE UMA COISA E FORNEÇA OUTRA NOS CANDIDATOS OU SUSPEITO

% Placa do suspeito, caso exista
SUSP = ["KVM3J24"];

% Unidade Federativa (UF) de interesse
uf = "RJ";

% Controle: usar ou não a matriz de confusão
% 1 para usar, 0 para não usar
confusao = 1;

% Proporção da frota de fora da UF de interesse (valor default: 33%)
pf = 0.33; % Valor padrão usado para eventos singulares
pd = 1 - pf; % Probabilidade dentro da UF


% Proporção da frota do mesmo tipo do QUESTIONADO
%(valor default: 64%, porção de automóveis)
pt = 0.64; % Valor padrão usado para eventos singulares

% Proporção da frota do mesmo modelo do QUESTIONADO
% valor default: 43%, mais popular)
pm = 0.43; % Valor padrão usado para eventos singulares

% Proporção da frota da mesma cor do QUESTIONADO
%(valor default: 33%, cor mais predominante)
pc = 0.34; % Valor padrão usado para eventos singulares

%% DEFINIÇÃO DE CONSTANTES

% Letras do alfabeto
ALFA = ["ABCDEFGHIJKLMNOPQRSTUVWXYZ"];
% Dígitos numéricos e letras associadas a números (exemplo: placas especiais)
NUMB1 = ["0123456789"]; % Dígitos numéricos
NUMB2 = ["ABCDEFGHIJ"]; % Letras que representam números
NUMB = [NUMB1, NUMB2];  % Combinação de ambas


%% LEITURA E AJUSTE DA MATRIZ DE CONFUSÃO

% Carregar ou criar a matriz de confusão, dependendo da configuração
if confusao == 1
    % Lê a matriz de confusão de um arquivo CSV
    CMATRIX = dlmread('CMATRIX.csv', ";");
else
    % Cria uma matriz identidade para simular um cenário sem erros
    CMATRIX = diag(ones(1, 36));
end

% Ajustar as submatrizes da matriz de confusão
% As submatrizes CLET e CNUM representam a confusão entre letras e números

% Submatriz para confusão entre letras (caracteres 11 a 36)
CLET = CMATRIX(11:36, 11:36);
% Adiciona a diagonal para ajustar valores e normaliza por linha
CLET = CLET + diag(100 - sum(CLET, 2));
CLET = CLET ./ sum(CLET, 2); % Normalização

% Submatriz para confusão entre números (caracteres 1 a 10)
CNUM = CMATRIX(1:10, 1:10);
% Adiciona a diagonal para ajustar valores e normaliza por linha
CNUM = CNUM + diag(100 - sum(CNUM, 2));
CNUM = CNUM ./ sum(CNUM, 2); % Normalização

% Submatriz N2 para confusão específica entre números e letras (exemplo: 0 e O, 1 e I)
N2 = CMATRIX(11:20, 11:20);
N2 = N2 + diag(100 - sum(N2, 2));
CNUM(11:20, 11:20) = N2 ./ sum(N2, 2); % Ajuste na matriz CNUM



%%  COMBINAÇÕES DO ESTADO E AS INEXISTENTES

% Carregar os estados a partir do arquivo CSV
% 'csv2cell' é usado para carregar dados que incluem strings
ESTADOS = csv2cell('Estados.csv', ';');

% Transpor a matriz para facilitar a manipulação (linhas -> colunas)
ESTADOS = ESTADOS';

% Encontrar a posição da UF (unidade federativa) correspondente
[~, p_uf] = find(cellfun(@(x) isequal(uf, x), ESTADOS));

% Inicializar a matriz de combinações
COMB = num2str([]);

% Loop sobre os 28 estados (assumindo que há 28 colunas relevantes)
for k = 2:28
    % Obter a sequência de estados para o estado atual
    SEQT = {ESTADOS{2:end-4, k}};
    SEQT = SEQT(~cellfun(@isempty, SEQT)); % Remover células vazias

   % Inicializar as novas combinações para este estado
    NDEF =  num2str([]);

    % Processar cada sequência na linha atual
    for k1 = 1:size(SEQT, 2)
        SEQ = SEQT{:,k1}; % Obter a sequência atual

        % Determinar o índice inicial e final da faixa de combinações
        inicial = (find(ALFA == SEQ(1)) - 1) * 26^2 + ...
                  (find(ALFA == SEQ(2)) - 1) * 26 + ...
                  (find(ALFA == SEQ(3)) - 1);
        final = (find(ALFA == SEQ(5)) - 1) * 26^2 + ...
                (find(ALFA == SEQ(6)) - 1) * 26 + ...
                (find(ALFA == SEQ(7)) - 1);
        ANO=SEQ(end-3:end);
        % Gerar combinações dentro do intervalo inicial-final
        for k2 = inicial:final
            letra1 = ALFA(floor((k2) / 26^2) + 1); % Primeira letra
            letra2 = ALFA(floor(rem(k2, 26^2) / 26) + 1); % Segunda letra
            letra3 = ALFA(floor(rem(rem(k2, 26^2), 26)) + 1); % Terceira letra
            NDEF = [NDEF; letra1, letra2, letra3,ANO]; % Adicionar à lista de combinações
        end
    end

    % Concatenar as novas combinações com o nome do estado
    COMB = [COMB; NDEF, repmat(ESTADOS{1, k}, [size(NDEF, 1), 1])];
end


b=str2double(COMB(:,4:7))<(ano+2); %EXCLUI SEQUÊNCIAS DE MODELOS MAIS RECENTES
COMB=COMB(b,:);


% Determinar o tamanho da frota nacional
% O valor está na penúltima linha da primeira coluna da célula 'ESTADOS'
% Isso assume que a última linha contém um total ou algo similar
nn = ESTADOS{end-2, 1}; % Valor da frota nacional (IBGE)

% Determinar o tamanho da frota da unidade federativa de interesse
% Utilizamos a posição 'p_uf' (definida anteriormente) para acessar a coluna da UF
nuf = ESTADOS{end-2, p_uf}; % Valor da frota da unidade federativa (IBGE)



for qst=1:2
clear LL Pp CAND
QUEST=QST{qst};

% Loop para encontrar os índices das células vazias em 'QUEST'
for k = find(cellfun(@isempty, QUEST))'
    % Verifica se o índice está na primeira parte da célula
    if k < 4
        % Se k for menor que 4, preenche a célula com o conjunto 'ALFA'
        QUEST{k} = ALFA;
    % Verifica se o índice é 5
    elseif k == 5 && MS
        % Se k for 5, preenche a célula com o conjunto 'NUMB2'
        QUEST{k} = NUMB2;
    % Caso contrário, preenche com o conjunto 'NUMB1'
    else
        QUEST{k} = NUMB1;
    end
end



%% LOOP PARA EXPANDIR OS CARACTERES QUE PODEM SER CONFUNDIDOS COM O QUE FOI OBSERVADO
%% AJUSTE DOS CONJUNTOS (USANDO MATRIZ DE CONFUSÃO OU NÃO)

if confusao
    % Inicializa a célula `Conf` para armazenar os resultados ajustados
    Conf = cell(1, 7);

    % Itera sobre as 7 posições de `QUEST`
    for k1 = 1:7
        conj = []; % Inicializa o conjunto para esta posição

        % Tratamento diferenciado para letras (k1 < 4) e números (k1 >= 4)
        if k1 < 4
            % Para letras, usa a matriz de confusão `CLET`
            for k2 = 1:length(QUEST{k1})
                % Encontra os índices na matriz de confusão que correspondem à letra atual
                conj = [conj; find(CLET(:, find(QUEST{k1}(k2) == ALFA)))];
            end
            % Remove duplicatas e converte os índices para as letras correspondentes
            conj = ALFA(unique(conj));
        else
            % Para números, usa a matriz de confusão `CNUM`
            for k2 = 1:length(QUEST{k1})
                % Encontra os índices na matriz de confusão que correspondem ao número atual
                conj = [conj; find(CNUM(:, find(QUEST{k1}(k2) == NUMB)))];
            end
            % Remove duplicatas e converte os índices para os números correspondentes
            conj = NUMB(unique(conj));
        end

        % Armazena o conjunto ajustado na célula `Conf`
        Conf{k1} = conj;
    end
else
    % Se a matriz de confusão não for usada, `Conf` recebe diretamente `QUEST`
    Conf = QUEST;
end

%% COMBINANDO OS CONJUNTOS E CALCULANDO AS PROBABILIDADES
CAND = Conf{1}(:); % Elementos do primeiro conjunto
LL = sum(CLET(ismember(ALFA, Conf{1}(:)), find(sum(QUEST{1}(:) == ALFA, 1))), 2)'; % Probabilidades do primeiro conjunto

% Itera sobre os demais conjuntos para combinar e calcular probabilidades
for k = 2:length(Conf)
    if k < 4
        % Para letras, utiliza a matriz de confusão `CLET`
        vero = sum(CLET(ismember(ALFA, Conf{k}(:)), find(sum(QUEST{k}(:) == ALFA, 1))), 2)';
    else
        % Para números, utiliza a matriz de confusão `CNUM`
        vero = sum(CNUM(ismember(NUMB, Conf{k}(:)), find(sum(QUEST{k}(:) == NUMB, 1))), 2)';
    end

    current_set = Conf{k}(:); % Próximo conjunto como vetor coluna
    current_probs = vero;    % Probabilidades associadas ao próximo conjunto

    % Cria grade cartesiana para combinar resultados acumulados com o próximo conjunto
    [A, B] = ndgrid(1:size(CAND, 1), 1:size(current_set, 1));
    CAND = strcat(CAND(A(:), :), current_set(B(:), :)); % Combina caracteres
    LL = LL(A) .* current_probs(B);              % Calcula probabilidades combinadas
end
LL=LL(:);

%% ELIMINA AS COMBINAÇÕES NÃO VÁLIDAS
[A, B] = ismember(CAND(:, 1:3), mat2cell(COMB(:, 1:3), ones(1, size(COMB(:, 1:3), 1)), 3));
Or = COMB(B(A), end-1:end);
LL = LL(A);               % Ajusta probabilidades
CAND = CAND(A, :);        % Ajusta combinações

if qst==1
%GUARDA CANDIDATOS E PROBABILIDADE DA TABELA COMPLETA
CANDC=CAND;
LLC=LL;
end
%% PROBABILIDADE PARA DENTRO E FORA DA UNIDADE FEDERATIVA


[~, b] = ismember(Or, ESTADOS(1, :)); % Identifica combinações sem definição

LAT = cell2mat(ESTADOS(end-1, :))';   % Latitude por UF
LNG = cell2mat(ESTADOS(end, :))';   % Longitude por UF

% Calcula probabilidade baseada na distância
Pp(ismember(Or, mat2cell(uf, ones(1, size(uf, 1)), 2))) = pd / nuf;
dist = haversine(LAT(p_uf), LNG(p_uf), LAT(b), LNG(b));
c = find(dist);

Pp(c) = sum(1 ./ dist(c)) .* (pf ./ (nn - nuf)) ./ dist(c);

%% CARREGA OS DADOS EM FORMA DE TABELA
if size(CAND, 1) > 1
    % Cria tabela para armazenar combinações e probabilidades
    CANDtable = cell(size(LL, 1), 7);
    CANDtable(:, 1) = mat2cell(CAND, ones(1, size(CAND, 1)), 7);
    CANDtable(:, 2) = mat2cell(Or, ones(1, size(CAND, 1)), 2);
    CANDtable(:, 3) = [""];
    CANDtable(:, 7) = mat2cell(num2str(LL * 100, 3), ones(1, size(CAND, 1)), size(num2str(LL * 100, 3), 2));
    CANDtable(:, 7) = strrep(CANDtable(:, 7), '.', ',');

    % Verifica se já existe um arquivo CSV com candidatos
    if exist("CONSULTA.csv")
        CANDtab_old = csv2cell("CONSULTA.csv", ';');
        CANDold = CANDtab_old(:, 1);

        % Atualiza dados com base no arquivo existente
        if length(CAND) >= length(CANDold)
            [OK, OK2] = ismember(CANDold, CAND);
            CANDtable(OK2(OK2>0), 1:6) = CANDtab_old(OK, 1:6);
        else
            [OK, OK2] = ismember(CAND, CANDold);
            CANDtable(OK, 1:6) = CANDtab_old(OK2((OK2 > 0)), 1:6);
        end
    end
end

%% ORDENANDO RESULTADOS E CALCULANDO LLR
[~, I] = sort(Pp .* LL', 'descend'); % Ordena com base na probabilidade
LL = LL(I);
LL=LL(:);
Or = Or(I,:);
Pp = Pp(I);
Pp=Pp(:);
CAND = CAND(I, :);

if size(CAND, 1) > 1
    CANDtable = CANDtable(I, :);
end

% Calcula LLR se houver suspeito
if exist("SUSP")
    sus = find(sum(CAND(:, 1:7) == SUSP, 2) == 7);
    lgc=ones(length(LL),1);
    lgc(sus)=2;
    if size(CANDtable{sus, 3}, 1) > 0
        for k = [3 4 6]
            lgc = lgc.*strncmp(CANDtable(:, k), CANDtable{sus, k}, 3);
        end
     end
        simlt=lgc;
        lgc = logical(lgc)+pt.*pm.*pc.*strncmp(CANDtable(:, 3), "", 1);
        [~, I] = sort(Pp.*LL+simlt, 'descend');
        LL = LL(I);
        Or = Or(I, :);
        Pp = Pp(I);
        CAND = CAND(I, :);
        lgc=lgc(I);
        if size(CAND, 1) > 1
            CANDtable = CANDtable(I, :);
        end
        sus = find(sum(CAND(:, 1:7) == SUSP, 2) == 7);
    if qst==1
    pLL = Pp .* LL .* lgc;
    LLR = log10(LL(sus) / (sum(pLL)));
    ["LOG(", num2str(LL(sus) * 100, 3), "%/", num2str(sum(pLL) * 100, 3), "%) = ", num2str(LLR, 3)]
    end
end

%% SALVANDO AS COMBINAÇÕES EM CSV
if size(CAND, 1) > 1 && qst==2
[A,B]=ismember(CAND,mat2cell(CANDC(:,:), ones(1, size(CANDC(:,:), 1)), 7));
 CANDtable(:, 7) = mat2cell(num2str(LLC(B) * 100, 3), ones(1, size(CAND, 1)), size(num2str(LLC(B) * 100, 3), 2));
 CANDtable(:, 7) = strrep(CANDtable(:, 7), '.', ',');
    % Salvar tabela como CSV
cell2csv("CONSULTA.csv",CANDtable,";")
end
end

