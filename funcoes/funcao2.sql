CREATE TABLE IF NOT EXISTS matches (
    match_id BIGINT PRIMARY KEY,
    event_name VARCHAR(255),
    maps VARCHAR(10),
    match_time TIMESTAMP,
    team1_name VARCHAR(100),
    team1_result INT,
    team2_name VARCHAR(100),
    team2_result INT
);

CREATE OR REPLACE FUNCTION analisar_confrontos(
    time_a TEXT,
    time_b TEXT,
    mapa_especifico TEXT DEFAULT NULL -- Quando é nulo, todos os mapas são considerados
)
RETURNS TABLE (
    mapa_considerado TEXT,
    total_partidas INTEGER,
    vitorias_time_a INTEGER,
    vitorias_time_b INTEGER,
    percentual_vitorias_time_a NUMERIC(5,2),
    percentual_vitorias_time_b NUMERIC(5,2),
    data_hora_ultimo_confronto TEXT,
    vencedor_ultima_match TEXT
)
AS $$
DECLARE
    partidas RECORD;
    partidas_array BIGINT[];
    total_partidas INT := 0;
    cont_vitorias_a INT := 0; 
    cont_vitorias_b INT := 0;
    ultima_match RECORD;
	percentual_vitorias_a NUMERIC;
	percentual_vitorias_b NUMERIC;
	data_hora_ultima_match TEXT;
BEGIN
    SELECT array_agg(match_id)
    INTO partidas_array
    FROM matches
    WHERE
        (mapa_especifico IS NULL OR maps = mapa_especifico)
	 AND
	 (
             (team1_name = time_a AND team2_name = time_b)
             OR
             (team1_name = time_b AND team2_name = time_a)
        );

    IF partidas_array IS NULL THEN
        RETURN QUERY SELECT COALESCE(mapa_especifico, 'Todos'), 0, 0, 0, 0.00, 0.00, 'Não há', 'Não há';
        RETURN;
    END IF;

    total_partidas := cardinality(partidas_array);

    -- Verifica quem ganhou cada uma das matches
    FOR i IN 1..total_partidas LOOP
        SELECT * INTO partidas FROM matches WHERE match_id = partidas_array[i];

        IF partidas.team1_name = time_a AND partidas.team1_result > partidas.team2_result THEN
            cont_vitorias_a := cont_vitorias_a + 1;
        ELSIF partidas.team2_name = time_a AND partidas.team2_result > partidas.team1_result THEN
            cont_vitorias_a := cont_vitorias_a + 1;
        ELSIF partidas.team1_name = time_b AND partidas.team1_result > partidas.team2_result THEN
            cont_vitorias_b := cont_vitorias_b + 1;
        ELSIF partidas.team2_name = time_b AND partidas.team2_result > partidas.team1_result THEN
            cont_vitorias_b := cont_vitorias_b + 1;
        END IF;
    END LOOP;

    -- Achar última match
    SELECT *
    INTO ultima_match
    FROM matches
    WHERE match_id = ANY (partidas_array)
    ORDER BY match_time DESC
    LIMIT 1;

    IF ultima_match.team1_result > ultima_match.team2_result THEN
        vencedor_ultima_match := ultima_match.team1_name;
    ELSE
        vencedor_ultima_match := ultima_match.team2_name;
    END IF;

    percentual_vitorias_a := ROUND(
        (cont_vitorias_a::numeric / total_partidas::numeric) * 100, 2);
	
    percentual_vitorias_b := ROUND(
        (cont_vitorias_b::numeric / total_partidas::numeric) * 100, 2);

    data_hora_ultima_match := TO_CHAR(ultima_match.match_time, 'DD/MM/YYYY HH24:MI');

    RETURN QUERY SELECT 
        COALESCE(mapa_especifico, 'Todos'),
        total_partidas,
        cont_vitorias_a,
        cont_vitorias_b,
        percentual_vitorias_a,
        percentual_vitorias_b,
        data_hora_ultima_match,
        vencedor_ultima_match;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM analisar_confrontos('Faze Clan', 'NaVi');
SELECT * FROM analisar_confrontos('Faze Clan', 'NaVi', 'Mirage');
SELECT * FROM analisar_confrontos('Faze Clan', 'NaVi', 'Não Sei Onde');

SELECT * FROM analisar_confrontos('Cloud9', 'Furia');
SELECT * FROM analisar_confrontos('Cloud9', 'Furia', 'Cache');

SELECT * FROM analisar_confrontos('MIBR', 'NaVi');
SELECT * FROM analisar_confrontos('MIBR', 'NaVi', 'Mirage');
