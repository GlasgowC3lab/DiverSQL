WITH joined AS (
    SELECT
        d.d_year,
        i.i_category,
        w.w_state,
        cd.cd_gender,
        hd.hd_buy_potential,
        c.c_customer_id,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        ib.ib_upper_bound,
        p.p_discount_active,
        (
            SELECT AVG(cs2.cs_net_profit)
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = i.i_item_sk
        ) AS avg_item_profit
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    FULL OUTER JOIN web_page wp
        ON c.c_customer_sk = wp.wp_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
       AND inv.inv_date_sk = d.d_date_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
       AND ss.ss_sold_date_sk = d.d_date_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
       AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_order_number = ws.ws_order_number
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2001
      AND i.i_brand_id = 2002002
      AND w.w_country = 'United States'
      AND ib.ib_upper_bound BETWEEN 50000 AND 100000
      AND cs.cs_quantity > 5
      AND p.p_discount_active = 'Y'
),
aggregated AS (
    SELECT
        d_year,
        i_category,
        w_state,
        cd_gender,
        hd_buy_potential,
        COUNT(DISTINCT c_customer_id) AS distinct_customers,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_net_profit) AS avg_profit,
        MIN(cs_ext_sales_price) AS min_sales,
        MAX(cs_ext_sales_price) AS max_sales,
        AVG(avg_item_profit) AS avg_item_profit_overall
    FROM joined
    GROUP BY d_year, i_category, w_state, cd_gender, hd_buy_potential
)
SELECT
    a.*, 
    ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_sales DESC) AS sales_rank
FROM aggregated a
ORDER BY a.total_sales DESC, a.d_year
LIMIT 100
