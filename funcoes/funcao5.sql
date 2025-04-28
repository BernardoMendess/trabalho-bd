CREATE OR REPLACE FUNCTION calc_peso_rankEcamp(data_olhada DATE, data_determinada DATE)
RETURNS TABLE(
    time_id BIGINT,
    nome_time VARCHAR(100),
    pais VARCHAR(50),
    data_fundacao DATE,
    ranking_atual BIGINT,
    pontuacao BIGINT
)
AS $$
DECLARE
    jogo_aux RECORD;
    resultado_aux RECORD;
    val_base INTEGER := 50;
    peso_bonus INTEGER := 20;
    pontuacao_ganha INTEGER := 0;
    pontuacao_perde INTEGER := 0;
    novo_ranking BIGINT := 1;
BEGIN
    DROP TABLE IF EXISTS aux_matches_r;
    CREATE TEMP TABLE aux_matches_r AS
    SELECT *
    FROM matches
    WHERE DATE(match_time) BETWEEN data_olhada AND data_determinada
    ORDER BY match_time;

    DROP TABLE IF EXISTS inn_times_jogos;
    CREATE TEMP TABLE inn_times_jogos AS
    SELECT 
        m.match_id,
        m.event_name,
        m.maps,
        m.match_time,
        t1.nome_time AS team1_name,
        t1.ranking_atual AS team1_ranking,
        m.team1_result,
        t2.nome_time AS team2_name,
        t2.ranking_atual AS team2_ranking,
        m.team2_result
    FROM aux_matches_r m
    INNER JOIN times t1 ON m.team1_name = t1.nome_time 
    INNER JOIN times t2 ON m.team2_name = t2.nome_time 
    ORDER BY m.match_time;

    DROP TABLE IF EXISTS resultado_pontuacoes;
    CREATE TEMP TABLE resultado_pontuacoes (
        nome_time_resultado VARCHAR(100),
        pais VARCHAR(50),
        data_fundacao DATE,
        ranking_atual BIGINT,
        pontuacao_resultado BIGINT
    );

    FOR jogo_aux IN SELECT * FROM inn_times_jogos
    LOOP
        pontuacao_ganha := 0;
        pontuacao_perde := 0;

        IF POSITION('IEM' IN jogo_aux.event_name) > 0 OR POSITION('Final' IN jogo_aux.event_name) > 0 THEN
            pontuacao_ganha := peso_bonus;
        END IF;

        IF jogo_aux.team1_result > jogo_aux.team2_result AND jogo_aux.team1_ranking > jogo_aux.team2_ranking THEN
            pontuacao_ganha := val_base + (jogo_aux.team1_ranking - jogo_aux.team2_ranking);
            pontuacao_perde := val_base + (jogo_aux.team2_ranking - jogo_aux.team1_ranking);
        END IF;
        
        IF jogo_aux.team2_result > jogo_aux.team1_result AND jogo_aux.team2_ranking > jogo_aux.team1_ranking THEN
            pontuacao_ganha := val_base + (jogo_aux.team2_ranking - jogo_aux.team1_ranking);
            pontuacao_perde := val_base + (jogo_aux.team1_ranking - jogo_aux.team2_ranking);
        END IF;

        IF jogo_aux.team1_result > jogo_aux.team2_result AND jogo_aux.team1_ranking < jogo_aux.team2_ranking THEN
            pontuacao_ganha := val_base;
            pontuacao_perde := val_base/2;
        END IF;
        
        IF jogo_aux.team2_result > jogo_aux.team1_result AND jogo_aux.team2_ranking < jogo_aux.team1_ranking THEN
            pontuacao_ganha := val_base;
            pontuacao_perde := val_base/2;
        END IF;

        IF EXISTS (SELECT 1 FROM resultado_pontuacoes r WHERE r.nome_time_resultado = jogo_aux.team1_name) THEN
            IF jogo_aux.team1_result > jogo_aux.team2_result THEN
                UPDATE resultado_pontuacoes r
                SET pontuacao_resultado = r.pontuacao_resultado + pontuacao_ganha
                WHERE r.nome_time_resultado = jogo_aux.team1_name;
            ELSE
                UPDATE resultado_pontuacoes r
                SET pontuacao_resultado = r.pontuacao_resultado + pontuacao_perde
                WHERE r.nome_time_resultado = jogo_aux.team1_name;
            END IF;
        ELSE
            INSERT INTO resultado_pontuacoes (nome_time_resultado, pais, data_fundacao, ranking_atual, pontuacao_resultado)
            SELECT 
                t.nome_time, t.pais, t.data_fundacao, t.ranking_atual,
                CASE WHEN jogo_aux.team1_result > jogo_aux.team2_result THEN pontuacao_ganha ELSE pontuacao_perde END
            FROM times t
            WHERE t.nome_time = jogo_aux.team1_name;
        END IF;

        IF EXISTS (SELECT 1 FROM resultado_pontuacoes r WHERE r.nome_time_resultado = jogo_aux.team2_name) THEN
            IF jogo_aux.team2_result > jogo_aux.team1_result THEN
                UPDATE resultado_pontuacoes r
                SET pontuacao_resultado = r.pontuacao_resultado + pontuacao_ganha
                WHERE r.nome_time_resultado = jogo_aux.team2_name;
            ELSE
                UPDATE resultado_pontuacoes r
                SET pontuacao_resultado = r.pontuacao_resultado + pontuacao_perde
                WHERE r.nome_time_resultado = jogo_aux.team2_name;
            END IF;
        ELSE
            INSERT INTO resultado_pontuacoes (nome_time_resultado, pais, data_fundacao, ranking_atual, pontuacao_resultado)
            SELECT 
                t.nome_time, t.pais, t.data_fundacao, t.ranking_atual,
                CASE WHEN jogo_aux.team2_result > jogo_aux.team1_result THEN pontuacao_ganha ELSE pontuacao_perde END
            FROM times t
            WHERE t.nome_time = jogo_aux.team2_name;
        END IF;

    END LOOP;

    FOR resultado_aux IN
        SELECT nome_time_resultado, pontuacao_resultado
        FROM resultado_pontuacoes
        ORDER BY pontuacao_resultado DESC
    LOOP
        UPDATE resultado_pontuacoes
        SET ranking_atual = novo_ranking
        WHERE nome_time_resultado = resultado_aux.nome_time_resultado;
        novo_ranking := novo_ranking + 1;
    END LOOP;
    
    RETURN QUERY
    SELECT ROW_NUMBER() OVER () AS time_id,
           r.nome_time_resultado, r.pais, r.data_fundacao, r.ranking_atual, r.pontuacao_resultado
    FROM resultado_pontuacoes r;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM calc_peso_rankEcamp('2025-01-10', '2025-10-14');

DROP FUNCTION calc_peso_rankEcamp