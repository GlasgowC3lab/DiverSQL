WITH sales_union AS (
   SELECT ss.ss_sold_date_sk AS date_sk,
          ss.ss_item_sk AS item_sk,
          ss.ss_customer_sk AS customer_sk,
          ss.ss_net_paid AS net_paid,
          ss.ss_net_profit AS net_profit,
          'store' AS channel
   FROM store_sales ss
   UNION ALL
   SELECT ws.ws_sold_date_sk AS date_sk,
          ws.ws_item_sk AS item_sk,
          ws.ws_bill_customer_sk AS customer_sk,
          ws.ws_net_paid AS net_paid,
          ws.ws_net_profit AS net_profit,
          'web' AS channel
   FROM web_sales ws
   UNION ALL
   SELECT cs.cs_sold_date_sk AS date_sk,
          cs.cs_item_sk AS item_sk,
          cs.cs_bill_customer_sk AS customer_sk,
          cs.cs_net_paid AS net_paid,
          cs.cs_net_profit AS net_profit,
          'catalog' AS channel
   FROM catalog_sales cs
)
SELECT
    d_year,
    i_category,
    i_class,
    channel,
    order_cnt,
    net_paid,
    net_profit,
    SUM(net_paid) OVER (PARTITION BY d_year ORDER BY i_category ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_year_net_paid
FROM (
    SELECT
        d.d_year AS d_year,
        i.i_category AS i_category,
        i.i_class AS i_class,
        s.channel AS channel,
        COUNT(*) AS order_cnt,
        SUM(s.net_paid) AS net_paid,
        SUM(s.net_profit) AS net_profit
    FROM sales_union s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    JOIN customer c ON s.customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
      AND cd.cd_gender = 'M'
    GROUP BY d.d_year, i.i_category, i.i_class, s.channel
) q
ORDER BY d_year, i_category, i_class, channel
LIMIT 100
