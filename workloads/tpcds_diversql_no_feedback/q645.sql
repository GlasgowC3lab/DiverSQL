WITH sales_agg AS (
    SELECT
        s.s_store_id,
        p.p_promo_id,
        d.d_year,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_txn_cnt,
        AVG(CASE WHEN sm.sm_type = 'A' THEN cs.cs_ext_sales_price END) AS avg_ext_sales_price_type_a,
        COALESCE(SUM(i.inv_quantity_on_hand), 0) AS total_inventory,
        COALESCE(SUM(wr.wr_return_quantity), 0) AS total_return_qty
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
        AND i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_customer_sk = ss.ss_customer_sk
    LEFT JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE p.p_channel_event = 'N'
      AND cd.cd_gender = 'M'
    GROUP BY s.s_store_id, p.p_promo_id, d.d_year
)
SELECT
    s_store_id,
    p_promo_id,
    d_year,
    store_net_profit,
    catalog_net_profit,
    total_inventory,
    total_return_qty,
    CASE
        WHEN store_net_profit > catalog_net_profit THEN 'Store Better'
        WHEN catalog_net_profit > store_net_profit THEN 'Catalog Better'
        ELSE 'Equal'
    END AS profit_comparison,
    RANK() OVER (PARTITION BY d_year ORDER BY (store_net_profit + catalog_net_profit) DESC) AS year_rank
FROM sales_agg
WHERE d_year BETWEEN 1998 AND 2000
  AND total_inventory > 1000
  AND total_return_qty < 500
  AND store_net_profit IS NOT NULL
  AND catalog_net_profit IS NOT NULL
ORDER BY year_rank, d_year, store_net_profit DESC
LIMIT 100
