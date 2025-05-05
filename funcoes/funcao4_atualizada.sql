CREATE OR REPLACE FUNCTION momentum_time(
    time_escolhido TEXT,
    data_param DATE,
    semana_param INTEGER,
    mes_param INTEGER,
    primeiro_intervalo DATE,
    segundo_intervalo DATE
)
RETURNS TABLE(
    time_saida TEXT,
    param_data_saida DATE,
    taxa_num NUMERIC,
    seq_max_vit INTEGER,
    seq_max_derrotas INTEGER,
    ini_data_periodo_saida DATE,
    fim_data_periodo_saida DATE,
    aproveitamento_primeiro INTEGER,
    aproveitamento_segundo INTEGER,
    diferenca_porcentual INTEGER
) AS $$
DECLARE
    seq_max_vit INTEGER := 0;
    seq_max_derrotas INTEGER := 0;
    aux_seq_max INTEGER := 0;
    aux_seq_max_derrota INTEGER := 0;
    num_vitorias INTEGER := 0;
    num_vitorias_primeiro INTEGER := 0;
    num_vitorias_segundo INTEGER := 0;
    temporario DATE;

    num_total_aux INTEGER := 0;
    num_jogos_primeiro INTEGER := 0;
    num_jogos_segundo INTEGER := 0;
    jogo_aux RECORD;
    taxa_num NUMERIC;
    aproveitamento_primeiro INTEGER;
    aproveitamento_segundo INTEGER;
    diferenca_porcentual INTEGER;

BEGIN
    DROP TABLE IF EXISTS aux_table;
    
    
    CREATE TEMP TABLE aux_table AS
        SELECT 
            m.*,
            t1.nome_time AS team1_name,--msm coisa q a func antiga, so muda isso para pegar os nomes q agr estão na outra tab
            t2.nome_time AS team2_name
        FROM matches m
        JOIN times t1 ON m.team1_id = t1.time_id--aqui pega baseado no id de cada que so tem na tab de matches
        JOIN times t2 ON m.team2_id = t2.time_id
        WHERE (t1.nome_time = time_escolhido OR t2.nome_time = time_escolhido)
          AND m.match_time >= data_param::TIMESTAMP
          AND m.match_time <= data_param::TIMESTAMP + ((semana_param * 7) + (mes_param * 30) || ' days')::INTERVAL
        ORDER BY m.match_time;

    
    FOR jogo_aux IN SELECT * FROM aux_table
    LOOP
        num_total_aux := num_total_aux + 1;

        
        IF (jogo_aux.team1_name = time_escolhido AND jogo_aux.team1_result = 16 AND jogo_aux.team1_result > jogo_aux.team2_result) OR
           (jogo_aux.team2_name = time_escolhido AND jogo_aux.team2_result = 16 AND jogo_aux.team2_result > jogo_aux.team1_result) THEN
            aux_seq_max := aux_seq_max + 1;
            aux_seq_max_derrota := 0;
            num_vitorias := num_vitorias + 1;
        ELSE
            aux_seq_max_derrota := aux_seq_max_derrota + 1;
            aux_seq_max := 0;
        END IF;

        seq_max_vit := GREATEST(seq_max_vit, aux_seq_max);--greatest me salvou 14 linhas
        seq_max_derrotas := GREATEST(seq_max_derrotas, aux_seq_max_derrota);

        IF primeiro_intervalo > segundo_intervalo THEN
            temporario := primeiro_intervalo;
            primeiro_intervalo := segundo_intervalo;
            segundo_intervalo := temporario;
        END IF;

        IF jogo_aux.match_time::DATE <= primeiro_intervalo THEN
            num_jogos_primeiro := num_jogos_primeiro + 1;
            IF (jogo_aux.team1_name = time_escolhido AND jogo_aux.team1_result = 16 AND jogo_aux.team1_result > jogo_aux.team2_result) OR
               (jogo_aux.team2_name = time_escolhido AND jogo_aux.team2_result = 16 AND jogo_aux.team2_result > jogo_aux.team1_result) THEN
                num_vitorias_primeiro := num_vitorias_primeiro + 1;
            END IF;
        END IF;

        IF jogo_aux.match_time::DATE > primeiro_intervalo AND jogo_aux.match_time::DATE <= segundo_intervalo THEN
            num_jogos_segundo := num_jogos_segundo + 1;
            IF (jogo_aux.team1_name = time_escolhido AND jogo_aux.team1_result = 16 AND jogo_aux.team1_result > jogo_aux.team2_result) OR
               (jogo_aux.team2_name = time_escolhido AND jogo_aux.team2_result = 16 AND jogo_aux.team2_result > jogo_aux.team1_result) THEN
                num_vitorias_segundo := num_vitorias_segundo + 1;
            END IF;
        END IF;
    END LOOP;

    IF num_total_aux > 0 THEN
        taxa_num := ROUND((num_vitorias::NUMERIC / num_total_aux::NUMERIC) * 100, 2);
    ELSE
        taxa_num := 0;
    END IF;

    IF num_jogos_primeiro > 0 THEN
        aproveitamento_primeiro := ROUND((num_vitorias_primeiro::NUMERIC / num_jogos_primeiro::NUMERIC) * 100, 2);
    ELSE
        aproveitamento_primeiro := 0;
    END IF;

    IF num_jogos_segundo > 0 THEN
        aproveitamento_segundo := ROUND((num_vitorias_segundo::NUMERIC / num_jogos_segundo::NUMERIC) * 100, 2);
    ELSE
        aproveitamento_segundo := 0;
    END IF;

    diferenca_porcentual := aproveitamento_segundo - aproveitamento_primeiro;

    RETURN QUERY
    SELECT
        time_escolhido,
        data_param,
        taxa_num,
        seq_max_vit,
        seq_max_derrotas,
        primeiro_intervalo,
        segundo_intervalo,
        aproveitamento_primeiro,
        aproveitamento_segundo,
        diferenca_porcentual;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM momentum_time('G2 Esports','2024-08-22',10,6,'2025-08-26','2025-01-22')

DROP FUNCTION momentum_time;

SELECT * FROM matches
