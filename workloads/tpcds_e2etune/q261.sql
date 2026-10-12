WITH sales_agg AS (
    SELECT
        ss.ss_customer_sk,
        ss.ss_promo_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    WHERE ss.ss_quantity > 1
    GROUP BY ss.ss_customer_sk, ss.ss_promo_sk, ss.ss_sold_date_sk
),
returns_agg AS (
    SELECT
        cr.cr_returning_customer_sk AS customer_sk,
        cr.cr_warehouse_sk AS warehouse_sk,
        cr.cr_returned_date_sk AS return_date_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_fee) AS total_return_fee,
        COUNT(*) AS return_transactions
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity >= 10
      AND cr.cr_warehouse_sk IN (7, 14, 9)
    GROUP BY cr.cr_returning_customer_sk, cr.cr_warehouse_sk, cr.cr_returned_date_sk
)
SELECT
    c.c_customer_id,
    p.p_promo_name,
    w.w_warehouse_name,
    s.total_sales_amount,
    r.total_return_amount,
    (s.total_profit - r.total_return_amount) AS net_revenue,
    s.sales_transactions,
    r.return_transactions,
    ROUND(
        100.0 * (s.total_profit - r.total_return_amount) /
        SUM(s.total_profit - r.total_return_amount) OVER (PARTITION BY p.p_promo_name),
        2
    ) AS contribution_pct_to_promo
FROM sales_agg s
JOIN returns_agg r
    ON s.ss_customer_sk = r.customer_sk
   AND s.ss_sold_date_sk = r.return_date_sk
JOIN customer c
    ON s.ss_customer_sk = c.c_customer_sk
JOIN promotion p
    ON s.ss_promo_sk = p.p_promo_sk
JOIN warehouse w
    ON r.warehouse_sk = w.w_warehouse_sk
WHERE c.c_preferred_cust_flag = 'Y'
  AND p.p_discount_active = 'Y'
ORDER BY net_revenue DESC
LIMIT 10
