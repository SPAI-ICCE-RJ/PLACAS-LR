pkg load io % Carrega o pacote necessário para manipulação de JSON

%% INSIRA AS VARIÁVEIS DE ENTRADA
token = ""; % Insira o token para a página https://apiplacas.com.br/
marca = "FIAT"; % Defina a marca do veículo de interesse

%% CARREGANDO A TABELA DE CANDIDATOS
% Lê o arquivo de candidatos e organiza a tabela em células (linhas e colunas)
CANDtab =csv2cell("CONSULTA.csv", ';');
CAND = cell2mat(CANDtab(:, 1)); % Extrai a primeira coluna (placas)
total = length(CAND); % Total de candidatos

%% REALIZANDO A CONSULTA E ATUALIZANDO OS DADOS
quest = "Yes"; % Inicializa a variável de controle para continuidade das consultas
if exist("token", "var") && ~isempty(token) % Verifica se o token foi fornecido
    for k = 1:total
        % Verifica se os campos de marca e modelo estão vazios para a linha atual
        if isempty(CANDtab{k, 3}) && isempty(CANDtab{k, 5})
            % Realiza a consulta à API usando a URL gerada
            [response, status] = urlread(["https://wdapi2.com.br/consulta/", CAND(k, :), "/", token]);
            data = fromJSON(response); % Converte a resposta JSON em estrutura

            if status == 1 % Verifica se a consulta foi bem-sucedida
                % Atualiza os campos da tabela baseado nos dados retornados
                if ~isfield(data, 'MARCA') || isnan(data.MARCA)
                    CANDtab{k, 3} = "indefinida";
                else
                    % Atualiza os campos com os dados retornados pela API
                    CANDtab{k, 2} = data.uf;
                    CANDtab{k, 3} = toupper(data.MARCA);
                    CANDtab{k, 4} = toupper(data.MODELO);
                    CANDtab{k, 5} = data.ano;
                    CANDtab{k, 6} = toupper(data.cor);

                    % Exibe o progresso
                    fprintf('Processando placa %d: %s\nUF: %s\nMARCA: %s\nMODELO:%s\nANO: %s\nCOR: %s\n\n',...
                    k, CANDtab{k, 1},CANDtab{k, 2},CANDtab{k, 3},CANDtab{k, 4},CANDtab{k, 5},CANDtab{k, 6});

                    % Verifica se a marca corresponde à de interesse
                    if strncmp(data.MARCA, marca, length(marca))
                        % Realiza consulta de saldo na API
                        [saldoResponse, saldoStatus] = urlread(["https://wdapi2.com.br/saldo/", token]);
                        if saldoStatus
                            saldoData = fromJSON(saldoResponse);
                            consultasRestantes = num2str(saldoData.qtdConsultas); % Consultas restantes
                        else
                            consultasRestantes = "indefinido";
                        end

                        % Mostra um diálogo ao usuário com os dados consultados
                        quest = questdlg(["Placa: ", CAND(k, :), "\nMarca: ", data.MARCA, ...
                                          "\nModelo: ", data.MODELO, "\nCor: ", data.cor, ...
                                          "\nVerossimilhança: ", CANDtab{k, 7}, ...
                                          "\nConsultas restantes: ", consultasRestantes], ...
                                          "Deseja continuar?");

                        % Salva a tabela atualizada após cada consulta
                        cell2csv("CONSULTA.csv", CANDtab, ";");
                    end
                end
            else
                % Caso o status da consulta falhe, marca a linha como 'manual'
                CANDtab{k, 3} = "manual";
            end
        end

        % Encerra o loop se o usuário optar por "Não" no diálogo
        if strncmp(quest, "No", 1)
            break;
        end
    end
else
    fprintf('Token não fornecido ou inválido. Operação abortada.\n');
end

