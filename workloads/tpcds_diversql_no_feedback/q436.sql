WITH filtered_promos AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_name,
        p.p_channel_details,
        substr(p.p_promo_id, 1, 3) AS promo_prefix,
        regexp_extract(p.p_promo_id, '(\\d+)', 1) AS promo_numeric_part,
        d_start.d_year AS start_year,
        d_start.d_month_seq AS start_month_seq
    FROM promotion p
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    WHERE regexp_like(p.p_promo_name, '(?i)discount|sale')
      AND p.p_channel_details LIKE '%email%'
)
SELECT
    fp.promo_prefix,
    fp.promo_numeric_part,
    concat(fp.promo_prefix, '-', fp.promo_numeric_part) AS promo_key,
    fp.p_promo_name,
    d_ret.d_year,
    d_ret.d_month_seq,
    COUNT(*) AS returns_cnt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    CASE
        WHEN SUM(wr.wr_net_loss) > (SELECT avg(wr2.wr_net_loss) FROM web_returns wr2) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS loss_category
FROM filtered_promos fp
JOIN web_sales ws
    ON ws.ws_promo_sk = fp.p_promo_sk
JOIN web_returns wr
    ON wr.wr_item_sk = ws.ws_item_sk
   AND wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year = 2002
GROUP BY
    fp.promo_prefix,
    fp.promo_numeric_part,
    fp.p_promo_name,
    d_ret.d_year,
    d_ret.d_month_seq
HAVING SUM(wr.wr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 100
