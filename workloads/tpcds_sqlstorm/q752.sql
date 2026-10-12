WITH item_desc_tokens AS (
    SELECT
        cs.cs_call_center_sk,
        d.d_year,
        token,
        COUNT(*) AS token_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    CROSS JOIN UNNEST(split(regexp_replace(lower(i.i_item_desc), '[^a-z0-9 ]', ''), ' ')) AS t(token)
    WHERE d.d_year = 2001 AND token <> ''
    GROUP BY cs.cs_call_center_sk, d.d_year, token
),
call_center_str AS (
    SELECT
        cc.cc_call_center_sk,
        upper(regexp_replace(cc.cc_name, '[^A-Za-z0-9]', '')) AS clean_name,
        concat_ws('_', lower(cc.cc_city), lower(cc.cc_state)) AS city_state,
        reverse(cc.cc_manager) AS rev_manager,
        length(replace(cc.cc_hours, ':', '')) AS hours_len,
        regexp_extract(cc.cc_hours, '([0-9]{2}:[0-9]{2})', 1) AS first_time,
        replace(cc.cc_hours, ':', '') AS hours_nocolon,
        substr(cc.cc_hours, 1, 5) AS first_five_chars
    FROM call_center cc
    WHERE cc.cc_rec_end_date >= DATE '2000-01-01'
),
call_center_aggregated AS (
    SELECT
        ccs.cc_call_center_sk,
        ccs.clean_name,
        ccs.city_state,
        ccs.rev_manager,
        ccs.hours_len,
        ccs.first_time,
        ccs.hours_nocolon,
        ccs.first_five_chars,
        SUM(cs.cs_net_paid) AS total_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_count
    FROM catalog_sales cs
    JOIN call_center_str ccs ON cs.cs_call_center_sk = ccs.cc_call_center_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY ccs.cc_call_center_sk, ccs.clean_name, ccs.city_state,
        ccs.rev_manager, ccs.hours_len, ccs.first_time,
        ccs.hours_nocolon, ccs.first_five_chars
)
SELECT
    cca.cc_call_center_sk,
    cca.clean_name,
    cca.city_state,
    cca.rev_manager,
    cca.hours_len,
    cca.first_time,
    cca.hours_nocolon,
    cca.first_five_chars,
    cca.total_paid,
    cca.total_profit,
    cca.sales_count,
    it.token,
    it.token_cnt,
    length(cca.clean_name) AS clean_name_len,
    lower(cca.rev_manager) AS rev_manager_lower,
    concat(cca.city_state, '-', cca.first_time) AS composite_key,
    format('%s-%s', cca.clean_name, it.token) AS formatted_string
FROM call_center_aggregated cca
LEFT JOIN item_desc_tokens it
    ON it.cs_call_center_sk = cca.cc_call_center_sk
WHERE it.token_cnt > 100
ORDER BY cca.total_profit DESC
LIMIT 50
