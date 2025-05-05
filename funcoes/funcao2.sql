DROP FUNCTION analisar_confrontos;

CREATE OR REPLACE FUNCTION analisar_confrontos(
    time_a TEXT,
    time_b TEXT,
    mapa TEXT DEFAULT NULL
)
RETURNS TABLE (
    mapa_considerado TEXT,
    total_matches INTEGER,
    vitorias_time_a INTEGER,
    vitorias_time_b INTEGER,
    vencedor_ultima_match TEXT,
    data_hora_ultima_match TEXT
)
AS $$
DECLARE
    partida RECORD;
    ultima_partida RECORD;
    cont_vitorias_a INT := 0;
    cont_vitorias_b INT := 0;
    total_partidas INT := 0;
    vencedor_ultima_partida TEXT;
	data_hora_ultima_partida TEXT;
BEGIN
    FOR partida IN
        SELECT 
            m.*,
            t1.nome_time AS team1_name,
            t2.nome_time AS team2_name
        FROM matches m
        INNER JOIN times t1 ON t1.time_id = m.team1_id
        INNER JOIN times t2 ON t2.time_id = m.team2_id
        WHERE (
            (t1.nome_time = time_a AND t2.nome_time = time_b) OR
            (t1.nome_time = time_b AND t2.nome_time = time_a)
        )
        AND (m.maps = mapa OR mapa IS NULL)
        ORDER BY m.match_time DESC
    LOOP
        total_partidas := total_partidas + 1;

        IF total_partidas = 1 THEN
            ultima_partida := partida;
        END IF;

        IF (partida.team1_name = time_a AND partida.team1_result > partida.team2_result) OR
           (partida.team2_name = time_a AND partida.team2_result > partida.team1_result) THEN
            cont_vitorias_a := cont_vitorias_a + 1;
        ELSE
            cont_vitorias_b := cont_vitorias_b + 1;
        END IF;
    END LOOP;

    IF total_partidas = 0 THEN
        RETURN QUERY SELECT COALESCE(mapa, 'Todos'), 0, 0, 0, 'Não há', 'Nula';
    ELSE
	data_hora_ultima_partida := TO_CHAR(ultima_partida.match_time, 'DD/MM/YYYY HH24:MI');

	IF ultima_partida.team1_result > ultima_partida.team2_result THEN
		vencedor_ultima_partida := ultima_partida.team1_name::TEXT;    
	ELSE
		vencedor_ultima_partida := ultima_partida.team2_name::TEXT;   
	END IF;
        RETURN QUERY SELECT
            COALESCE(mapa, 'Todos'),
            total_partidas,
            cont_vitorias_a,
            cont_vitorias_b,
	    vencedor_ultima_partida,
            data_hora_ultima_partida;
    END IF;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM analisar_confrontos('Faze Clan', 'NaVi');
SELECT * FROM analisar_confrontos('Faze Clan', 'NaVi', 'Mirage');
SELECT * FROM analisar_confrontos('Faze Clan', 'NaVi', 'Não Sei Onde');

SELECT * FROM analisar_confrontos('Cloud9', 'Furia');
SELECT * FROM analisar_confrontos('Cloud9', 'Furia', 'Cache');

SELECT * FROM analisar_confrontos('MIBR', 'NaVi');
SELECT * FROM analisar_confrontos('MIBR', 'NaVi', 'Mirage');
