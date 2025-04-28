CREATE OR REPLACE FUNCTION gerar_distribuicao_resultados(
    evento_nome TEXT DEFAULT NULL,
    time_escolhido TEXT DEFAULT NULL
)
RETURNS TABLE (
    placar TEXT,
    quantidade BIGINT,
    percentual NUMERIC(5,2),
    vitorias_time BIGINT,
    percentual_vitorias_time NUMERIC(5,2)
)
AS $$
DECLARE
    total_partidas INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO total_partidas
    FROM matches
    WHERE (evento_nome IS NULL OR event_name = evento_nome)
      AND (time_escolhido IS NULL OR team1_name = time_escolhido OR team2_name = time_escolhido);

    IF total_partidas = 0 THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        CONCAT(GREATEST(team1_result, team2_result), 'x', LEAST(team1_result, team2_result)) AS placar,
        COUNT(*) AS quantidade,
        ROUND((COUNT(*) * 100.0) / total_partidas, 2) AS percentual,
        
        CASE
            WHEN time_escolhido IS NOT NULL THEN
                SUM(
                    CASE
                        WHEN (team1_name = time_escolhido AND team1_result > team2_result) 
                          OR (team2_name = time_escolhido AND team2_result > team1_result)
                        THEN 1 ELSE 0
                    END
                )
            ELSE NULL
        END AS vitorias_time,

        CASE
            WHEN time_escolhido IS NOT NULL THEN
                ROUND(
                    SUM(
                        CASE
                            WHEN (team1_name = time_escolhido AND team1_result > team2_result) 
                              OR (team2_name = time_escolhido AND team2_result > team1_result)
                            THEN 1 ELSE 0
                        END
                    ) * 100.0 / COUNT(*), 2
                )
            ELSE NULL
        END AS percentual_vitorias_time

    FROM matches
    WHERE (evento_nome IS NULL OR event_name = evento_nome)
      AND (time_escolhido IS NULL OR team1_name = time_escolhido OR team2_name = time_escolhido)
    GROUP BY 
        GREATEST(team1_result, team2_result), 
        LEAST(team1_result, team2_result)
    ORDER BY quantidade DESC;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM gerar_distribuicao_resultados('ESL Pro League S19', 'Vitality');

DROP FUNCTION gerar_distribuicao_resultados;