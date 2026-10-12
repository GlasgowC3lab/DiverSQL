WITH filtered_returns AS (
    SELECT
        sr.sr_net_loss,
        d.d_year,
        i.i_category,
        i.i_brand,
        i.i_class,
        i.i_color,
        i.i_item_desc,
        i.i_formulation,
        s.s_store_name,
        s.s_state,
        r.r_reason_desc
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2000
      AND s.s_state = 'CA'
      AND i.i_formulation LIKE '%steel%'
      AND regexp_like(i.i_item_desc, '^.{3}[0-9]{2}')
)
SELECT
    s_store_name,
    i_category,
    r_reason_desc,
    SUM(sr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    MIN(CONCAT(i_brand, ' ', i_class)) AS brand_class,
    MIN(SUBSTRING(i_color, 1, 5)) AS color_prefix
FROM filtered_returns
GROUP BY CUBE (s_store_name, i_category, r_reason_desc)
ORDER BY total_net_loss DESC
LIMIT 100
