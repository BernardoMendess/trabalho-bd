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
    FROM matches m
    JOIN eventos e ON m.evento_id = e.evento_id
    JOIN times t1 ON m.team1_id = t1.time_id
    JOIN times t2 ON m.team2_id = t2.time_id
    WHERE (evento_nome IS NULL OR e.nome_evento = evento_nome)
      AND (
            time_escolhido IS NULL 
         OR t1.nome_time = time_escolhido 
         OR t2.nome_time = time_escolhido
      );

    IF total_partidas = 0 THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        CONCAT(GREATEST(m.team1_result, m.team2_result), 'x', LEAST(m.team1_result, m.team2_result)) AS placar,
        COUNT(*) AS quantidade,
        ROUND(COUNT(*) * 100.0 / total_partidas, 2) AS percentual,

        CASE
            WHEN time_escolhido IS NOT NULL THEN
                SUM(
                    CASE
                        WHEN (t1.nome_time = time_escolhido AND m.team1_result > m.team2_result)
                          OR (t2.nome_time = time_escolhido AND m.team2_result > m.team1_result)
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
                            WHEN (t1.nome_time = time_escolhido AND m.team1_result > m.team2_result)
                              OR (t2.nome_time = time_escolhido AND m.team2_result > m.team1_result)
                            THEN 1 ELSE 0
                        END
                    ) * 100.0 / COUNT(*), 2
                )
            ELSE NULL
        END AS percentual_vitorias_time

    FROM matches m
    JOIN eventos e ON m.evento_id = e.evento_id
    JOIN times t1 ON m.team1_id = t1.time_id
    JOIN times t2 ON m.team2_id = t2.time_id
    WHERE (evento_nome IS NULL OR e.nome_evento = evento_nome)
      AND (
            time_escolhido IS NULL 
         OR t1.nome_time = time_escolhido 
         OR t2.nome_time = time_escolhido
      )
    GROUP BY 
        GREATEST(m.team1_result, m.team2_result), 
        LEAST(m.team1_result, m.team2_result)
    ORDER BY quantidade DESC;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM gerar_distribuicao_resultados('ESL Pro League S19', 'Vitality');

DROP FUNCTION gerar_distribuicao_resultados;
