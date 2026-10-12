WITH cc_stats AS (
    SELECT AVG(cc_employees) AS avg_employees
    FROM call_center
    WHERE cc_division = 3
),
sales_item AS (
    SELECT
        i_category,
        i_brand,
        i_manufact,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_net_profit) AS total_net_profit,
        AVG(ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_transactions
    FROM store_sales
    JOIN item ON store_sales.ss_item_sk = item.i_item_sk
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2453650
      AND i_current_price >= 5
    GROUP BY i_category, i_brand, i_manufact
)
SELECT
    si.i_category,
    si.i_brand,
    si.i_manufact,
    si.total_quantity,
    si.total_net_paid,
    si.total_net_profit,
    si.avg_discount,
    si.sales_transactions,
    RANK() OVER (ORDER BY si.total_net_profit DESC) AS profit_rank,
    cs.avg_employees
FROM sales_item si
CROSS JOIN cc_stats cs
WHERE si.total_net_profit > cs.avg_employees * 1000
ORDER BY profit_rank
LIMIT 20
