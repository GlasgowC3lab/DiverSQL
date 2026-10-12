/*
  Goal: Rank items by net profit within each year, showing daily sales totals, promotion and catalog details, and filter for recent year, high‑price items, active promotions, business hours, and other business rules.
*/
WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_ext_sales_price,
        ss.ss_promo_sk,
        cr.cr_catalog_page_sk,
        cp.cp_description,
        cp.cp_type,
        p.p_promo_name,
        p.p_cost,
        i.i_product_name,
        i.i_current_price,
        d.d_date,
        d.d_year,
        t.t_hour,
        ws.web_tax_percentage
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 50
      AND p.p_cost < 5000
      AND cp.cp_type = 'Catalog'
      AND ws.web_tax_percentage >= 0.05
      AND t.t_hour BETWEEN 9 AND 17
      AND ss.ss_quantity >= 2
      AND EXISTS (SELECT 1 FROM promotion p2 WHERE p2.p_promo_sk = ss.ss_promo_sk AND p2.p_discount_active = 'N')
)
SELECT
    b.d_date,
    b.i_product_name,
    b.ss_quantity,
    b.ss_net_paid,
    b.p_promo_name,
    CASE WHEN b.ss_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
    ds.daily_item_sales,
    RANK() OVER (PARTITION BY b.d_year ORDER BY b.ss_net_profit DESC) AS profit_rank_year,
    b.cp_description,
    b.web_tax_percentage,
    b.t_hour
FROM base b
CROSS JOIN LATERAL (
    SELECT SUM(ss2.ss_ext_sales_price) AS daily_item_sales
    FROM store_sales ss2
    WHERE ss2.ss_item_sk = b.ss_item_sk
      AND ss2.ss_sold_date_sk = b.ss_sold_date_sk
) ds
ORDER BY profit_rank_year ASC, ds.daily_item_sales DESC
LIMIT 100
