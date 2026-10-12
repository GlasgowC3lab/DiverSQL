WITH agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        d.d_year,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(ss.ss_net_paid) AS store_sales_total
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND p.p_channel_dmail = 'Y'
      AND i.i_current_price > 50
    GROUP BY i.i_item_id, i.i_product_name, d.d_year
)
SELECT
    a.i_item_id,
    a.i_product_name,
    a.d_year,
    a.total_sales,
    a.total_profit,
    a.store_sales_total,
    SUM(a.total_sales) OVER (PARTITION BY a.i_item_id ORDER BY a.d_year ROWS UNBOUNDED PRECEDING) AS running_sales,
    LAG(a.total_sales) OVER (PARTITION BY a.i_item_id ORDER BY a.d_year) AS prior_year_sales,
    RANK() OVER (ORDER BY a.total_profit DESC) AS profit_rank
FROM agg a
ORDER BY a.total_profit DESC
LIMIT 100
