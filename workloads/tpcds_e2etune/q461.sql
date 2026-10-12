WITH sales_agg AS (
    SELECT cs.cs_item_sk,
           SUM(cs.cs_net_paid_inc_tax) AS total_sales,
           SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451175
      AND c.c_preferred_cust_flag = 'Y'
    GROUP BY cs.cs_item_sk
),
returns_agg AS (
    SELECT cr.cr_item_sk,
           SUM(cr.cr_return_amount) AS total_return_amount,
           COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN customer c_ret ON cr.cr_refunded_customer_sk = c_ret.c_customer_sk
    WHERE cr.cr_return_amount > 100
      AND cr.cr_returned_date_sk BETWEEN 2450815 AND 2451175
      AND c_ret.c_preferred_cust_flag = 'Y'
    GROUP BY cr.cr_item_sk
)
SELECT i.i_category,
       i.i_brand,
       SUM(s.total_sales) AS category_brand_sales,
       SUM(s.total_profit) AS category_brand_profit,
       SUM(COALESCE(r.total_return_amount, 0)) AS category_brand_returns,
       (SUM(s.total_profit) - SUM(COALESCE(r.total_return_amount, 0))) AS net_profit,
       RANK() OVER (ORDER BY (SUM(s.total_profit) - SUM(COALESCE(r.total_return_amount, 0))) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r ON s.cs_item_sk = r.cr_item_sk
JOIN item i ON s.cs_item_sk = i.i_item_sk
GROUP BY i.i_category, i.i_brand
HAVING SUM(s.total_sales) > 10000
ORDER BY net_profit DESC
LIMIT 10
