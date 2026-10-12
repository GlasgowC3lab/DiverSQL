WITH joined AS (
    SELECT
        d.d_year,
        p.p_promo_name,
        p.p_discount_active,
        cc.cc_state,
        ib.ib_upper_bound,
        cs.cs_net_profit,
        ws.ws_net_profit,
        sr.sr_net_loss,
        wr.wr_net_loss
    FROM call_center cc
    JOIN date_dim d
        ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_sales cs
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
        AND cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_reason_sk = r.r_reason_sk
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
        AND (wr.wr_refunded_hdemo_sk = hd.hd_demo_sk OR wr.wr_returning_hdemo_sk = hd.hd_demo_sk)
),
agg1 AS (
    SELECT
        d_year,
        p_promo_name,
        SUM(cs_net_profit + ws_net_profit - sr_net_loss - wr_net_loss) AS total_net
    FROM joined
    WHERE d_year = 2001
      AND p_discount_active = 'Y'
      AND cc_state = 'CA'
      AND ib_upper_bound > 50000
    GROUP BY d_year, p_promo_name
),
agg2 AS (
    SELECT
        d_year,
        p_promo_name,
        SUM(cs_net_profit + ws_net_profit - sr_net_loss - wr_net_loss) AS total_net
    FROM joined
    WHERE d_year = 2002
      AND p_discount_active = 'Y'
      AND cc_state = 'CA'
      AND ib_upper_bound > 50000
    GROUP BY d_year, p_promo_name
)
SELECT
    u.year,
    u.promo_name,
    AVG(u.total_net) AS avg_total_net
FROM (
    SELECT d_year AS year, p_promo_name AS promo_name, total_net FROM agg1
    UNION
    SELECT d_year AS year, p_promo_name AS promo_name, total_net FROM agg2
) u
GROUP BY u.year, u.promo_name
ORDER BY avg_total_net DESC
LIMIT 100
