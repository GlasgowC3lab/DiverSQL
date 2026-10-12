WITH agg AS (
    SELECT
        cc.cc_state AS state,
        cp.cp_department AS department,
        p.p_promo_name AS promo_name,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss
    FROM
        catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN web_returns wr ON hd.hd_demo_sk = wr.wr_refunded_hdemo_sk
    WHERE
        cc.cc_state IN ('TN', 'GA', 'MI')
        AND p.p_discount_active = 'Y'
        AND sm.sm_type = 'AIR'
        AND cs.cs_sold_date_sk BETWEEN 2450806 AND 2451063
    GROUP BY
        cc.cc_state,
        cp.cp_department,
        p.p_promo_name
    HAVING
        SUM(cs.cs_net_profit) > 5000
)
SELECT
    state,
    department,
    promo_name,
    total_sales_profit,
    total_return_loss,
    total_sales_profit - total_return_loss AS net_profit_after_returns,
    RANK() OVER (PARTITION BY state, department ORDER BY (total_sales_profit - total_return_loss) DESC) AS promo_rank
FROM agg
ORDER BY
    state,
    department,
    net_profit_after_returns DESC
LIMIT 50
