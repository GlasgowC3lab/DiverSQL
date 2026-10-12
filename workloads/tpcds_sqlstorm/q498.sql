WITH sales AS (
    SELECT 'store' AS channel,
           d.d_year,
           d.d_quarter_seq,
           i.i_item_id,
           i.i_item_desc,
           SUM(ss.ss_net_paid) AS total_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, d.d_quarter_seq, i.i_item_id, i.i_item_desc

    UNION ALL

    SELECT 'catalog' AS channel,
           d.d_year,
           d.d_quarter_seq,
           i.i_item_id,
           i.i_item_desc,
           SUM(cs.cs_net_paid) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, d.d_quarter_seq, i.i_item_id, i.i_item_desc

    UNION ALL

    SELECT 'web' AS channel,
           d.d_year,
           d.d_quarter_seq,
           i.i_item_id,
           i.i_item_desc,
           SUM(ws.ws_net_paid) AS total_sales
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, d.d_quarter_seq, i.i_item_id, i.i_item_desc
)
SELECT channel,
       d_year,
       d_quarter_seq,
       i_item_id,
       i_item_desc,
       total_sales
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY channel, d_year, d_quarter_seq ORDER BY total_sales DESC) AS rn
    FROM sales
) t
WHERE rn <= 10
ORDER BY channel, d_year, d_quarter_seq, total_sales DESC
