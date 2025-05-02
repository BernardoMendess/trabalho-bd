CREATE TYPE resultado_type AS (
    time_nome VARCHAR,
    vitorias BIGINT,
    derrotas BIGINT,
    media_rounds NUMERIC,
    pontos BIGINT,
    rounds_ganhos BIGINT,
    rounds_perdidos BIGINT
);

CREATE OR REPLACE FUNCTION ranking_evento(
    evento_nome VARCHAR,
    inicio_ranking INT DEFAULT 1,
    fim_ranking INT DEFAULT 10
)
RETURNS TABLE (
    posicao_resultado INT,
    time_resultado VARCHAR,
    pontos_resultado BIGINT,
    vitorias_resultado BIGINT,
    derrotas_resultado BIGINT,
    media_rounds_resultado NUMERIC,
    rounds_ganhos_resultado BIGINT,
    rounds_perdidos_resultado BIGINT
) AS $$
DECLARE
    resultados resultado_type[];
    rec resultado_type;
    ranking INT := 0;
BEGIN
    SELECT ARRAY_AGG(r ORDER BY r.pontos DESC, r.vitorias DESC, r.rounds_ganhos DESC, r.rounds_perdidos ASC) INTO resultados
    FROM (
        SELECT 
            t.nome_time AS time_nome,
            COUNT(*) FILTER (WHERE m1.resultado > m1.resultado_oponente) AS vitorias,
            COUNT(*) FILTER (WHERE m1.resultado < m1.resultado_oponente) AS derrotas,
            ROUND(AVG(m1.resultado + m1.resultado_oponente), 2) AS media_rounds,
            COUNT(*) FILTER (WHERE m1.resultado > m1.resultado_oponente) * 3 AS pontos,
            SUM(m1.resultado) AS rounds_ganhos,
            SUM(m1.resultado_oponente) AS rounds_perdidos
        FROM (
            SELECT m.match_id, m.team1_id AS time_id, m.team1_result AS resultado, m.team2_result AS resultado_oponente
            FROM matches m
            JOIN eventos e ON m.evento_id = e.evento_id
            WHERE e.nome_evento = evento_nome

            UNION ALL

            SELECT m.match_id, m.team2_id AS time_id, m.team2_result AS resultado, m.team1_result AS resultado_oponente
            FROM matches m
            JOIN eventos e ON m.evento_id = e.evento_id
            WHERE e.nome_evento = evento_nome
        ) m1
        JOIN times t ON m1.time_id = t.time_id
        GROUP BY t.nome_time
    ) r;

    FOREACH rec IN ARRAY resultados LOOP
        ranking := ranking + 1;
        IF ranking BETWEEN inicio_ranking AND fim_ranking THEN
            posicao_resultado := ranking;
            time_resultado := rec.time_nome;
            pontos_resultado := rec.pontos;
            vitorias_resultado := rec.vitorias;
            derrotas_resultado := rec.derrotas;
            media_rounds_resultado := rec.media_rounds;
            rounds_ganhos_resultado := rec.rounds_ganhos;
            rounds_perdidos_resultado := rec.rounds_perdidos;

            RETURN NEXT;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM ranking_evento('Blast World Final 2025', 1, 10);

DROP FUNCTION ranking_evento;
