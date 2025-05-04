DROP FUNCTION analisar_confrontos;

CREATE OR REPLACE FUNCTION analisar_confrontos(
    time_a TEXT,
    time_b TEXT,
    mapa TEXT DEFAULT NULL
)
RETURNS TABLE (
    mapa_considerado TEXT,
    total_partidas INTEGER,
    vitorias_time_a INTEGER,
    vitorias_time_b INTEGER,
    data_hora_ultimo_confronto TEXT,
    vencedor_ultima_match TEXT
)
AS $$
DECLARE
    partidas RECORD;
    partidas_array INT[];
    total_partidas INT := 0;
    cont_vitorias_a INT := 0; 
    cont_vitorias_b INT := 0;
    ultima_match RECORD;
    data_hora_ultima_match TEXT;
BEGIN
    SELECT array_agg(m.match_id)
    INTO partidas_array
    FROM matches AS m
    INNER JOIN times AS t1 ON t1.time_id = m.team1_id
    INNER JOIN times AS t2 ON t2.time_id = m.team2_id
    WHERE (
        (t1.nome_time = time_a AND t2.nome_time = time_b) OR
        (t1.nome_time = time_b AND t2.nome_time = time_a)
    )
    AND (m.maps = mapa OR mapa IS NULL);

    IF partidas_array IS NULL THEN
        RETURN QUERY SELECT COALESCE(mapa, 'Todos'), 0, 0, 0, 'Não há', 'Não há';
        RETURN;
    END IF;

    total_partidas := cardinality(partidas_array);

    FOR i IN 1..total_partidas LOOP
        SELECT m.*, t1.nome_time AS team1_name, t2.nome_time AS team2_name
        INTO partidas
        FROM matches AS m
        JOIN times AS t1 ON t1.time_id = m.team1_id
        JOIN times AS t2 ON t2.time_id = m.team2_id
        WHERE m.match_id = partidas_array[i];

        IF (partidas.team1_name = time_a AND partidas.team1_result > partidas.team2_result) OR
           (partidas.team2_name = time_a AND partidas.team2_result > partidas.team1_result) THEN
            cont_vitorias_a := cont_vitorias_a + 1;
        ELSE
            cont_vitorias_b := cont_vitorias_b + 1;
        END IF;
    END LOOP;

    SELECT m.*, t1.nome_time AS team1_name, t2.nome_time AS team2_name
    INTO ultima_match
    FROM matches m
    INNER JOIN times AS t1 ON t1.time_id = m.team1_id
    INNER JOIN times AS t2 ON t2.time_id = m.team2_id
    WHERE m.match_id = ANY (partidas_array)
    ORDER BY m.match_time DESC
    LIMIT 1;

    IF ultima_match.team1_result > ultima_match.team2_result THEN
        vencedor_ultima_match := ultima_match.team1_name;
    ELSE
        vencedor_ultima_match := ultima_match.team2_name;
    END IF;

    data_hora_ultima_match := TO_CHAR(ultima_match.match_time, 'DD/MM/YYYY HH24:MI');

    RETURN QUERY SELECT 
        COALESCE(mapa, 'Todos'),
        total_partidas,
        cont_vitorias_a,
        cont_vitorias_b,
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
