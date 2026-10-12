WITH unified_sales AS (
    SELECT d.d_year,
           i.i_item_id,
           i.i_item_desc,
           cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000

    UNION ALL

    SELECT d.d_year,
           i.i_item_id,
           i.i_item_desc,
           ss.ss_net_profit AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000

    UNION ALL

    SELECT d.d_year,
           i.i_item_id,
           i.i_item_desc,
           ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
),
profit_by_item AS (
    SELECT d_year,
           i_item_id,
           i_item_desc,
           SUM(profit) AS total_profit
    FROM unified_sales
    GROUP BY d_year, i_item_id, i_item_desc
)
SELECT d_year,
       i_item_id,
       i_item_desc,
       total_profit,
       rn AS rank
FROM (
    SELECT d_year,
           i_item_id,
           i_item_desc,
           total_profit,
           ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS rn
    FROM profit_by_item
) t
WHERE rn <= 5
ORDER BY d_year, rn
