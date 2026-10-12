WITH returns_agg AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_amt_inc_tax) AS total_return_amt
    FROM web_returns
    GROUP BY wr_item_sk
)
SELECT 
    cc.cc_name,
    cc.cc_state,
    i.i_category,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(COALESCE(r.total_return_amt, 0)) AS total_returns,
    CASE WHEN SUM(cs.cs_net_paid_inc_ship_tax) = 0 THEN 0
         ELSE SUM(COALESCE(r.total_return_amt, 0)) / SUM(cs.cs_net_paid_inc_ship_tax) END AS return_rate,
    RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(cs.cs_net_paid_inc_ship_tax) DESC) AS sales_rank
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN returns_agg r ON i.i_item_sk = r.wr_item_sk
WHERE cc.cc_employees > 2000000
  AND cc.cc_division_name IN ('pri', 'able')
  AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
GROUP BY cc.cc_name, cc.cc_state, i.i_category
HAVING SUM(cs.cs_net_paid_inc_ship_tax) > 100000
ORDER BY total_sales DESC
LIMIT 50
