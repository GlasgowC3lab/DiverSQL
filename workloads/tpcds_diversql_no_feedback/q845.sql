WITH cr_agg AS (
    SELECT
        cr_item_sk,
        cr_order_number,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    GROUP BY cr_item_sk, cr_order_number
)
SELECT
    cs.cs_order_number,
    c.c_customer_id,
    d_sold.d_year,
    d_ship.d_year AS ship_year,
    p.p_promo_name,
    CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
    cs.cs_net_paid,
    cr_agg.total_return_amount,
    RANK() OVER (PARTITION BY d_sold.d_year ORDER BY cs.cs_net_paid DESC) AS sales_rank
FROM store_sales ss
JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
LEFT JOIN cr_agg ON cr_agg.cr_item_sk = cs.cs_item_sk AND cr_agg.cr_order_number = cs.cs_order_number
WHERE cs.cs_promo_sk IN (
    SELECT p2.p_promo_sk FROM promotion p2 WHERE p2.p_discount_active = 'Y'
)
  AND ws.web_country = 'United States'
  AND d_sold.d_year BETWEEN 1999 AND 2001
ORDER BY d_sold.d_year, sales_rank
LIMIT 100
