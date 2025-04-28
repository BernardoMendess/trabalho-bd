CREATE OR REPLACE FUNCTION ranking_evento(
    evento_nome VARCHAR,
    inicio_ranking INT DEFAULT 1,
    fim_ranking INT DEFAULT 10
)
RETURNS TABLE (
    posicao_resultado BIGINT,
    time_resultado VARCHAR,
    pontos_resultado BIGINT,
    vitorias_resultado BIGINT,
    derrotas_resultado BIGINT,
    media_rounds_resultado NUMERIC,
    rounds_ganhos_resultado BIGINT,
    rounds_perdidos_resultado BIGINT
) AS $$
DECLARE
    total_matches INT;
    rec RECORD;
    ranking BIGINT := 0;
BEGIN
    CREATE TEMP TABLE temp_resultados (
        time_nome VARCHAR,
        vitorias BIGINT,
        derrotas BIGINT,
        media_rounds NUMERIC,
        pontos BIGINT,
        rounds_ganhos BIGINT,
        rounds_perdidos BIGINT
    ) ON COMMIT DROP;

    INSERT INTO temp_resultados (time_nome, vitorias, derrotas, media_rounds, pontos, rounds_ganhos, rounds_perdidos)
    SELECT 
        time_nome,
        COUNT(*) FILTER (WHERE resultado > resultado_oponente) AS vitorias,
        COUNT(*) FILTER (WHERE resultado < resultado_oponente) AS derrotas,
        ROUND(AVG(resultado + resultado_oponente), 2) AS media_rounds,
        COUNT(*) FILTER (WHERE resultado > resultado_oponente) * 3 AS pontos,
        SUM(resultado) AS rounds_ganhos,
        SUM(resultado_oponente) AS rounds_perdidos
    FROM (
        SELECT team1_name AS time_nome, team1_result AS resultado, team2_result AS resultado_oponente
        FROM matches
        WHERE event_name = evento_nome
        UNION ALL
        SELECT team2_name AS time_nome, team2_result AS resultado, team1_result AS resultado_oponente
        FROM matches
        WHERE event_name = evento_nome
    ) subquery
    GROUP BY time_nome;

    FOR rec IN
        SELECT * FROM temp_resultados
        ORDER BY pontos DESC, vitorias DESC, media_rounds DESC, time_nome
    LOOP
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