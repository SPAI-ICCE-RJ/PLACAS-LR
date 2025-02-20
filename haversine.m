function distance = haversine(lat1, lon1, lat2, lon2)
  % haversine: Calcula a distância entre dois pontos na Terra
  %
  % Parâmetros:
  % lat1, lon1 - Latitude e longitude do primeiro ponto (em graus)
  % lat2, lon2 - Latitude e longitude do segundo ponto (em graus)
  %
  % Retorno:
  % distance - Distância em quilômetros entre os dois pontos

  % Raio médio da Terra (em km)
  R = 6371;

  % Converter graus para radianos
  lat1 = deg2rad(lat1/1000000);
  lon1 = deg2rad(lon1/1000000);
  lat2 = deg2rad(lat2/1000000);
  lon2 = deg2rad(lon2/1000000);

  % Diferenças das coordenadas
  dlat = lat2 - lat1;
  dlon = lon2 - lon1;

  % Fórmula do haversine
  a = sin(dlat / 2).^2 + cos(lat1).*cos(lat2).*sin(dlon / 2).^2;
  c = 2 * atan2(sqrt(a), sqrt(1 - a));

  % Calcular a distância
  distance = R * c;
end
