WITH sales_agg AS (
    SELECT
        i.i_category,
        i.i_class,
        i.i_item_sk,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451195
    GROUP BY i.i_category, i.i_class, i.i_item_sk
),
returns_agg AS (
    SELECT
        i.i_category,
        i.i_class,
        i.i_item_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT wr.wr_reason_sk) AS distinct_return_reasons
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450815 AND 2451195
      AND wp.wp_type = 'product'
    GROUP BY i.i_category, i.i_class, i.i_item_sk
),
inventory_agg AS (
    SELECT
        i.i_category,
        i.i_class,
        i.i_item_sk,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_category, i.i_class, i.i_item_sk
)
SELECT
    s.i_category,
    s.i_class,
    s.i_item_sk,
    s.total_net_profit,
    r.total_return_amount,
    (s.total_net_profit - COALESCE(r.total_return_amount, 0)) AS net_profit_after_returns,
    i.avg_inventory_qty,
    r.distinct_return_reasons,
    RANK() OVER (ORDER BY (s.total_net_profit - COALESCE(r.total_return_amount, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.i_category = r.i_category
   AND s.i_class = r.i_class
   AND s.i_item_sk = r.i_item_sk
LEFT JOIN inventory_agg i
    ON s.i_category = i.i_category
   AND s.i_class = i.i_class
   AND s.i_item_sk = i.i_item_sk
WHERE (s.total_net_profit - COALESCE(r.total_return_amount, 0)) > 0
  AND COALESCE(i.avg_inventory_qty, 0) > 0
ORDER BY profit_rank
LIMIT 100
