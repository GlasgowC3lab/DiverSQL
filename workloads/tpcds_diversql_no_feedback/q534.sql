WITH cs_agg AS (
    SELECT
        cs.cs_sold_date_sk                                 AS cs_sold_date_sk,
        cs.cs_promo_sk                                     AS cs_promo_sk,
        cs.cs_item_sk                                      AS cs_item_sk,
        w.w_warehouse_sk                                   AS w_warehouse_sk,
        d.d_year                                           AS d_year,
        p.p_promo_name                                     AS p_promo_name,
        SUM(cs.cs_net_profit)                              AS total_profit,
        SUM(cs.cs_ext_sales_price)                         AS total_sales,
        CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category
    FROM catalog_sales cs
    JOIN date_dim d               ON cs.cs_sold_date_sk   = d.d_date_sk
    JOIN promotion p              ON cs.cs_promo_sk       = p.p_promo_sk
    JOIN customer_address ca      ON cs.cs_bill_addr_sk   = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk  = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm             ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse w              ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    WHERE d.d_year BETWEEN 2000 AND 2002                     -- predicate 1
      AND ca.ca_country = 'United States'                    -- predicate 2
      AND cd.cd_gender = 'M'                                 -- predicate 3
      AND ib.ib_upper_bound <= 80000                         -- predicate 4
      AND sm.sm_type = 'AIR'                                 -- predicate 5
      AND p.p_discount_active = 'Y'                          -- predicate 6
    GROUP BY
        cs.cs_sold_date_sk,
        cs.cs_promo_sk,
        cs.cs_item_sk,
        w.w_warehouse_sk,
        d.d_year,
        p.p_promo_name
)
SELECT
    ca.d_year,
    ca.p_promo_name,
    ca.profit_category,
    ca.total_profit,
    ca.total_sales,
    inv.inv_quantity_on_hand,
    ss_agg.ss_total_qty,
    sr_agg.sr_total_loss,
    RANK() OVER (PARTITION BY ca.d_year ORDER BY ca.total_profit DESC) AS profit_rank
FROM cs_agg ca
LEFT JOIN inventory inv
    ON ca.cs_sold_date_sk = inv.inv_date_sk
   AND ca.w_warehouse_sk   = inv.inv_warehouse_sk
LEFT JOIN (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS ss_total_qty
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_item_sk
) ss_agg
    ON ca.cs_sold_date_sk = ss_agg.ss_sold_date_sk
   AND ca.cs_item_sk      = ss_agg.ss_item_sk
LEFT JOIN (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        SUM(sr.sr_net_loss) AS sr_total_loss
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk, sr.sr_item_sk
) sr_agg
    ON ca.cs_sold_date_sk = sr_agg.sr_returned_date_sk
   AND ca.cs_item_sk      = sr_agg.sr_item_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_returned_date_sk = ca.cs_sold_date_sk
      AND wr.wr_item_sk          = ca.cs_item_sk
)
ORDER BY ca.d_year, profit_rank
LIMIT 100
