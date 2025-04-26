CREATE OR REPLACE FUNCTION generate_event_ranking(
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
BEGIN
    RETURN QUERY
    WITH partidas AS (
        SELECT match_id, event_name, team1_name AS time_nome, team1_result AS resultado, team2_result AS resultado_oponente
        FROM matches
        WHERE event_name = evento_nome
        UNION ALL
        SELECT match_id, event_name, team2_name AS time_nome, team2_result AS resultado, team1_result AS resultado_oponente
        FROM matches
        WHERE event_name = evento_nome
    ),
    resultados AS (
    SELECT 
        time_nome,
        COUNT(*) FILTER (WHERE resultado > resultado_oponente) AS vitorias,
        COUNT(*) FILTER (WHERE resultado < resultado_oponente) AS derrotas,
        ROUND(AVG(resultado + resultado_oponente), 2) AS media_rounds,
	COUNT(*) FILTER (WHERE resultado > resultado_oponente) * 3 AS pontos,
	SUM(resultado) AS rounds_ganhos,
	SUM(resultado_oponente) AS rounds_perdidos
        FROM partidas
        GROUP BY time_nome
    ),
    classificacao AS (
        SELECT 
	    RANK() OVER (ORDER BY pontos DESC, vitorias DESC, media_rounds DESC, time_nome) AS posicao,
            time_nome,
            pontos,
            vitorias,
            derrotas,
            media_rounds,
	    rounds_ganhos,
	    rounds_perdidos
        FROM resultados
    )
    SELECT 
        c.posicao,
        c.time_nome,
        c.pontos,
        c.vitorias,
        c.derrotas,
        c.media_rounds,
	c.rounds_ganhos,
	c.rounds_perdidos
    FROM classificacao c
    WHERE c.posicao BETWEEN inicio_ranking AND fim_ranking
    ORDER BY c.posicao;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM generate_event_ranking('Blast World Final 2025');
