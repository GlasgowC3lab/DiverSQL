WITH sales_agg AS (
    SELECT
        s.s_store_id,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_count,
        CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    WHERE sm.sm_carrier = 'UPS'
      AND sm.sm_contract = 'OrDuVy2H'
      AND hd.hd_dep_count >= 5
      AND ib.ib_lower_bound >= 30000
    GROUP BY s.s_store_id
),
store_ids AS (
    SELECT s_store_id FROM store WHERE s_state = 'CA'
    INTERSECT
    SELECT s_store_id FROM store WHERE s_city = 'Los Angeles'
)
SELECT
    sa.s_store_id,
    sa.total_profit,
    sa.sales_count,
    sa.profit_category
FROM sales_agg sa
JOIN store_ids si ON sa.s_store_id = si.s_store_id
ORDER BY sa.total_profit DESC
LIMIT 100
