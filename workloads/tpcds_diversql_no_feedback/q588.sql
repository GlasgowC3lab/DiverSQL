WITH per_store_hour AS (
    SELECT
        s.s_store_sk AS store_sk,
        s.s_store_name AS store_name,
        s.s_state AS state,
        t.t_hour AS hour,
        SUM(ss.ss_net_paid) AS sum_net_paid,
        SUM(ss.ss_net_profit) AS sum_net_profit,
        COUNT(*) AS sales_cnt,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS sum_return_amount,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS sum_web_net_paid,
        COUNT(DISTINCT p.p_promo_id) AS promo_cnt
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_response_target = 1
      AND p.p_channel_dmail = 'Y'
      AND s.s_state = 'CA'
      AND (r.r_reason_desc = 'Customer Not Satisfied' OR r.r_reason_desc IS NULL)
      AND (cr.cr_store_credit > 100 OR cr.cr_store_credit IS NULL)
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state, t.t_hour
)
SELECT
    store_sk,
    store_name,
    state,
    hour,
    sum_net_paid,
    sum_net_profit,
    sales_cnt,
    sum_return_amount,
    sum_web_net_paid,
    promo_cnt,
    (sum_net_paid - sum_return_amount) AS net_after_returns
FROM per_store_hour
WHERE sum_net_paid > (
    SELECT avg(p_cost)
    FROM promotion
    WHERE p_response_target = 1
)
ORDER BY net_after_returns DESC, sum_net_paid DESC
LIMIT 100
