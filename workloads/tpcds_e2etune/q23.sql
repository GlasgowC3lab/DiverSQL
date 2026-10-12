WITH sales_and_returns AS (
    SELECT
        cp.cp_department AS department,
        p.p_promo_name AS promo_name,
        cs.cs_item_sk AS item_sk,
        cs.cs_net_profit AS sales_profit,
        cr.cr_return_amt_inc_tax AS return_amount,
        r.r_reason_desc AS return_reason
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cp.cp_department = 'DEPARTMENT'
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451088
)
SELECT
    department,
    promo_name,
    item_sk,
    SUM(sales_profit) AS total_sales_profit,
    SUM(CASE WHEN return_reason = 'Damaged' THEN return_amount ELSE 0 END) AS damaged_return_amount,
    SUM(return_amount) AS total_return_amount,
    SUM(sales_profit) - COALESCE(SUM(return_amount), 0) AS net_profit_after_returns,
    RANK() OVER (PARTITION BY department ORDER BY SUM(sales_profit) - COALESCE(SUM(return_amount), 0) DESC) AS profit_rank
FROM sales_and_returns
GROUP BY department, promo_name, item_sk
HAVING SUM(sales_profit) > 0
ORDER BY department, net_profit_after_returns DESC, promo_name
LIMIT 100
