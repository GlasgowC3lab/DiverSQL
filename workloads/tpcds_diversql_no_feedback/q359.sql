WITH filtered_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_birth_year BETWEEN 1960 AND 1980
      AND c.c_preferred_cust_flag = 'Y'
      AND EXISTS (
          SELECT 1
          FROM customer_demographics cd
          WHERE cd.cd_demo_sk = c.c_current_cdemo_sk
            AND cd.cd_purchase_estimate > 5000
      )
),
agg AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        w.w_country,
        ws_site.web_name,
        cc.cc_name,
        cp.cp_description,
        sm.sm_type,
        ib.ib_upper_bound,
        ib.ib_lower_bound,
        SUM(ws.ws_net_profit)               AS total_net_profit,
        SUM(cr.cr_net_loss)                 AS total_net_loss,
        COUNT(DISTINCT c_refunded.c_customer_sk) AS distinct_refunded_customers,
        CASE WHEN ib.ib_upper_bound > 100000 THEN 'HIGH_INCOME' ELSE 'LOW_INCOME' END AS income_category
    FROM warehouse w
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer_address ca_refunded ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN income_band ib ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
    JOIN filtered_customers fc ON ws.ws_bill_customer_sk = fc.c_customer_sk
    WHERE w.w_state = 'CA'
      AND ws_site.web_state = 'CA'
      AND cd_refunded.cd_purchase_estimate > 4000
      AND cc.cc_closed_date_sk IS NULL
    GROUP BY
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        w.w_country,
        ws_site.web_name,
        cc.cc_name,
        cp.cp_description,
        sm.sm_type,
        ib.ib_upper_bound,
        ib.ib_lower_bound,
        CASE WHEN ib.ib_upper_bound > 100000 THEN 'HIGH_INCOME' ELSE 'LOW_INCOME' END
)
SELECT
    agg.w_warehouse_id,
    agg.w_city,
    agg.web_name,
    agg.cc_name,
    agg.cp_description,
    agg.sm_type,
    agg.total_net_profit,
    agg.total_net_loss,
    agg.distinct_refunded_customers,
    agg.income_category,
    attr,
    ROW_NUMBER() OVER (PARTITION BY agg.w_warehouse_id ORDER BY agg.total_net_profit DESC) AS warehouse_profit_rank
FROM agg
CROSS JOIN UNNEST(ARRAY[agg.w_state, agg.w_country]) AS t(attr)
LIMIT 100
