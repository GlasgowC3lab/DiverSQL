WITH agg_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_returned_date_sk,
        COUNT(*) AS returns_cnt,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2451545 AND 2451910
      AND sr.sr_return_quantity > 0
    GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    p.p_promo_name,
    td.t_hour,
    td.t_sub_shift,
    COALESCE(ss.ss_sales_price, 0) AS sales_price,
    COALESCE(ar.returns_cnt, 0) AS returns_cnt,
    CASE
        WHEN COALESCE(ss.ss_sales_price, 0) > 50 THEN 'High'
        WHEN COALESCE(ss.ss_sales_price, 0) > 20 THEN 'Medium'
        ELSE 'Low'
    END AS price_category,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY COALESCE(ss.ss_sales_price, 0) DESC) AS sales_rank
FROM store_sales ss
FULL OUTER JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_item_sk = sr.sr_item_sk
   AND ss.ss_store_sk = sr.sr_store_sk
LEFT JOIN agg_returns ar
    ON ar.sr_store_sk = COALESCE(ss.ss_store_sk, sr.sr_store_sk)
   AND ar.sr_returned_date_sk = COALESCE(ss.ss_sold_date_sk, sr.sr_returned_date_sk)
LEFT JOIN store s
    ON s.s_store_sk = COALESCE(ss.ss_store_sk, sr.sr_store_sk)
LEFT JOIN promotion p
    ON p.p_promo_sk = ss.ss_promo_sk
LEFT JOIN time_dim td
    ON td.t_time_sk = COALESCE(ss.ss_sold_time_sk, sr.sr_return_time_sk)
LEFT JOIN web_sales ws
    ON ws.ws_sold_time_sk = td.t_time_sk
WHERE
    s.s_manager IN ('Brian Norris', 'Matt Frederick')
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND td.t_sub_shift = 'morning'
    AND (COALESCE(ss.ss_sales_price, 0) > 0 OR COALESCE(ar.returns_cnt, 0) > 0)
ORDER BY sales_rank
LIMIT 100
